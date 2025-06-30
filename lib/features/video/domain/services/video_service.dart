import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../../core/services/base_service.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../data/models/video_content.dart';
import '../../domain/enum/video_source.dart';
import '../../../../core/exceptions/app_exceptions.dart';

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

    final videoId = VideoId.parseVideoId(url);
    if (videoId == null) {
      throw const VideoException('Invalid YouTube URL format');
    }
    
    final id = videoId.toString();
    if (_cache.containsKey(id)) {
      logger.i('Returning cached video: $id');
      return _cache[id]!;
    }

    try {
      logger.i('Processing YouTube video: $url');
      final video = await _youtubeExplode.videos.get(videoId);
      
      // Try to get subtitles
      ClosedCaptionManifest? manifest;
      try {
        manifest = await _youtubeExplode.videos.closedCaptions.getManifest(videoId);
      } catch (e) {
        logger.w('Failed to get subtitle manifest: $e');
        manifest = null;
      }
      
      List<Subtitle> subtitles = [];
      String? warning;
      
      if (manifest?.tracks.isNotEmpty == true) {
        try {
          // Prefer English subtitles, fall back to first available
          final track = manifest!.tracks
              .where((t) => t.language.code.startsWith('en'))
              .firstOrNull ?? 
              manifest.tracks.first;
              
          final captions = await _youtubeExplode.videos.closedCaptions.get(track);
          subtitles = captions.captions.map((c) => Subtitle(
            startTime: c.offset.inMilliseconds,
            endTime: (c.offset + c.duration).inMilliseconds,
            text: c.text,
          )).toList();
          
          logger.i('Successfully extracted ${subtitles.length} subtitles');
        } catch (e) {
          logger.w('Failed to extract subtitles: $e');
          warning = 'Subtitles unavailable';
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
