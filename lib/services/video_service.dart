import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/video_content.dart';
import 'youtube_service.dart';

class VideoService {
  final YoutubeExplode _youtubeExplode = YoutubeExplode();
  final Uuid _uuid = Uuid();
  
  // Detects the type of video from URL
  VideoSource detectSourceType(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return VideoSource.youtube;
    } else if (url.contains('tiktok.com')) {
      return VideoSource.tiktok;
    } else if (url.contains('instagram.com')) {
      return VideoSource.instagram;
    } else {
      throw Exception('Unsupported video source');
    }
  }
  
  // Gets video metadata and prepares video content
  Future<VideoContent> processVideoUrl(String url) async {
    final videoSource = detectSourceType(url);
    
    switch (videoSource) {
      case VideoSource.youtube:
        return _processYouTubeVideo(url);
      case VideoSource.tiktok:
        return _processTikTokVideo(url);
      case VideoSource.instagram:
        return _processInstagramVideo(url);
      default:
        throw Exception('Unsupported video source');
    }
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
      
      // Use YouTubeService to get video details
      final videoDetails = await YouTubeService.getVideoDetails(videoId);
      
      // Fetch real subtitles using our new service
      final subtitles = await YouTubeService.getYouTubeSubtitles(videoId);
      
      // If no subtitles were found, inform the user
      if (subtitles.isEmpty) {
        print('No subtitles found for this YouTube video. You may need to add them manually.');
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
      throw Exception('Failed to process YouTube video: $e');
    }
  }
  
  // Processes TikTok videos - would need TikTok API integration
  Future<VideoContent> _processTikTokVideo(String url) async {
    // This is a placeholder - in a real app, you would integrate with TikTok's API
    // TikTok doesn't have an official public API for this, so would require custom solutions
    
    // For demonstration purposes, we'll return a mock VideoContent
    return VideoContent(
      id: _uuid.v4(),
      title: 'TikTok Video',
      sourceUrl: url,
      source: VideoSource.tiktok,
      subtitles: [], // Would need to implement subtitle extraction for TikTok
      dateAdded: DateTime.now(),
    );
  }
  
  // Processes Instagram videos - would need Instagram API integration
  Future<VideoContent> _processInstagramVideo(String url) async {
    // This is a placeholder - in a real app, you would integrate with Instagram's API
    // Instagram API access is restricted and would require approval
    
    // For demonstration purposes, we'll return a mock VideoContent
    return VideoContent(
      id: _uuid.v4(),
      title: 'Instagram Video',
      sourceUrl: url,
      source: VideoSource.instagram,
      subtitles: [], // Would need to implement subtitle extraction for Instagram
      dateAdded: DateTime.now(),
    );
  }
  
  // Process a locally uploaded video
  Future<VideoContent> processLocalVideo(File videoFile, String title) async {
    // Save the file to app's documents directory
    final directory = await getApplicationDocumentsDirectory();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final String filePath = '${directory.path}/$fileName';
    
    // Copy the file to the app's storage
    await videoFile.copy(filePath);
    
    // For local videos, subtitles would need to be generated using speech-to-text
    // This is a complex task that would require integration with a speech recognition API
    
    // For demonstration, we'll return empty subtitles
    return VideoContent(
      id: _uuid.v4(),
      title: title,
      sourceUrl: 'file://$filePath',
      source: VideoSource.local,
      localPath: filePath,
      subtitles: [], // Would need to implement subtitle generation for local videos
      dateAdded: DateTime.now(),
    );
  }
  
  // Cleanup
  void dispose() {
    _youtubeExplode.close();
  }
} 