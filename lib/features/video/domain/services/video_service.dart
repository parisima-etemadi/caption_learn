// lib/features/videos/domain/services/video_service.dart
import 'package:caption_learn/features/video/data/models/video_content.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../domain/enum/video_source.dart';
import '../../../../core/utils/logger.dart';

class VideoService {
  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  final Uuid _uuid = Uuid();
  final Logger _logger = const Logger('VideoService');
  
  // Validates if the URL is a YouTube URL
  bool isYoutubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }
  
  // Process a video URL (only YouTube supported)
  Future<VideoContent> processVideoUrl(String url) async {
    if (!isYoutubeUrl(url)) {
      throw Exception('Only YouTube URLs are supported');
    }
    
    return _processYouTubeVideo(url);
  }
  
  // Extract YouTube video ID from URL
  String? extractYoutubeVideoId(String url) {
    final RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(7);
  }
  
  // Processes YouTube videos
  Future<VideoContent> _processYouTubeVideo(String url) async {
    try {
      final String? videoId = extractYoutubeVideoId(url);
      
      if (videoId == null || videoId.isEmpty) {
        throw Exception('Invalid YouTube URL');
      }
      
      // Get video details
      final videoDetails = await _getVideoDetails(videoId);
      
      // Fetch subtitles
      final subtitles = await _getYouTubeSubtitles(videoId);
      
      // If no subtitles were found, log a warning
      if (subtitles.isEmpty) {
        _logger.w('No subtitles found for this YouTube video. You may need to add them manually.');
      }
      
      return VideoContent(
        id: _uuid.v4(),
        title: videoDetails['title'] ?? 'YouTube Video',
        sourceUrl: url,
        source: VideoSource.youtube,
        subtitles: subtitles,
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Failed to process YouTube video', e);
      throw Exception('Failed to process YouTube video: $e');
    }
  }
  
  /// Gets video details from YouTube
  Future<Map<String, dynamic>> _getVideoDetails(String videoId) async {
    try {
      final video = await _youtubeExplode.videos.get(videoId);
      
      return {
        'title': video.title,
        'author': video.author,
        'duration': video.duration?.inMilliseconds,
        'thumbnailUrl': video.thumbnails.highResUrl,
      };
    } catch (e) {
      _logger.e('Error fetching YouTube video details', e);
      return {};
    }
  }
  
  /// Fetches subtitles from a YouTube video
  Future<List<Subtitle>> _getYouTubeSubtitles(String videoId) async {
    final subtitles = <Subtitle>[];
    
    try {
      // Get closed captions manifest
      final manifest = await _youtubeExplode.videos.closedCaptions.getManifest(videoId);
      
      // Get the first available track
      if (manifest.tracks.isNotEmpty) {
        // Try to find English track first
        final track = manifest.tracks
            .firstWhere(
                (t) => t.language.code.toLowerCase() == 'en',
                orElse: () => manifest.tracks.first
            );
        
        // Get the actual closed captions
        final closedCaptions = await _youtubeExplode.videos.closedCaptions.get(track);
        
        // Convert to our app's Subtitle format
        for (final caption in closedCaptions.captions) {
          subtitles.add(
            Subtitle(
              startTime: caption.offset.inMilliseconds,
              endTime: (caption.offset + caption.duration).inMilliseconds,
              text: caption.text,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Error fetching YouTube subtitles', e);
    }
    
    return subtitles;
  }
  
  // Cleanup resources
  void dispose() {
    _youtubeExplode.close();
  }
}