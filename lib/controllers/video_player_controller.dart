import 'dart:async';
import 'dart:io';
import 'package:caption_learn/services/youtube_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/video_content.dart';
import '../models/vocabulary_item.dart';
import '../services/storage_service.dart';

/// Manager class that handles video player logic and state
class VideoPlayerManager {
  final String videoId;
  final StorageService storageService;
  final VoidCallback onSubtitleIndexChanged;
  final VoidCallback onLoadingChanged;
  final VoidCallback onInitialized;
  
  VideoPlayerController? controller;
  YoutubePlayerController? youtubeController;
  VideoContent? videoContent;
  bool isInitialized = false;
  bool isLoading = true;
  bool isYoutubeVideo = false;
  bool isYoutubePlayerReady = false;
  int currentSubtitleIndex = -1;
  Timer? positionTimer;
  
  VideoPlayerManager({
    required this.videoId,
    required this.storageService,
    required this.onSubtitleIndexChanged,
    required this.onLoadingChanged,
    required this.onInitialized,
  });
  
  /// Load the video content and initialize the appropriate player
  Future<void> loadVideo(BuildContext context) async {
    isLoading = true;
    onLoadingChanged();
    
    try {
      final video = await storageService.getVideoById(videoId);
      
      if (video == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video not found')),
        );
        Navigator.pop(context);
        return;
      }
      
      videoContent = video;
      isYoutubeVideo = video.source == VideoSource.youtube;
      
      validateAndFixSubtitles();
      
      await initializeVideoPlayer(context);
      
      isLoading = false;
      onLoadingChanged();
      
      if (!isYoutubeVideo) {
        controller?.addListener(updateCurrentSubtitle);
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading video: ${e.toString()}')),
      );
      Navigator.pop(context);
    }
  }
  
  /// Initialize the appropriate video player based on content source
  Future<void> initializeVideoPlayer(BuildContext context) async {
    if (videoContent == null) return;
    
    if (videoContent!.source == VideoSource.local && videoContent!.localPath != null) {
      await initializeLocalVideo(context);
    } else if (videoContent!.source == VideoSource.youtube) {
      await initializeYouTubeVideo(context);
    } else {
      showUnsupportedSourceError(context);
    }
  }

  /// Initialize the local video player
  Future<void> initializeLocalVideo(BuildContext context) async {
    controller = VideoPlayerController.file(File(videoContent!.localPath!));
    try {
      await controller!.initialize();
      isInitialized = true;
      onInitialized();
      controller!.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing video: ${e.toString()}')),
      );
    }
  }

  /// Initialize the YouTube video player
  Future<void> initializeYouTubeVideo(BuildContext context) async {
    final ytVideoId = YoutubePlayer.convertUrlToId(videoContent!.sourceUrl);
    if (ytVideoId != null) {
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
        // Implementation for fetching subtitles would be called here
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid YouTube URL')),
      );
      Navigator.pop(context);
    }
  }

  /// Show error for unsupported video sources
  void showUnsupportedSourceError(BuildContext context) {
    String message = 'This video source is not yet supported for playback';
    if (videoContent!.source == VideoSource.instagram) {
      message = 'Instagram videos are currently not supported for playback';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pop(context);
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
      final updatedVideoContent = videoContent!.copyWith(
        subtitles: fixedSubtitles,
      );
      
      storageService.saveVideo(updatedVideoContent);
      videoContent = updatedVideoContent;
    }
  }

  /// Update the current subtitle index based on video position
  void updateCurrentSubtitle() {
    if (controller == null || videoContent == null || !controller!.value.isPlaying) {
      return;
    }
    
    final currentPosition = controller!.value.position.inMilliseconds;
    final subtitles = videoContent!.subtitles;
    
    int index = subtitles.indexWhere((subtitle) => 
      currentPosition >= subtitle.startTime && currentPosition <= subtitle.endTime);
    
    if (index != currentSubtitleIndex) {
      currentSubtitleIndex = index;
      onSubtitleIndexChanged();
    }
  }

  /// Set up the YouTube player position listener
  void setupYouTubeListener() {
    if (isYoutubeVideo && youtubeController != null) {
      positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (youtubeController == null) {
          timer.cancel();
          return;
        }
        
        if (youtubeController!.value.isPlaying) {
          final position = youtubeController!.value.position.inMilliseconds;
          final subtitles = videoContent?.subtitles ?? [];
          
          int index = subtitles.indexWhere((subtitle) => 
            position >= subtitle.startTime && position <= subtitle.endTime);
          
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

  /// Clean up resources when disposed
  void dispose() {
    controller?.dispose();
    youtubeController?.dispose();
    positionTimer?.cancel();
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
  Future<void> saveVocabularyItem(VocabularyItem item, String definition, String example) async {
    final updatedWord = item.copyWith(
      definition: definition,
      example: example,
    );
    
    await storageService.saveVocabularyItem(updatedWord);
  }
} 