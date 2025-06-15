import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubePlayerWidget extends StatefulWidget {
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
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (!widget.isInitialized || widget.controller == null) {
      return const Center(
        child: Text('Error initializing YouTube player'),
      );
    }
    
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: widget.controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: widget.onReady,
        onEnded: (YoutubeMetaData metaData) {
          // Handle video end if needed
        },
        topActions: [
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              widget.controller!.metadata.title,
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
      ),
      builder: (context, player) => player,
    );
  }
}