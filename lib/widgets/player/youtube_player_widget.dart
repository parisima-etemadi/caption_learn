import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubePlayerWidget extends StatelessWidget {
  final YoutubePlayerController? controller;
  final bool isInitialized;
  final VoidCallback onReady;

  const YouTubePlayerWidget({
    Key? key,
    required this.controller,
    required this.isInitialized,
    required this.onReady,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || controller == null) {
      return const Center(
        child: Text('Error initializing YouTube player'),
      );
    }
    
    return YoutubePlayer(
      controller: controller!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.red,
      progressColors: const ProgressBarColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
      ),
      onReady: onReady,
      onEnded: (YoutubeMetaData metaData) {
        // Handle video end if needed
      },
      // Add these to improve UI and interaction
      topActions: [
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            controller!.metadata.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.0,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
      bottomActions: [
        CurrentPosition(),
        const SizedBox(width: 10.0),
        ProgressBar(
          isExpanded: true,
          colors: const ProgressBarColors(
            playedColor: Colors.red,
            handleColor: Colors.redAccent,
          ),
        ),
        const SizedBox(width: 10.0),
        RemainingDuration(),
        FullScreenButton(),
      ],
    );
  }
} 