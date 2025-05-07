import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_content.dart';
import '../../utils/time_formatter.dart';
import 'subtitle_display.dart';

class TranscriptPanel extends StatefulWidget {
  final VideoContent? videoContent;
  final int currentSubtitleIndex;
  final bool isYoutubeVideo;
  final VideoPlayerController? controller;
  final Function(String) onWordTap;
  final Function(int) onSeekToTime;
  final VoidCallback onClose;

  const TranscriptPanel({
    Key? key,
    required this.videoContent,
    required this.currentSubtitleIndex,
    required this.isYoutubeVideo,
    required this.controller,
    required this.onWordTap,
    required this.onSeekToTime,
    required this.onClose,
  }) : super(key: key);

  @override
  State<TranscriptPanel> createState() => _TranscriptPanelState();
}

class _TranscriptPanelState extends State<TranscriptPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closePanel() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  void _showLanguageOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                trailing:
                    _selectedLanguage == 'English'
                        ? const Icon(Icons.check)
                        : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'English';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Spanish'),
                trailing:
                    _selectedLanguage == 'Spanish'
                        ? const Icon(Icons.check)
                        : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = 'Spanish';
                  });
                  Navigator.pop(context);
                },
              ),
              // Add more languages as needed
            ],
          ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy transcript'),
                onTap: () {
                  // Implement copy functionality
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share transcript'),
                onTap: () {
                  // Implement share functionality
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download transcript'),
                onTap: () {
                  // Implement download functionality
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            MediaQuery.of(context).size.height * _slideAnimation.value,
          ),
          child: child,
        );
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with title and controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: _showOptionsMenu,
                        tooltip: 'Options',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: _closePanel,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Transcript content
            Expanded(
              child:
                  widget.videoContent == null ||
                          widget.videoContent!.subtitles.isEmpty
                      ? _buildEmptyState()
                      : _buildTranscriptList(),
            ),

            // Language selector at bottom
            _buildLanguageSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.subtitles_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No transcript available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add subtitles to view the transcript',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptList() {
    final subtitles = widget.videoContent!.subtitles;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: subtitles.length,
      itemBuilder: (context, index) {
        final subtitle = subtitles[index];
        final isCurrentSubtitle = index == widget.currentSubtitleIndex;

        return InkWell(
          onTap: () => widget.onSeekToTime(subtitle.startTime),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color:
                  isCurrentSubtitle
                      ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamp
                SizedBox(
                  width: 70,
                  child: Text(
                    TimeFormatter.formatDuration(subtitle.startTime),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isCurrentSubtitle
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          isCurrentSubtitle
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                    ),
                  ),
                ),
                // Subtitle text
                Expanded(
                  child: SubtitleDisplay(
                    subtitle: subtitle,
                    isHighlighted: isCurrentSubtitle,
                    onWordTap: widget.onWordTap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: InkWell(
        onTap: _showLanguageOptions,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _selectedLanguage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_drop_up,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
