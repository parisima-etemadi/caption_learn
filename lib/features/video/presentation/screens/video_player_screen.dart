import 'package:caption_learn/core/widgets/learned_words_indicator.dart';
import 'package:caption_learn/features/player/domain/services/video_player_manager.dart';
import 'package:caption_learn/features/vocabulary/models/vocabulary_item.dart';
import 'package:caption_learn/features/vocabulary/presentation/widgets/vocabulary_dialog.dart';
import 'package:caption_learn/services/storage_service.dart';
import 'package:caption_learn/features/player/presentation/widgets/custom_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../player/presentation/widgets/subtitle_display.dart';
import '../../../player/presentation/widgets/youtube_player_widget.dart';
import '../../../vocabulary/presentation/screens/vocabulary_screen.dart';

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
    
    if (_playerManager.isYoutubeVideo && _playerManager.youtubeController != null) {
      _playerManager.youtubeController!.pauseVideo();
    } else if (_playerManager.controller != null) {
      _playerManager.controller!.pause();
    }
    
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
          if (_playerManager.isYoutubeVideo) {
            _playerManager.youtubeController?.playVideo();
          } else {
            _playerManager.controller?.play();
          }
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
      
      if (_playerManager.isYoutubeVideo) {
        _playerManager.youtubeController?.playVideo();
      } else {
        _playerManager.controller?.play();
      }
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
              child: Column(
                children: [
                  Expanded(
                    child: _buildVideoPlayerSection(),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _activeNavIndex,
        showSubtitlesNotifier: _playerManager.showSubtitlesNotifier,
        onTap: (index) {
          if (index == 1) {
            // Handle subtitle toggle without changing the main active index
            _playerManager.toggleSubtitles();
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
  
  Widget _buildVideoPlayerSection() {
    // Ensure we have a unique key for the player
    final playerKey = ValueKey('youtube_player_${widget.videoId}');
    
    return Stack(
      children: [
        Container(
          color: Colors.black,
          width: double.infinity,
          child: _playerManager.isInitialized && _playerManager.youtubeController != null
              ? YoutubePlayerWidget(
                  key: playerKey, // Add unique key
                  controller: _playerManager.youtubeController,
                )
              : const Center(
                  child: Text(
                    'Video player not available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ),
        
        if (_playerManager.videoContent != null)
          const Positioned(
            top: 16,
            left: 16,
            child: LearnedWordsIndicator(),
          ),
      ],
    );
  }
}