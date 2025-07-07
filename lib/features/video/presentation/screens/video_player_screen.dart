import 'package:caption_learn/core/widgets/learned_words_indicator.dart';
import 'package:caption_learn/features/player/domain/services/video_player_manager.dart';
import 'package:caption_learn/features/video/data/models/video_content.dart';
import 'package:caption_learn/features/vocabulary/models/vocabulary_item.dart';
import 'package:caption_learn/features/vocabulary/presentation/widgets/vocabulary_dialog.dart';
import 'package:caption_learn/services/storage_service.dart';
import 'package:caption_learn/features/player/presentation/widgets/custom_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../player/presentation/widgets/subtitle_display.dart';
import '../../../player/presentation/widgets/youtube_player_widget.dart';
import '../../../vocabulary/presentation/screens/vocabulary_screen.dart';
import '../../../player/presentation/widgets/say_it_dialog.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  
  const VideoPlayerScreen({
    super.key, 
    required this.videoId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with AutomaticKeepAliveClientMixin {
  late final VideoPlayerManager _playerManager;
  final TextEditingController _definitionController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  bool _showControls = true;
  VocabularyItem? _selectedWord;
  int _activeNavIndex = 2;
  
  // Add this to prevent recreation
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    
    _playerManager = VideoPlayerManager(
      videoId: widget.videoId,
      onSubtitleIndexChanged: () {
        if (mounted) setState(() {});
      },
      onLoadingChanged: () {
        if (mounted) setState(() {});
      },
      onInitialized: () {
        if (mounted) setState(() {});
      },
    );
    
    // Use post frame callback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playerManager.loadVideo(context);
    });
  }
  
  @override
  void dispose() {
    _playerManager.dispose();
    _definitionController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  void _selectWord(String word) {
    setState(() {
      _showControls = true;
      _selectedWord = _playerManager.createVocabularyItem(word);
    });
    
    _playerManager.pause();
    
    _showVocabularyDialog();
  }

  void _showVocabularyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VocabularyDialog(
        selectedWord: _selectedWord!,
        definitionController: _definitionController,
        exampleController: _exampleController,
        onSave: _saveVocabularyItem,
        onCancel: () {
          Navigator.of(context).pop();
          _playerManager.play();
        },
      ),
    );
  }

  void _saveVocabularyItem() async {
    if (_selectedWord == null) return;
    
    await _playerManager.saveVocabularyItem(
      _selectedWord!, 
      _definitionController.text, 
      _exampleController.text
    );
    
    _definitionController.clear();
    _exampleController.clear();
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedWord!.word} added to vocabulary')),
      );
      
      _playerManager.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_playerManager.videoContent?.title ?? 'Video Player'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.book),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VocabularyScreen(
                    videoId: widget.videoId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _playerManager.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Provider.value(
              value: _playerManager,
              child: _buildVideoPlayerSection(),
            ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _activeNavIndex,
        showSubtitlesNotifier: _playerManager.showSubtitlesNotifier,
        isLoopingNotifier: _playerManager.isLoopingNotifier,
        onTap: (index) {
          if (index == 1) {
            // Handle subtitle toggle without changing the main active index
            _playerManager.toggleSubtitles();
          } else if (index == 0 || index == 2) {
            // Handle repeat and loop actions
            _playerManager.toggleLooping();
            setState(() {
              _activeNavIndex = 2; // Keep loop as the main active button
            });
          } else if (index == 4) {
            _handleSayIt();
          } else {
            // Set the active index for other buttons
            setState(() {
              _activeNavIndex = index;
            });
          }
        },
      ),
    );
  }
  
  void _handleSayIt() {
    final currentSubtitle = _playerManager.currentSubtitleNotifier.value;
    if (currentSubtitle != null) {
      _playerManager.pause();
      showDialog(
        context: context,
        builder: (_) => SayItDialog(
          correctText: currentSubtitle.text,
          speechService: _playerManager.speechService,
          ttsService: _playerManager.ttsService,
        ),
      ).then((_) {
        // Resume playback when the dialog is closed
        _playerManager.play();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active subtitle to practice.")),
      );
    }
  }

  Widget _buildVideoPlayerSection() {
    final playerKey = ValueKey('video_player_${widget.videoId}');
    
    if (!_playerManager.isInitialized) {
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: const Center(
          child: Text(
            'Video player not available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return _playerManager.isYoutubeVideo
        ? YoutubePlayerWidget(
            key: playerKey,
            controller: _playerManager.youtubeController,
          )
        : _buildLocalVideoPlayer();
  }

  Widget _buildLocalVideoPlayer() {
    return Column(
      children: [
        Container(
          color: Colors.black,
          child: GestureDetector(
            onTap: () {
              if (_playerManager.controller == null) return;
              setState(() {
                if (_playerManager.controller!.value.isPlaying) {
                  _playerManager.pause();
                } else {
                  _playerManager.play();
                }
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _playerManager.controller!.value.aspectRatio,
                  child: VideoPlayer(_playerManager.controller!),
                ),
                if (!_playerManager.controller!.value.isPlaying)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 40),
                        onPressed: () {
                          if (_playerManager.controller == null) return;
                          final currentPosition = _playerManager.controller!.value.position;
                          var newPosition = currentPosition - const Duration(seconds: 10);
                          if (newPosition < Duration.zero) {
                            newPosition = Duration.zero;
                          }
                          _playerManager.seekTo(newPosition.inMilliseconds);
                        },
                      ),
                      const SizedBox(width: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white, size: 40),
                        onPressed: () {
                          if (_playerManager.controller == null) return;
                          final currentPosition = _playerManager.controller!.value.position;
                          final videoDuration = _playerManager.controller!.value.duration;
                          var newPosition = currentPosition + const Duration(seconds: 10);
                          if (newPosition > videoDuration) {
                            newPosition = videoDuration;
                          }
                          _playerManager.seekTo(newPosition.inMilliseconds);
                        },
                      ),
                    ],
                  ),
                if (_playerManager.videoContent != null)
                  const Positioned(
                    top: 16,
                    left: 16,
                    child: LearnedWordsIndicator(),
                  ),
              ],
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _playerManager.showSubtitlesNotifier,
          builder: (context, showSubtitles, _) {
            if (!showSubtitles) {
              return const SizedBox(height: 80);
            }
            return ValueListenableBuilder<Subtitle?>(
              valueListenable: _playerManager.currentSubtitleNotifier,
              builder: (context, subtitle, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: _playerManager.currentPositionNotifier,
                  builder: (context, position, _) {
                    return SubtitleDisplay(
                      currentSubtitle: subtitle,
                      onWordTap: (word) => _selectWord(word),
                      currentPositionMs: position,
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}