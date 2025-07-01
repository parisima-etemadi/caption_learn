import 'dart:async';
import 'dart:convert';
import 'package:caption_learn/core/utils/logger.dart';
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
  Future<VideoContent> processVideoUrl(String url) async {
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
      final video = await yt.videos.get(videoId);
      logger.i('Video title: ${video.title}');

      final orchestrator = _SubtitleOrchestrator(videoId, logger);
      final subtitleResult = await orchestrator.extractSubtitles();

      final result = VideoContent(
        id: videoId.value,
        title: video.title,
        sourceUrl: url,
        subtitles: subtitleResult.subtitles,
        source: VideoSource.youtube,
        dateAdded: DateTime.now(),
        subtitleWarning: subtitleResult.warning,
      );

      _cache[videoId.value] = result;
      logger.i('Successfully processed video: ${video.title}');
      return result;
    } catch (e) {
      logger.e('Failed to process YouTube video: $url', e);
      throw VideoException('Failed to process video: ${e.toString()}', originalError: e);
    } finally {
      // **FIX**: Ensure the client is always closed after the operation.
      yt.close();
    }
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
    if (!_oauthService.isAuthenticated) {
      _logger.i("Skipping OAuth: User not authenticated.");
      final tracks = await _fetchCaptionTracksFromApi();
      if (tracks.isNotEmpty) {
        return (subtitles: <Subtitle>[], warning: 'Subtitles available but require YouTube authentication. Please sign in via Settings.');
      }
      return (subtitles: <Subtitle>[], warning: null);
    }

    final captionTracks = await _fetchCaptionTracksFromApi();
    if (captionTracks.isEmpty) return (subtitles: <Subtitle>[], warning: null);

    final track = captionTracks.firstWhere(
        (t) => t['language'] != null && (t['language'] as String).startsWith('en'),
        orElse: () => captionTracks.first);

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
