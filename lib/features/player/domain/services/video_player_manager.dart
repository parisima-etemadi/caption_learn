// lib/features/player/domain/services/video_player_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/storage_service.dart';
import '../../../vocabulary/models/vocabulary_item.dart';
import '../../../video/data/models/video_content.dart';
import '../../../video/domain/enum/video_source.dart';

/// Manager class that handles video player logic and state
class VideoPlayerManager {
  final String videoId;
  final VoidCallback onSubtitleIndexChanged;
  final VoidCallback onLoadingChanged;
  final VoidCallback onInitialized;
  final Logger _logger = const Logger('VideoPlayerManager');
  final StorageService _storageService = StorageService();


  VideoPlayerController? controller; // For future local video support
  YoutubePlayerController? youtubeController;
  VideoContent? videoContent;
  bool isInitialized = false;
  bool isLoading = true;
  bool isYoutubeVideo = false;
  bool isYoutubePlayerReady = false;
  int currentSubtitleIndex = -1;
  Timer? positionTimer;
  bool _isDisposed = false;
  
  VideoPlayerManager({
    required this.videoId,
    required this.onSubtitleIndexChanged,
    required this.onLoadingChanged,
    required this.onInitialized,
  });

  /// Load the video content and initialize the appropriate player
  Future<void> loadVideo(BuildContext context) async {
    isLoading = true;
    onLoadingChanged();

    try {
      // Load video data from storage
      _logger.i('Loading video with ID: $videoId');
      videoContent = _storageService.getVideoById(videoId);

      if (videoContent == null) {
        // Get all videos to debug
        final allVideos = _storageService.getVideos();
        _logger.e('Video with ID $videoId not found. Available videos: ${allVideos.map((v) => '${v.id}: ${v.title}').join(', ')}');
        _showError(context, 'Video not found (ID: $videoId)');
        return;
      }

      _logger.i('Successfully loaded video: ${videoContent!.title}');

      isYoutubeVideo = videoContent!.source == VideoSource.youtube;

      // Currently we only support YouTube videos
      if (!isYoutubeVideo) {
        _showError(context, 'Currently only YouTube videos are supported');
        return;
      }

      validateAndFixSubtitles();

      await initializeVideoPlayer(context);

      isLoading = false;
      onLoadingChanged();
    } catch (e) {
      _logger.e('Error loading video', e);
      _showError(context, 'Error loading video: ${e.toString()}');
    }
  }



  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Navigator.pop(context);
  }

  /// Initialize the appropriate video player based on content source
  Future<void> initializeVideoPlayer(BuildContext context) async {
    if (videoContent == null) return;

    // Currently we only initialize YouTube videos
    // Structure kept for future expansion to other video types
    if (videoContent!.source == VideoSource.youtube) {
      await initializeYouTubeVideo(context);
    } else {
      _showError(context, 'Currently only YouTube videos are supported');
    }
  }


// Update the initializeYouTubeVideo method:
Future<void> initializeYouTubeVideo(BuildContext context) async {
  if (_isDisposed) return;
  
  final ytVideoId = YoutubePlayer.convertUrlToId(videoContent!.sourceUrl);
  if (ytVideoId != null) {
    // Dispose existing controller if any
    youtubeController?.dispose();
    
    isYoutubePlayerReady = false;

    youtubeController = YoutubePlayerController(
      initialVideoId: ytVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    );

    isInitialized = true;
    onInitialized();

    if (videoContent!.subtitles.isEmpty) {
      _logger.i('No subtitles found for this video');
    }
  } else {
    _showError(context, 'Invalid YouTube URL');
  }
}

// Update the dispose method:
void dispose() {
  _isDisposed = true;
  positionTimer?.cancel();
  youtubeController?.dispose();
  controller?.dispose();
  _logger.d('Disposed player resources');
}

  /// Validate and fix any subtitle timing issues
  void validateAndFixSubtitles() {
    if (videoContent == null || videoContent!.subtitles.isEmpty) return;

    final subtitles = videoContent!.subtitles;
    bool hasChanges = false;
    final List<Subtitle> fixedSubtitles = [];

    for (int i = 0; i < subtitles.length; i++) {
      var subtitle = subtitles[i];

      if (subtitle.startTime >= subtitle.endTime) {
        final newEndTime = subtitle.startTime + 3000;
        subtitle = Subtitle(
          startTime: subtitle.startTime,
          endTime: newEndTime,
          text: subtitle.text,
        );
        hasChanges = true;
      }

      if (i > 0) {
        final prevSubtitle = fixedSubtitles[i - 1];
        if (subtitle.startTime < prevSubtitle.endTime) {
          subtitle = Subtitle(
            startTime: prevSubtitle.endTime + 10,
            endTime: subtitle.endTime,
            text: subtitle.text,
          );
          hasChanges = true;
        }
      }

      fixedSubtitles.add(subtitle);
    }

    if (hasChanges) {
      _logger.i('Fixed subtitle timing issues');
      final updatedVideoContent = videoContent!.copyWith(
        subtitles: fixedSubtitles,
      );

      // No longer saving to repository, just update local instance
      videoContent = updatedVideoContent;
    }
  }

  /// Set up the YouTube player position listener
  void setupYouTubeListener() {
    if (isYoutubeVideo && youtubeController != null) {
      positionTimer?.cancel(); // Cancel any existing timer

      positionTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) {
        if (youtubeController == null) {
          timer.cancel();
          return;
        }

        if (youtubeController!.value.isPlaying) {
          final position = youtubeController!.value.position.inMilliseconds;
          final subtitles = videoContent?.subtitles ?? [];

          int index = subtitles.indexWhere(
            (subtitle) =>
                position >= subtitle.startTime && position <= subtitle.endTime,
          );

          if (index != currentSubtitleIndex) {
            currentSubtitleIndex = index;
            onSubtitleIndexChanged();
          }
        }
      });
    }
  }

  /// Seek to specific time in YouTube video
  void seekYouTubeToTime(int milliseconds) {
    if (youtubeController != null && isYoutubePlayerReady) {
      youtubeController!.seekTo(Duration(milliseconds: milliseconds));

      Future.delayed(const Duration(milliseconds: 300), () {
        youtubeController?.play();
      });
    }
  }



  /// Create a vocabulary item from a selected word
  VocabularyItem createVocabularyItem(String word) {
    return VocabularyItem(
      id: const Uuid().v4(),
      word: word,
      definition: '',
      example: '',
      sourceVideoId: videoId,
      dateAdded: DateTime.now(),
    );
  }

  /// Save vocabulary item to storage
  Future<void> saveVocabularyItem(
    VocabularyItem item,
    String definition,
    String example,
  ) async {
    try {
      // Create updated item with definition and example
      final updatedWord = item.copyWith(definition: definition, example: example);

      // Save to storage
      await _storageService.saveVocabularyItem(updatedWord);
      _logger.i('Successfully saved vocabulary item: ${updatedWord.word}');
    } catch (e) {
      _logger.e('Failed to save vocabulary item', e);
      throw Exception('Failed to save vocabulary item: $e');
    }
  }
}
