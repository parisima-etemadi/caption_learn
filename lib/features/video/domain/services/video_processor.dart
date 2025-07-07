import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../services/storage_service.dart';
import '../services/video_service.dart';
import '../../data/models/video_content.dart';
import '../enum/video_source.dart';
import '../../../../core/utils/logger.dart';

class VideoProcessor {
  final _videoService = VideoService();
  final _storageService = StorageService();
  final Logger _logger = const Logger('VideoProcessor');

  Future<void> process({
    required VideoSource source,
    required String url,
    File? videoFile,
    File? subtitleFile,
  }) async {
    try {
      _logger.i('Processing video - Source: $source');
      
      String? subtitleContent;
      if (subtitleFile != null) {
        try {
          _logger.i('Reading subtitle file: ${subtitleFile.path}');
          subtitleContent = await subtitleFile.readAsString();
          _logger.i('Subtitle content read successfully, length: ${subtitleContent.length}');
        } catch (e) {
          _logger.e('Failed to read subtitle file', e);
          // Don't throw - continue without subtitles
          subtitleContent = null;
        }
      }
      
      VideoContent videoContent;
      
      if (source == VideoSource.youtube) {
        _logger.i('Processing YouTube URL: $url');
        videoContent = await _videoService.processVideoUrl(
          url, 
          manualSubtitleContent: subtitleContent
        );
      } else {
        _logger.i('Processing local video: ${videoFile?.path}');
        if (videoFile == null) {
          throw Exception('Video file is required for local processing');
        }
        videoContent = await _createLocalVideo(videoFile, subtitleContent);
      }
      
      _logger.i('Saving video to storage...');
      await _storageService.saveVideo(videoContent);
      _logger.i('Video saved successfully with ID: ${videoContent.id}');
      
      // Ensure the process completes
      return;
      
    } catch (e) {
      _logger.e('Video processing failed', e);
      rethrow;
    }
  }

  Future<VideoContent> _createLocalVideo(File file, String? subtitleContent) async {
    try {
      _logger.i('Creating local video content');
      
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory(p.join(appDir.path, 'videos'));
      
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
        _logger.i('Created videos directory: ${videosDir.path}');
      }
      
      final fileName = p.basename(file.path);
      final newPath = p.join(videosDir.path, fileName);
      
      _logger.i('Writing video from ${file.path} to $newPath');
      final newFile = File(newPath);
      await newFile.writeAsBytes(await file.readAsBytes());
      _logger.i('Video written successfully');

      List<Subtitle> subtitles = [];
      if (subtitleContent != null && subtitleContent.isNotEmpty) {
        try {
          _logger.i('Parsing subtitles...');
          subtitles = await _videoService.parseSubtitles(subtitleContent);
          _logger.i('Parsed ${subtitles.length} subtitles');
        } catch (e) {
          _logger.e('Failed to parse subtitles', e);
          // Continue without subtitles rather than failing
          subtitles = [];
        }
      }
      
      final videoContent = VideoContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: newFile.path.split('/').last,
        sourceUrl: newFile.path,
        source: VideoSource.local,
        localPath: newFile.path,
        subtitles: subtitles,
        dateAdded: DateTime.now(),
      );
      
      _logger.i('Local video content created with ${subtitles.length} subtitles');
      return videoContent;
      
    } catch (e) {
      _logger.e('Failed to create local video', e);
      rethrow;
    }
  }

  void dispose() {
    _logger.i('VideoProcessor disposed');
    _videoService.dispose();
  }
}