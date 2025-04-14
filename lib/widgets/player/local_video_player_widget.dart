import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_content.dart';
import '../../models/vocabulary_item.dart';

class LocalVideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool showControls;
  final VoidCallback onTap;
  final int currentSubtitleIndex;
  final VideoContent? videoContent;
  final VocabularyItem? selectedWord;

  const LocalVideoPlayerWidget({
    Key? key,
    required this.controller,
    required this.isInitialized,
    required this.showControls,
    required this.onTap,
    required this.currentSubtitleIndex,
    required this.videoContent,
    required this.selectedWord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Center(
        child: Text('Error initializing video player'),
      );
    }
    
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller!),
            if (showControls)
              _buildVideoControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildSubtitleDisplay(context),
          _buildControlsRow(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSubtitleDisplay(BuildContext context) {
    if (currentSubtitleIndex == -1 || videoContent == null) {
      return const SizedBox(height: 120);
    }
    
    final subtitle = videoContent!.subtitles[currentSubtitleIndex];
    final words = subtitle.text.split(' ');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedWord != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedWord!.word,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 8,
            children: words.map((word) {
              final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
              
              return Text(
                word,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
          onPressed: _skipBack,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 48,
          ),
          onPressed: _togglePlayPause,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
          onPressed: _skipForward,
        ),
      ],
    );
  }

  void _togglePlayPause() {
    if (controller == null) return;
    
    if (controller!.value.isPlaying) {
      controller!.pause();
    } else {
      controller!.play();
    }
  }

  void _skipBack() {
    if (controller == null) return;
    
    final currentPosition = controller!.value.position.inMilliseconds;
    controller!.seekTo(Duration(milliseconds: (currentPosition - 5000).clamp(0, controller!.value.duration.inMilliseconds)));
  }

  void _skipForward() {
    if (controller == null) return;
    
    final currentPosition = controller!.value.position.inMilliseconds;
    controller!.seekTo(Duration(milliseconds: (currentPosition + 5000).clamp(0, controller!.value.duration.inMilliseconds)));
  }
} 