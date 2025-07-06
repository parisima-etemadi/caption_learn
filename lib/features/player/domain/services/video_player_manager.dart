// lib/features/player/domain/services/video_player_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/storage_service.dart';
import '../../../vocabulary/models/vocabulary_item.dart';
import '../../../video/data/models/video_content.dart';
import '../../../video/domain/enum/video_source.dart';
import '../../../../services/speech_service.dart';
import '../../../../services/tts_service.dart';

/// Manager class that handles video player logic and state
class VideoPlayerManager {
  final String videoId;
  final VoidCallback onSubtitleIndexChanged;
  final VoidCallback onLoadingChanged;
  final VoidCallback onInitialized;
  final Logger _logger = const Logger('VideoPlayerManager');
  final StorageService _storageService = StorageService();
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();


  VideoPlayerController? controller; // For future local video support
  YoutubePlayerController? youtubeController;
  VideoContent? videoContent;
  bool isInitialized = false;
  bool isLoading = true;
  bool isYoutubeVideo = false;
  int currentSubtitleIndex = -1;
  final ValueNotifier<Subtitle?> currentSubtitleNotifier = ValueNotifier(null);
  final ValueNotifier<int> currentPositionNotifier = ValueNotifier(0);
  final ValueNotifier<bool> showSubtitlesNotifier = ValueNotifier(true);
  final ValueNotifier<bool> isLoopingNotifier = ValueNotifier(false);
  Timer? positionTimer;
  StreamSubscription? _ytStateSubscription;
  bool _isDisposed = false;
  bool _isYouTubeListenerSetup = false;
  
  VideoPlayerManager({
    required this.videoId,
    required this.onSubtitleIndexChanged,
    required this.onLoadingChanged,
    required this.onInitialized,
  }) {
    _speechService.initialize();
  }

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
    final ytVideoId = YoutubePlayerController.convertUrlToId(videoContent!.sourceUrl);
    if (ytVideoId != null) {
      youtubeController = YoutubePlayerController.fromVideoId(
        videoId: ytVideoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );

      _ytStateSubscription = youtubeController!.stream.listen((event) {
        // Player is ready when it's cued or playing for the first time
        if (!_isYouTubeListenerSetup &&
            (event.playerState == PlayerState.cued ||
                event.playerState == PlayerState.playing)) {
          _logger.i("YouTube player is ready. Setting up subtitle listener.");
          setupYouTubeListener();
          _isYouTubeListenerSetup = true;
        }
      });

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
    _ytStateSubscription?.cancel();
    _speechService.dispose();
    _ttsService.dispose();
    youtubeController?.close();
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

      // Check position more frequently for smoother looping
      positionTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
        if (youtubeController == null || _isDisposed) {
          timer.cancel();
          return;
        }
        
        final playerState = await youtubeController!.playerState;
        if (playerState == PlayerState.playing) {
          final position = (await youtubeController!.currentTime) * 1000;
          currentPositionNotifier.value = position.toInt();

          // If looping is active, it takes precedence over advancing subtitles.
          if (isLoopingNotifier.value && currentSubtitleNotifier.value != null) {
            // When the video passes the end of the current subtitle, loop it back.
            if (position >= currentSubtitleNotifier.value!.endTime) {
              seekYouTubeToTime(currentSubtitleNotifier.value!.startTime);
              return; // Crucial: Prevents the logic below from running and breaking the loop.
            }
          }
          
          final subtitles = videoContent?.subtitles ?? [];

          int index = subtitles.indexWhere(
            (subtitle) =>
                position >= subtitle.startTime && position <= subtitle.endTime,
          );

          if (index != currentSubtitleIndex) {
            currentSubtitleIndex = index;
            currentSubtitleNotifier.value =
                index != -1 ? subtitles[index] : null;
            onSubtitleIndexChanged();
            
            // If the subtitle changes (e.g., user seeks manually), disable looping.
            // This is now safe because it won't be reached during an active loop.
            if (isLoopingNotifier.value) {
              isLoopingNotifier.value = false;
            }
          }
        }
      });
    }
  }

  void toggleSubtitles() {
    showSubtitlesNotifier.value = !showSubtitlesNotifier.value;
  }

  void toggleLooping() {
    isLoopingNotifier.value = !isLoopingNotifier.value;
  }

  SpeechService get speechService => _speechService;
  TtsService get ttsService => _ttsService;

  /// Seek to specific time in YouTube video
  void seekYouTubeToTime(int milliseconds) {
    if (youtubeController != null) {
      youtubeController!.seekTo(seconds: milliseconds / 1000, allowSeekAhead: true);

      Future.delayed(const Duration(milliseconds: 300), () {
        youtubeController!.playVideo();
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
