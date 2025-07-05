import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../features/vocabulary/models/vocabulary_item.dart';
import '../../../../features/vocabulary/presentation/widgets/vocabulary_dialog.dart';
import '../../domain/services/video_player_manager.dart';
import '../../../video/data/models/video_content.dart';
import 'subtitle_display.dart';

class YoutubePlayerWidget extends StatefulWidget {
  final YoutubePlayerController? controller;

  const YoutubePlayerWidget({Key? key, this.controller}) : super(key: key);

  @override
  _YoutubePlayerWidgetState createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late VideoPlayerManager _playerManager;
  final _definitionController = TextEditingController();
  final _exampleController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _playerManager = Provider.of<VideoPlayerManager>(context, listen: false);
  }

  @override
  void dispose() {
    _definitionController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  void _showVocabularyDialog(String word) {
    final newItem = _playerManager.createVocabularyItem(word);
    
    showDialog(
      context: context,
      builder: (context) => VocabularyDialog(
        selectedWord: newItem,
        definitionController: _definitionController,
        exampleController: _exampleController,
        onSave: () {
          _playerManager.saveVocabularyItem(
            newItem,
            _definitionController.text,
            _exampleController.text,
          );
          Navigator.of(context).pop();
          _definitionController.clear();
          _exampleController.clear();
        },
        onCancel: () {
          Navigator.of(context).pop();
          _definitionController.clear();
          _exampleController.clear();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        YoutubePlayer(
          controller: widget.controller!,
          aspectRatio: 16 / 9,
        ),

        // Subtitles display
        ValueListenableBuilder<Subtitle?>(
          valueListenable: _playerManager.currentSubtitleNotifier,
          builder: (context, subtitle, _) {
            return ValueListenableBuilder<int>(
              valueListenable: _playerManager.currentPositionNotifier,
              builder: (context, position, _) {
                return SubtitleDisplay(
                  currentSubtitle: subtitle,
                  onWordTap: (word) => _showVocabularyDialog(word),
                  currentPositionMs: position,
                );
              },
            );
          },
        ),
      ],
    );
  }
}