// lib/features/videos/domain/services/video_service.dart
import 'dart:async';

import 'package:caption_learn/features/video/data/models/video_content.dart';
import 'package:caption_learn/services/youtube/youtube_exceptions.dart';
import 'package:caption_learn/services/youtube_service.dart';
import '../../domain/enum/video_source.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/youtube_utils.dart';

class VideoService {
  final YouTubeService _youtubeService = YouTubeService();
  final Logger _logger = const Logger('VideoService');

  // Process a video URL (only YouTube supported)
  Future<VideoContent> processVideoUrl(String url) async {
    if (!YoutubeUtils.isYoutubeUrl(url)) {
      throw Exception('Only YouTube URLs are supported');
    }

    try {
      // Use the enhanced YouTube service
      return await _youtubeService.processVideoUrl(url);
    } on YouTubeServiceException catch (e) {
      _logger.e('YouTube service error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      _logger.e('Failed to process YouTube video', e);
      throw Exception('Failed to process YouTube video: $e');
    }
  }

  // Cleanup resources
  void dispose() {
    _youtubeService.dispose();
  }
}
