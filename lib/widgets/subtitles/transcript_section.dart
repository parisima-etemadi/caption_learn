import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_content.dart';
import '../../utils/time_formatter.dart';
import 'subtitle_display.dart';

class TranscriptSection extends StatelessWidget {
  final VideoContent? videoContent;
  final int currentSubtitleIndex;
  final bool isYoutubeVideo;
  final VideoPlayerController? controller;
  final VoidCallback onAddTranscript;
  final Function(String) onSelectWord;
  final Function(int) onSeekYouTube;

  const TranscriptSection({
    Key? key,
    required this.videoContent,
    required this.currentSubtitleIndex,
    required this.isYoutubeVideo,
    required this.controller,
    required this.onAddTranscript,
    required this.onSelectWord,
    required this.onSeekYouTube,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (videoContent == null) {
      return const SizedBox.shrink();
    }
    
    if (videoContent!.subtitles.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return _buildTranscriptList(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transcript',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
            
            // Empty state content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.subtitles_off,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No transcript available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: onAddTranscript,
                      child: const Text('Add Transcript'),
                    ),
                  ],
                ),
              ),
            ),
    
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptList(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transcript',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
                        onPressed: () {
                          // Options menu
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                        onPressed: () {
                          // This would typically toggle transcript view
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Divider
            Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
            
            // Scripts list with timestamps
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: videoContent!.subtitles.length,
                itemBuilder: (context, index) {
                  final subtitle = videoContent!.subtitles[index];
                  final isCurrentSubtitle = index == currentSubtitleIndex;
                  
                  return InkWell(
                  onTap: () {
                    final startTimeMs = subtitle.startTime;
                    
                    if (!isYoutubeVideo && controller != null) {
                      controller!.pause();
                      controller!.seekTo(Duration(milliseconds: startTimeMs));
                      
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (controller != null) {
                          controller!.play();
                        }
                      });
                    } else {
                      onSeekYouTube(startTimeMs);
                    }
                  },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: isCurrentSubtitle 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timestamp in blue bubble
                          Container(
                            width: 50,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            margin: const EdgeInsets.only(right: 12, top: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                TimeFormatter.formatTimestamp(subtitle.startTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          
                          // Subtitle text with word selection capability
                          Expanded(
                            child: GestureDetector(
                              onLongPress: () {
                                _showWordSelectionDialog(context, subtitle.text);
                              },
                              child: SubtitleDisplay(
                                subtitle: subtitle,
                                isHighlighted: isCurrentSubtitle,
                                onWordTap: onSelectWord,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Language selector at bottom
          ],
        ),
      ),
    );
  }

 

  void _showWordSelectionDialog(BuildContext context, String text) {
    final words = text.split(' ')
        .map((word) => word.replaceAll(RegExp(r'[^\w\s]'), ''))
        .where((word) => word.isNotEmpty)
        .toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a word to add to vocabulary'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: words.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(words[index]),
                onTap: () {
                  Navigator.pop(context);
                  onSelectWord(words[index]);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 