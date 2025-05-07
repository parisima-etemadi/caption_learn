import 'package:caption_learn/widgets/player/custom_bottom_navigation.dart';
import 'package:flutter/material.dart';
import '../../controllers/video_player_controller.dart';
import '../../models/vocabulary_item.dart';
import '../../services/storage_service.dart';
import '../../widgets/dialogs/vocabulary_dialog.dart';
import '../../widgets/dialogs/transcript_dialog.dart';
import '../../widgets/indicators/learned_words_indicator.dart';
import '../../widgets/player/local_video_player_widget.dart';
import '../../widgets/player/youtube_player_widget.dart';
import '../../widgets/subtitles/transcript_section.dart';
import '../../features/vocabulary/screens/vocabulary_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  
  const VideoPlayerScreen({
    super.key, 
    required this.videoId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerManager _playerManager;
  final TextEditingController _definitionController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  bool _showControls = true;
  VocabularyItem? _selectedWord;
  int _activeNavIndex = 2;
  @override
  void initState() {
    super.initState();
    
    _playerManager = VideoPlayerManager(
      videoId: widget.videoId,
      storageService: StorageService(),
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
    
    _playerManager.loadVideo(context);
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
      _playerManager.youtubeController!.pause();
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
            _playerManager.youtubeController?.play();
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
        _playerManager.youtubeController?.play();
      } else {
        _playerManager.controller?.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          : Column(
              children: [
                _buildVideoPlayerSection(),
                _buildTranscriptSection(),
              ],
            ),
            bottomNavigationBar: CustomBottomNavigation(
      currentIndex: _activeNavIndex,
      onTap: (index) {
        setState(() {
          _activeNavIndex = index;
        });
      },    
         ),
    );
  }
  
  Widget _buildVideoPlayerSection() {
    return Stack(
      children: [
        Container(
          color: Colors.black,
          width: double.infinity,
          child: _playerManager.isYoutubeVideo 
            ? YouTubePlayerWidget(
                controller: _playerManager.youtubeController,
                isInitialized: _playerManager.isInitialized,
                onReady: () {
                  setState(() {
                    _playerManager.isYoutubePlayerReady = true;
                    _playerManager.youtubeController?.play();
                  });
                  _playerManager.setupYouTubeListener();
                },
              )
            : LocalVideoPlayerWidget(
                controller: _playerManager.controller,
                isInitialized: _playerManager.isInitialized,
                showControls: _showControls,
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                },
                currentSubtitleIndex: _playerManager.currentSubtitleIndex,
                videoContent: _playerManager.videoContent,
                selectedWord: _selectedWord,
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
  
  Widget _buildTranscriptSection() {
    return TranscriptSection(
      videoContent: _playerManager.videoContent,
      currentSubtitleIndex: _playerManager.currentSubtitleIndex,
      isYoutubeVideo: _playerManager.isYoutubeVideo,
      controller: _playerManager.controller,
      onAddTranscript: () {
        showDialog(
          context: context,
          builder: (context) => const TranscriptDialog(),
        );
      },
      onSelectWord: _selectWord,
      onSeekYouTube: _playerManager.seekYouTubeToTime,
    );
  }
} 