import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_caption_scraper/youtube_caption_scraper.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/base_service.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../data/models/video_content.dart';
import '../../domain/enum/video_source.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../services/subtitle/subtitle_parser.dart';

/// Unified video processing service - handles YouTube video processing directly
class VideoService extends BaseService {
  static final VideoService _instance = VideoService._internal();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  final Map<String, VideoContent> _cache = {};
  
  @override
  String get serviceName => 'VideoService';
  
  factory VideoService() => _instance;
  VideoService._internal();

  /// Process a video URL - currently supports YouTube only
  Future<VideoContent> processVideoUrl(String url) async {
    if (!YoutubeUtils.isYoutubeUrl(url)) {
      throw const VideoException('Only YouTube URLs are supported');
    }

    final videoIdString = VideoId.parseVideoId(url);
    if (videoIdString == null) {
      throw const VideoException('Invalid YouTube URL format');
    }
    final videoId = VideoId(videoIdString);
    
    final id = videoId.toString();
    if (_cache.containsKey(id)) {
      logger.i('Returning cached video: $id');
      return _cache[id]!;
    }

    try {
      logger.i('Processing YouTube video: $url');
      final video = await _youtubeExplode.videos.get(videoId);
      print(video.title);
       print(video);
      // Try to get subtitles with retry logic
      ClosedCaptionManifest? manifest = await _getManifestWithRetry(videoId);
      
      List<Subtitle> subtitles = [];
      String? warning;
      
      if (manifest?.tracks.isNotEmpty == true) {
        // Try multiple tracks in case some have parsing issues
        final englishTracks = manifest!.tracks
            .where((t) => t.language.code.startsWith('en'))
            .toList();
        final tracksToTry = englishTracks.isNotEmpty ? englishTracks : manifest.tracks.toList();
        
        bool successfullyExtracted = false;
        
        for (final track in tracksToTry) {
          try {
            logger.i('Attempting to extract from track: ${track.language.name} (${track.language.code})');
            final captions = await _youtubeExplode.videos.closedCaptions.get(track);
            subtitles = captions.captions.map((c) => Subtitle(
              startTime: c.offset.inMilliseconds,
              endTime: (c.offset + c.duration).inMilliseconds,
              text: c.text,
            )).toList();
            
            logger.i('Successfully extracted ${subtitles.length} subtitles from ${track.language.name}');
            successfullyExtracted = true;
            break;
          } catch (e) {
            logger.w('Failed to extract from track ${track.language.name}: $e');
            
            // If it's an XML parsing error, this might be a known issue with youtube_explode_dart
            if (e.toString().contains('XmlParserException')) {
              logger.i('XML parsing error detected - this appears to be a youtube_explode_dart library issue');
            }
            // Continue to next track
          }
        }
        
        if (!successfullyExtracted) {
          // Fallback: try to extract subtitles using youtube_caption_scraper
          logger.i('Attempting fallback subtitle extraction...');
          subtitles = await _fallbackSubtitleExtraction(url);
          
          if (subtitles.isNotEmpty) {
            logger.i('Fallback extraction successful: ${subtitles.length} subtitles');
          } else {
            // Try direct API extraction as final fallback
            logger.i('Attempting direct YouTube API extraction...');
            subtitles = await _directYouTubeApiExtraction(videoId.toString());
            
            if (subtitles.isNotEmpty) {
              logger.i('Direct API extraction successful: ${subtitles.length} subtitles');
            } else {
              warning = _getSubtitleErrorMessage('No extraction method succeeded');
              logger.w('All subtitle extraction methods failed - YouTube API changes affecting all approaches');
            }
          }
        }
      } else {
        warning = 'No subtitles found';
      }
      
      final result = VideoContent(
        id: id,
        title: video.title,
        sourceUrl: url,
        subtitles: subtitles,
        source: VideoSource.youtube,
        dateAdded: DateTime.now(),
        subtitleWarning: warning,
      );
      
      _cache[id] = result;
      logger.i('Successfully processed video: ${video.title}');
      return result;
      
    } catch (e) {
      logger.e('Failed to process YouTube video: $url', e);
      throw VideoException('Failed to process video: $e', originalError: e);
    }
  }
  
  /// Fallback method to extract subtitles using youtube_caption_scraper
  Future<List<Subtitle>> _fallbackSubtitleExtraction(String videoUrl) async {
    try {
      logger.i('Attempting subtitle extraction with youtube_caption_scraper');
      
      final captionScraper = YouTubeCaptionScraper();
      final captionTracks = await captionScraper.getCaptionTracks(videoUrl);
      
      if (captionTracks.isEmpty) {
        logger.w('No caption tracks found by youtube_caption_scraper');
        return [];
      }
      
      logger.i('Found ${captionTracks.length} caption tracks with scraper');
      
      // Try to find English captions first, then any available
      var preferredTrack = captionTracks.where((track) => 
        track.languageCode?.toLowerCase().contains('en') == true ||
        track.name?.toLowerCase().contains('english') == true
      ).firstOrNull;
      
      preferredTrack ??= captionTracks.first;
      
      logger.i('Using caption track: ${preferredTrack.name} (${preferredTrack.languageCode})');
      
      final subtitles = await captionScraper.getSubtitles(preferredTrack);
      
      // Convert youtube_caption_scraper subtitles to our format
      final convertedSubtitles = subtitles.map((subtitle) => Subtitle(
        startTime: subtitle.start?.inMilliseconds ?? 0,
        endTime: (subtitle.start?.inMilliseconds ?? 0) + (subtitle.duration?.inMilliseconds ?? 0),
        text: subtitle.text ?? '',
      )).where((s) => s.text.isNotEmpty).toList();
      
      logger.i('Successfully converted ${convertedSubtitles.length} subtitles');
      return convertedSubtitles;
      
    } catch (e) {
      logger.w('Fallback extraction with youtube_caption_scraper failed: $e');
      return [];
    }
  }
  
  /// Try getting manifest with different YouTube clients
  Future<ClosedCaptionManifest?> _getManifestWithRetry(VideoId videoId) async {
    // Try multiple approaches to get the manifest
    final approaches = [
      () async {
        logger.i('Attempting to get manifest with iOS headers');
        final iosClient = YoutubeExplode(YoutubeHttpClient());
        try {
          return await iosClient.videos.closedCaptions.getManifest(videoId);
        } finally {
          iosClient.close();
        }
      },
      () async {
        logger.i('Attempting to get manifest with Android headers');
        final androidClient = YoutubeExplode(YoutubeHttpClient());
        try {
          return await androidClient.videos.closedCaptions.getManifest(videoId);
        } finally {
          androidClient.close();
        }
      },
      () async {
        logger.i('Attempting to get manifest with default client');
        return await _youtubeExplode.videos.closedCaptions.getManifest(videoId);
      },
    ];
    
    for (final approach in approaches) {
      try {
        final manifest = await approach();
        if (manifest.tracks.isNotEmpty) {
          logger.i('Successfully got manifest with ${manifest.tracks.length} tracks');
          return manifest;
        }
      } catch (e) {
        logger.w('Manifest attempt failed: $e');
        continue;
      }
    }
    
    return null;
  }
  
  /// Direct YouTube API extraction as final fallback
  Future<List<Subtitle>> _directYouTubeApiExtraction(String videoId) async {
    try {
      // YouTube's timedtext API endpoints to try
      final endpoints = [
        'https://www.youtube.com/api/timedtext?v=$videoId&lang=en&fmt=srv3',
        'https://www.youtube.com/api/timedtext?v=$videoId&lang=en&fmt=vtt',
        'https://www.youtube.com/api/timedtext?v=$videoId&lang=en-US&fmt=srv3',
      ];
      
      for (final url in endpoints) {
        try {
          logger.i('Trying direct API: $url');
          final response = await http.get(Uri.parse(url));
          
          if (response.statusCode == 200 && response.body.isNotEmpty) {
            logger.i('Direct API response received, parsing...');
            return _parseTimedTextResponse(response.body);
          }
        } catch (e) {
          logger.w('Direct API request failed: $e');
          continue;
        }
      }
    } catch (e) {
      logger.w('Direct YouTube API extraction failed: $e');
    }
    return [];
  }
  
  /// Parse timedtext API response
  List<Subtitle> _parseTimedTextResponse(String responseBody) {
    try {
      // Try parsing as VTT format
      if (responseBody.contains('WEBVTT')) {
        return SubtitleParser.parseVtt(responseBody);
      }
      
      // Try parsing as SRV3 (XML) format
      if (responseBody.contains('<?xml')) {
        return SubtitleParser.parseSrv3(responseBody);
      }
      
      logger.w('Unknown subtitle format in direct API response');
      return [];
    } catch (e) {
      logger.w('Failed to parse timedtext response: $e');
      return [];
    }
  }
  
  /// Get user-friendly error message
  String _getSubtitleErrorMessage(dynamic error) {
    final errorStr = error.toString();
    
    if (errorStr.contains('XmlParserException')) {
      return 'YouTube subtitle format has changed. We\'re working on a fix.';
    } else if (errorStr.contains('VideoUnavailableException')) {
      return 'This video is not available in your region.';
    } else if (errorStr.contains('403') || errorStr.contains('Forbidden')) {
      return 'Access to subtitles is restricted for this video.';
    } else if (errorStr.contains('No extraction method succeeded')) {
      return 'Unable to extract subtitles. YouTube may have updated their API.';
    }
    
    return 'Unable to load subtitles at this time. Please try again later.';
  }

  /// Clear video cache
  void clearCache() {
    _cache.clear();
    logger.i('Video cache cleared');
  }

  /// Dispose of resources
  void dispose() {
    _youtubeExplode.close();
    _cache.clear();
    logger.i('VideoService disposed');
  }
}

/// Extension to safely get first element or null
extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

