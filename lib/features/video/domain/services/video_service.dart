import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:caption_learn/core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/base_service.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../../../services/auth/youtube_oauth_service.dart';
import '../../../../services/subtitle/subtitle_parser.dart';
import '../../data/models/video_content.dart';
import '../enum/video_source.dart';

/// Service to process YouTube video URLs, fetch metadata, and extract subtitles.
/// It uses an orchestrator pattern to try multiple subtitle extraction strategies
/// until one succeeds, ensuring maximum reliability.
class VideoService extends BaseService {
  static final VideoService _instance = VideoService._internal();
  final Map<String, VideoContent> _cache = {};

  @override
  String get serviceName => 'VideoService';

  factory VideoService() => _instance;
  VideoService._internal();

  /// Processes a YouTube video URL.
  ///
  /// Fetches video metadata and then uses the [_SubtitleOrchestrator]
  /// to attempt various strategies for extracting subtitles.
  Future<VideoContent> processVideoUrl(
    String url, {
    String? manualSubtitleContent,
  }) async {
    if (!YoutubeUtils.isYoutubeUrl(url)) {
      throw const VideoException('Only YouTube URLs are supported');
    }

    final videoIdString = VideoId.parseVideoId(url);
    if (videoIdString == null) {
      throw const VideoException('Invalid YouTube URL format');
    }
    final videoId = VideoId(videoIdString);

    if (_cache.containsKey(videoId.value)) {
      logger.i('Returning cached video: ${videoId.value}');
      return _cache[videoId.value]!;
    }

    // **FIX**: Create a new YoutubeExplode instance for each request to avoid client-closed errors.
    final yt = YoutubeExplode();
    try {
      logger.i('Processing YouTube video: $url');

      Video? video;
      String? videoTitle;

      try {
        video = await yt.videos.get(videoId).timeout(
              const Duration(seconds: 30),
              onTimeout: () =>
                  throw TimeoutException('The connection to YouTube timed out.'),
            );
        videoTitle = video.title;
        logger.i('Video title from API: $videoTitle');
      } on VideoUnavailableException catch (e) {
        logger.w('VideoUnavailableException caught. Trying fallback title extraction. ${e.toString()}');
        videoTitle = await _getTitleFromWebScraping(videoId.value);
        if (videoTitle != null) {
          logger.i('Video title from fallback: $videoTitle');
        } else {
          logger.e('Fallback title extraction also failed.');
          throw VideoException('Failed to process video', originalError: e);
        }
      }

      if (videoTitle == null) {
        throw const VideoException('Failed to retrieve video title.');
      }

      logger.i('Video title: $videoTitle');

      List<Subtitle> subtitles = [];
      String? subtitleWarning;

      if (manualSubtitleContent != null && manualSubtitleContent.isNotEmpty) {
        logger.i('Parsing manual subtitle content.');
        try {
          subtitles = SubtitleParser.parse(manualSubtitleContent);
          if (subtitles.isEmpty) {
            subtitleWarning = 'The provided subtitle file appears to be empty or in an unsupported format.';
          }
        } catch (e) {
          logger.e('Error parsing manual subtitle file', e);
          subtitleWarning = 'Failed to parse the subtitle file. Please check the format.';
        }
      } else {
        final orchestrator = _SubtitleOrchestrator(videoId, logger);
        final subtitleResult = await orchestrator.extractSubtitles();
        subtitles = subtitleResult.subtitles;
        subtitleWarning = subtitleResult.warning;
      }

      // Simulate translation for each subtitle
      if (subtitles.isNotEmpty) {
        subtitles = subtitles
            .map((s) => s.copyWith(translation: 'Translated: ${s.text}'))
            .toList();
      }

      final result = VideoContent(
        id: videoId.value,
        title: videoTitle,
        sourceUrl: url,
        subtitles: subtitles,
        source: VideoSource.youtube,
        dateAdded: DateTime.now(),
        subtitleWarning: subtitleWarning,
      );

      _cache[videoId.value] = result;
      logger.i('Successfully processed video: $videoTitle');
      return result;
    } on SocketException catch (e) {
      logger.e('Network error while processing video: $url', e);
      throw const NetworkException('Please check your internet connection and try again.');
    } on TimeoutException catch (e) {
      logger.e('Timeout error while processing video: $url', e);
      throw NetworkException(e.message ?? 'The request timed out.');
    } catch (e) {
      logger.e('Failed to process YouTube video: $url', e);
      throw VideoException('Failed to process video', originalError: e);
    } finally {
      // **FIX**: Ensure the client is always closed after the operation.
      yt.close();
    }
  }

  Future<List<Subtitle>> parseSubtitles(String content) async {
    return compute(SubtitleParser.parse, content);
  }

  Future<String?> _getTitleFromWebScraping(String videoId) async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
      });

      if (response.statusCode == 200) {
        final titleMatch = RegExp(r'<title>(.*?) - YouTube</title>').firstMatch(response.body);
        return titleMatch?.group(1)?.trim();
      }
    } catch (e) {
      logger.e('Error during web scraping for title', e);
    }
    return null;
  }

  void clearCache() {
    _cache.clear();
    logger.i('Video cache cleared');
  }

  void dispose() {
    // The YoutubeExplode instance is now managed within processVideoUrl,
    // so there's nothing to close here.
    clearCache();
    logger.i('VideoService disposed');
  }
}

/// A private helper class to manage the complex process of subtitle extraction.
/// It tries a series of strategies in order until one is successful.
class _SubtitleOrchestrator {
  final VideoId _videoId;
  final Logger _logger;
  final YoutubeExplode _yt;
  final YouTubeOAuthService _oauthService;

  _SubtitleOrchestrator(this._videoId, this._logger)
      : _yt = YoutubeExplode(),
        _oauthService = YouTubeOAuthService();

  /// The main method that attempts to extract subtitles using a sequence of strategies.
  Future<({List<Subtitle> subtitles, String? warning})> extractSubtitles() async {
    List<Subtitle> subtitles = [];
    String? warning;

    final strategies = [
      _tryYoutubeExplode,
      _tryOAuth,
      _tryWebScraping,
    ];

    for (final strategy in strategies) {
      try {
        final result = await strategy();
        if (result.subtitles.isNotEmpty) {
          subtitles = result.subtitles;
          warning = result.warning;
          _logger.i('Extraction successful with strategy: ${strategy.toString()}');
          break;
        }
        if (result.warning != null) {
          warning = result.warning;
        }
      } catch (e) {
        _logger.w('Strategy ${strategy.toString()} failed: $e');
        if (e.toString().contains('403:')) {
            warning = 'The video owner has disabled subtitle downloads for third-party apps.';
        }
        continue;
      }
    }

    if (subtitles.isEmpty && warning == null) {
      warning = "Could not find or extract subtitles for this video.";
    }
    
    _yt.close();
    return (subtitles: subtitles, warning: warning);
  }

  /// Strategy 1: Use the youtube_explode_dart package directly.
  Future<({List<Subtitle> subtitles, String? warning})> _tryYoutubeExplode() async {
    _logger.i("Attempting strategy: YoutubeExplode");
    final manifest = await _yt.videos.closedCaptions.getManifest(_videoId);

    if (manifest.tracks.isEmpty) return (subtitles: <Subtitle>[], warning: null);

    final trackInfo = manifest.tracks.firstWhere(
        (t) => t.language.code.startsWith('en'),
        orElse: () => manifest.tracks.first);

    try {
      final track = await _yt.videos.closedCaptions.get(trackInfo);
      final subtitles = track.captions
          .map((c) => Subtitle(
                startTime: c.offset.inMilliseconds,
                endTime: (c.offset + c.duration).inMilliseconds,
                text: c.text,
              ))
          .toList();
      return (subtitles: subtitles, warning: null);
    } on Exception catch (e) {
        if (e.toString().contains('XmlParserException')) {
            _logger.w('YoutubeExplode failed with XML error, will try other methods. ${e.toString()}');
        } else {
            throw e;
        }
        return (subtitles: <Subtitle>[], warning: null);
    }
  }

  /// Strategy 2: Use the official YouTube Data API with user authentication.
  Future<({List<Subtitle> subtitles, String? warning})> _tryOAuth() async {
    _logger.i("Attempting strategy: OAuth");

    // First, check if there are any caption tracks at all using the public API.
    // This avoids prompting for login if no captions exist.
    final tracks = await _fetchCaptionTracksFromApi();
    if (tracks.isEmpty) {
      _logger.i("No caption tracks found via public API. Skipping OAuth.");
      return (subtitles: <Subtitle>[], warning: null);
    }

    // If tracks exist but the user is not authenticated, return a specific warning.
    if (!_oauthService.isAuthenticated) {
      _logger.i("User not authenticated for OAuth, but tracks are available.");
      return (
        subtitles: <Subtitle>[],
        warning:
            'This video has subtitles that require you to sign in with Google.'
      );
    }
    
    _logger.i("User is authenticated. Proceeding with OAuth to download captions.");

    // Since we are authenticated, we can now try to download the best track.
    final track = tracks.firstWhere(
        (t) => t['language'] != null && (t['language'] as String).startsWith('en'),
        orElse: () => tracks.first);

    final captionId = track['id'] as String;
    final captionData = await _oauthService.downloadCaptions(captionId);

    if (captionData != null && captionData.isNotEmpty) {
      return (subtitles: SubtitleParser.parse(captionData), warning: null);
    }
    return (subtitles: <Subtitle>[], warning: null);
  }

  /// Strategy 3: Scrape the YouTube watch page for subtitle data.
  Future<({List<Subtitle> subtitles, String? warning})> _tryWebScraping() async {
    _logger.i("Attempting strategy: Web Scraping");
    final url = 'https://www.youtube.com/watch?v=${_videoId.value}';
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9',
    });

    if (response.statusCode != 200) return (subtitles: <Subtitle>[], warning: null);

    final playerResponseMatch = RegExp(r'var ytInitialPlayerResponse\s*=\s*({.+?});').firstMatch(response.body);
    if (playerResponseMatch == null) return (subtitles: <Subtitle>[], warning: null);

    final playerResponse = json.decode(playerResponseMatch.group(1)!);
    final renderer = playerResponse['captions']?['playerCaptionsTracklistRenderer'];
    final tracks = renderer?['captionTracks'] as List?;

    if (tracks == null || tracks.isEmpty) return (subtitles: <Subtitle>[], warning: null);

    final track = tracks.firstWhere((t) => (t['languageCode'] as String).startsWith('en'), orElse: () => tracks.first);
    final baseUrl = track['baseUrl'] as String?;

    if (baseUrl == null) return (subtitles: <Subtitle>[], warning: null);

    final subtitleResponse = await http.get(Uri.parse(baseUrl));
    if (subtitleResponse.statusCode == 200 && subtitleResponse.body.isNotEmpty) {
      final List<Subtitle> subtitles = SubtitleParser.parse(subtitleResponse.body);
      return (subtitles: subtitles, warning: null);
    }

    return (subtitles: <Subtitle>[], warning: null);
  }

  /// Helper to fetch the list of available caption tracks via the Data API.
  Future<List<Map<String, dynamic>>> _fetchCaptionTracksFromApi() async {
    final listUrl = Uri.parse('https://www.googleapis.com/youtube/v3/captions').replace(queryParameters: {
      'part': 'snippet',
      'videoId': _videoId.value,
      'key': AppConstants.youtubeApiKey,
    });

    final response = await http.get(listUrl);
    if (response.statusCode != 200) {
      _logger.w('Failed to list captions via Data API: ${response.statusCode}');
      return [];
    }

    final data = json.decode(response.body);
    final items = data['items'] as List<dynamic>?;
    return items?.cast<Map<String, dynamic>>() ?? [];
  }
}