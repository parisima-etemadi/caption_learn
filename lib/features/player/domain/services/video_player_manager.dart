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

  VideoPlayerController? controller;
  YoutubePlayerController? youtubeController;
  VideoContent? videoContent;
  bool isInitialized = false;
  bool isLoading = true;
  bool get isYoutubeVideo => videoContent?.source == VideoSource.youtube;

  int currentSubtitleIndex = -1;
  final ValueNotifier<Subtitle?> currentSubtitleNotifier = ValueNotifier(null);
  final ValueNotifier<int> currentPositionNotifier = ValueNotifier(0);
  final ValueNotifier<bool> showSubtitlesNotifier = ValueNotifier(true);
  final ValueNotifier<bool> isLoopingNotifier = ValueNotifier(false);
  Timer? positionTimer;
  StreamSubscription? _ytStateSubscription;
  bool _isDisposed = false;

  VideoPlayerManager({
    required this.videoId,
    required this.onSubtitleIndexChanged,
    required this.onLoadingChanged,
    required this.onInitialized,
  }) {
    _speechService.initialize();
  }

  Future<void> loadVideo(BuildContext context) async {
    isLoading = true;
    onLoadingChanged();
    try {
      _logger.i('Loading video with ID: $videoId');
      videoContent = _storageService.getVideoById(videoId);
      if (videoContent == null) {
        throw Exception('Video with ID $videoId not found');
      }
      _logger.i('Successfully loaded video: ${videoContent!.title}');
      validateAndFixSubtitles();
      await initializeVideoPlayer(context);
    } catch (e) {
      _logger.e('Error loading video', e);
      _showError(context, 'Error loading video: ${e.toString()}');
    } finally {
      isLoading = false;
      onLoadingChanged();
    }
  }

  void _showError(BuildContext context, String message) {
    if (_isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Navigator.of(context).pop();
  }

  Future<void> initializeVideoPlayer(BuildContext context) async {
    if (videoContent!.source == VideoSource.youtube) {
      await initializeYouTubeVideo(context);
    } else {
      await initializeLocalVideo(context);
    }
    setupPositionListener();
  }

  Future<void> initializeYouTubeVideo(BuildContext context) async {
    final ytVideoId =
        YoutubePlayerController.convertUrlToId(videoContent!.sourceUrl);
    if (ytVideoId != null) {
      youtubeController = YoutubePlayerController.fromVideoId(
        videoId: ytVideoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
            showControls: true, showFullscreenButton: true),
      );
      // Wait for the player to be ready
      await Future.delayed(const Duration(seconds: 2));
      isInitialized = true;
      onInitialized();
    } else {
      _showError(context, 'Invalid YouTube URL');
    }
  }

  Future<void> initializeLocalVideo(BuildContext context) async {
    final localPath = videoContent!.localPath;
    if (localPath == null || !File(localPath).existsSync()) {
      _showError(context, 'Local video file not found at path: $localPath');
      return;
    }
    controller = VideoPlayerController.file(File(localPath));
    await controller!.initialize();
    isInitialized = true;
    onInitialized();
  }

  void dispose() {
    _isDisposed = true;
    positionTimer?.cancel();
    _ytStateSubscription?.cancel();
    controller?.removeListener(_onLocalPlayerPositionChanged);
    controller?.dispose();
    youtubeController?.close();
    _speechService.dispose();
    _ttsService.dispose();
    _logger.d('Disposed player resources');
  }

  void _onLocalPlayerPositionChanged() {
    if (!controller!.value.isPlaying || _isDisposed) return;
    final position = controller!.value.position.inMilliseconds;
    currentPositionNotifier.value = position;
    _updateSubtitle(position);
  }

  void setupPositionListener() {
    positionTimer?.cancel(); // Cancel any existing timer
    if (isYoutubeVideo) {
      youtubeController?.listen((event) async {
        if (event.playerState == PlayerState.playing && !_isDisposed) {
          final position = (await youtubeController!.currentTime) * 1000;
          currentPositionNotifier.value = position.toInt();
          _updateSubtitle(position.toInt());
        }
      });
    } else {
      controller?.addListener(_onLocalPlayerPositionChanged);
    }
  }

  void _updateSubtitle(int position) {
    if (isLoopingNotifier.value && currentSubtitleNotifier.value != null) {
      if (position >= currentSubtitleNotifier.value!.endTime) {
        seekTo(currentSubtitleNotifier.value!.startTime);
        return;
      }
    }

    final subtitles = videoContent?.subtitles ?? [];
    int index = subtitles.indexWhere(
      (s) => position >= s.startTime && position <= s.endTime,
    );

    if (index != currentSubtitleIndex) {
      currentSubtitleIndex = index;
      currentSubtitleNotifier.value = index != -1 ? subtitles[index] : null;
      onSubtitleIndexChanged();
      if (isLoopingNotifier.value) {
        isLoopingNotifier.value = false;
      }
    }
  }

  void play() {
    isYoutubeVideo ? youtubeController?.playVideo() : controller?.play();
  }

  void pause() {
    isYoutubeVideo ? youtubeController?.pauseVideo() : controller?.pause();
  }

  void seekTo(int milliseconds) {
    if (isYoutubeVideo) {
      youtubeController
          ?.seekTo(seconds: milliseconds / 1000, allowSeekAhead: true);
    } else {
      controller?.seekTo(Duration(milliseconds: milliseconds));
    }
  }

  void validateAndFixSubtitles() {
    if (videoContent == null || videoContent!.subtitles.isEmpty) return;
    final subtitles = videoContent!.subtitles;
    final fixedSubtitles = <Subtitle>[];
    bool hasChanges = false;
    for (int i = 0; i < subtitles.length; i++) {
      var sub = subtitles[i];
      if (sub.startTime >= sub.endTime) {
        sub = sub.copyWith(endTime: sub.startTime + 3000);
        hasChanges = true;
      }
      if (i > 0 && sub.startTime < fixedSubtitles[i - 1].endTime) {
        sub = sub.copyWith(startTime: fixedSubtitles[i - 1].endTime + 10);
        hasChanges = true;
      }
      fixedSubtitles.add(sub);
    }
    if (hasChanges) {
      _logger.i('Fixed subtitle timing issues');
      videoContent = videoContent!.copyWith(subtitles: fixedSubtitles);
    }
  }

  void toggleSubtitles() =>
      showSubtitlesNotifier.value = !showSubtitlesNotifier.value;
  void toggleLooping() => isLoopingNotifier.value = !isLoopingNotifier.value;

  SpeechService get speechService => _speechService;
  TtsService get ttsService => _ttsService;

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

  Future<void> saveVocabularyItem(
      VocabularyItem item, String definition, String example) async {
    try {
      final updatedWord =
          item.copyWith(definition: definition, example: example);
      await _storageService.saveVocabularyItem(updatedWord);
      _logger.i('Successfully saved vocabulary item: ${updatedWord.word}');
    } catch (e) {
      _logger.e('Failed to save vocabulary item', e);
      throw Exception('Failed to save vocabulary item: $e');
    }
  }
}
