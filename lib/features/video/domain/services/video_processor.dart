import 'dart:io';
import '../../../../services/storage_service.dart';
import '../services/video_service.dart';
import '../../data/models/video_content.dart';
import '../enum/video_source.dart'; // Import the existing enum


class VideoProcessor {
  final _videoService = VideoService();
  final _storageService = StorageService();

  Future<void> process({
    required VideoSource source,
    required String url,
    File? videoFile,
    File? subtitleFile,
  }) async {
    final subtitleContent = await subtitleFile?.readAsString();
    
    final videoContent = source == VideoSource.youtube
        ? await _videoService.processVideoUrl(url, manualSubtitleContent: subtitleContent)
        : await _createLocalVideo(videoFile!, subtitleContent);
    
    await _storageService.saveVideo(videoContent);
  }

  Future<VideoContent> _createLocalVideo(File file, String? subtitleContent) async {
    return VideoContent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: file.path.split('/').last,
      sourceUrl: file.path,
      source: VideoSource.local, // This now uses the correct enum
      localPath: file.path,
      subtitles: subtitleContent != null 
          ? await _videoService.parseSubtitles(subtitleContent)
          : [],
      dateAdded: DateTime.now(),
    );
  }

  void dispose() => _videoService.dispose();
}