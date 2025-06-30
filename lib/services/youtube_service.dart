import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../core/services/base_service.dart';
import '../features/video/data/models/video_content.dart';
import 'youtube/youtube_video_processor.dart';

class YouTubeService extends BaseService {
  static final YouTubeService _instance = YouTubeService._internal();
  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  late final YouTubeVideoProcessor _videoProcessor;
  
  @override
  String get serviceName => 'YouTubeService';
  
  factory YouTubeService() => _instance;
  
  YouTubeService._internal() : super() {
    _videoProcessor = YouTubeVideoProcessor(_youtubeExplode);
  }

  /// Enhanced video processing with better error handling and caching
  Future<VideoContent> processVideoUrl(String url) async {
    try {
      return await _videoProcessor.processVideoUrl(url);
    } catch (e) {
      logger.e('Error processing video URL: $url', e);
      rethrow;
    }
  }
  
  /// Clear cache (useful for memory management)
  void clearCache() {
    _videoProcessor.clearCache();
    logger.i('Cleared YouTube service cache');
  }
  
  /// Dispose of resources
  void dispose() {
    _youtubeExplode.close();
    logger.i('YouTube service disposed');
  }
}