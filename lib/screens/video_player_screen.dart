import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/video_content.dart';
import '../models/vocabulary_item.dart';
import '../services/storage_service.dart';
import 'vocabulary_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  
  const VideoPlayerScreen({
    super.key, 
    required this.videoId,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final StorageService _storageService = StorageService();
  VideoPlayerController? _controller;
  YoutubePlayerController? _youtubeController;
  VideoContent? _videoContent;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _showControls = true;
  int _currentSubtitleIndex = -1;
  VocabularyItem? _selectedWord;
  bool _isYoutubeVideo = false;
  
  final TextEditingController _definitionController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadVideo();
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    _youtubeController?.dispose();
    _definitionController.dispose();
    _exampleController.dispose();
    super.dispose();
  }
  
  Future<void> _loadVideo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final video = await _storageService.getVideoById(widget.videoId);
      
      if (video == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video not found')),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      setState(() {
        _videoContent = video;
        _isYoutubeVideo = video.source == VideoSource.youtube;
      });
      
      await _initializeVideoPlayer();
      
      setState(() {
        _isLoading = false;
      });
      
      // Add a listener to update the current subtitle
      if (!_isYoutubeVideo) {
        _controller?.addListener(_updateCurrentSubtitle);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    }
  }
  
  Future<void> _initializeVideoPlayer() async {
    if (_videoContent == null) return;
    
    if (_videoContent!.source == VideoSource.local && _videoContent!.localPath != null) {
      _controller = VideoPlayerController.file(File(_videoContent!.localPath!));
      try {
        await _controller!.initialize();
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing video: ${e.toString()}')),
        );
      }
    } else if (_videoContent!.source == VideoSource.youtube) {
      // Extract YouTube video ID from URL
      final videoId = YoutubePlayer.convertUrlToId(_videoContent!.sourceUrl);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
          ),
        );
        setState(() {
          _isInitialized = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid YouTube URL')),
        );
        Navigator.pop(context);
      }
    } else {
      // For other sources, you'd need appropriate players
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This video source is not yet supported for playback')),
      );
      Navigator.pop(context);
    }
  }
  
  void _updateCurrentSubtitle() {
    if (_controller == null || _videoContent == null || !_controller!.value.isPlaying) {
      return;
    }
    
    final position = _controller!.value.position.inMilliseconds;
    final subtitles = _videoContent!.subtitles;
    
    int index = subtitles.indexWhere((subtitle) => 
      position >= subtitle.startTime && position <= subtitle.endTime);
    
    if (index != _currentSubtitleIndex) {
      setState(() {
        _currentSubtitleIndex = index;
      });
    }
  }
  
  void _togglePlayPause() {
    if (_controller == null) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }
  
  void _skipBack() {
    if (_controller == null) return;
    
    final currentPosition = _controller!.value.position.inMilliseconds;
    _controller!.seekTo(Duration(milliseconds: (currentPosition - 5000).clamp(0, _controller!.value.duration.inMilliseconds)));
  }
  
  void _skipForward() {
    if (_controller == null) return;
    
    final currentPosition = _controller!.value.position.inMilliseconds;
    _controller!.seekTo(Duration(milliseconds: (currentPosition + 5000).clamp(0, _controller!.value.duration.inMilliseconds)));
  }
  
  void _selectWord(String word) {
    setState(() {
      _controller?.pause();
      _selectedWord = VocabularyItem(
        id: const Uuid().v4(),
        word: word,
        definition: '',
        sourceVideoId: widget.videoId,
        dateAdded: DateTime.now(),
      );
      _definitionController.text = '';
      _exampleController.text = '';
    });
    _showAddVocabularyDialog();
  }
  
  Future<void> _saveVocabularyItem() async {
    if (_selectedWord == null || _definitionController.text.isEmpty) {
      return;
    }
    
    final updatedWord = _selectedWord!.copyWith(
      definition: _definitionController.text.trim(),
      example: _exampleController.text.trim().isNotEmpty 
          ? _exampleController.text.trim() 
          : null,
    );
    
    await _storageService.saveVocabularyItem(updatedWord);
    
    if (mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${updatedWord.word}" to vocabulary')),
      );
      setState(() {
        _selectedWord = null;
      });
      _controller?.play();
    }
  }
  
  Future<void> _showAddVocabularyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add "${_selectedWord?.word}" to Vocabulary'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                TextField(
                  controller: _definitionController,
                  decoration: const InputDecoration(
                    labelText: 'Definition',
                    hintText: 'Enter the definition',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _exampleController,
                  decoration: const InputDecoration(
                    labelText: 'Example (optional)',
                    hintText: 'Enter an example sentence',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _controller?.play();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                _saveVocabularyItem();
              },
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_videoContent?.title ?? 'Video Player'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _isYoutubeVideo 
                  ? _buildYoutubePlayer()
                  : _buildVideoPlayer(),
                _buildSubtitlesSection(),
              ],
            ),
    );
  }
  
  Widget _buildVideoPlayer() {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: Text('Error initializing video player'),
      );
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller!),
            if (_showControls)
              _buildVideoControls(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildYoutubePlayer() {
    if (!_isInitialized || _youtubeController == null) {
      return const Center(
        child: Text('Error initializing YouTube player'),
      );
    }
    
    return YoutubePlayer(
      controller: _youtubeController!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.red,
      progressColors: const ProgressBarColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
      ),
      onReady: () {
        _isInitialized = true;
      },
    );
  }
  
  Widget _buildVideoControls() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildSubtitleDisplay(),
          _buildControlsRow(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildSubtitleDisplay() {
    if (_currentSubtitleIndex == -1 || _videoContent == null) {
      return const SizedBox(height: 120);
    }
    
    final subtitle = _videoContent!.subtitles[_currentSubtitleIndex];
    final words = subtitle.text.split(' ');
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        children: words.map((word) {
          // Remove punctuation for the display word
          final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
          
          return InkWell(
            onTap: () => _selectWord(cleanWord),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.transparent,
              ),
              child: Text(
                word,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildControlsRow() {
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
            _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
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
  
  Widget _buildSubtitlesSection() {
    if (_videoContent == null || _videoContent!.subtitles.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _videoContent!.subtitles.length,
        itemBuilder: (context, index) {
          final subtitle = _videoContent!.subtitles[index];
          final isCurrentSubtitle = index == _currentSubtitleIndex;
          
          return Card(
            elevation: isCurrentSubtitle ? 3 : 1,
            color: isCurrentSubtitle 
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                subtitle.text,
                style: TextStyle(
                  fontWeight: isCurrentSubtitle ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                '${_formatDuration(subtitle.startTime)} - ${_formatDuration(subtitle.endTime)}',
              ),
              onTap: () {
                if (!_isYoutubeVideo && _controller != null) {
                  _controller!.seekTo(Duration(milliseconds: subtitle.startTime));
                }
                // For YouTube videos, seeking is more complex and might require
                // using the YouTube player controller's API
              },
              onLongPress: () {
                // Show a context menu to add selected words to vocabulary
                _showWordSelectionDialog(subtitle.text);
              },
            ),
          );
        },
      ),
    );
  }
  
  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  void _showWordSelectionDialog(String text) {
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
                  _selectWord(words[index]);
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