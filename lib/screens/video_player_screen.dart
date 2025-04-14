import 'dart:async';
import 'dart:io';
import 'package:caption_learn/services/youtube_service.dart';
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
  bool _showAddTranscriptButton = false;
  Timer? _positionTimer;
  
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
    _positionTimer?.cancel();
    super.dispose();
  }

void _setupYouTubeListener() {
  // Only set up listener if this is a YouTube video and controller exists
  if (_isYoutubeVideo && _youtubeController != null) {
    // Add a periodic timer to check YouTube player position
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _youtubeController == null) {
        timer.cancel();
        return;
      }
      
      if (_youtubeController!.value.isPlaying) {
        final position = _youtubeController!.value.position.inMilliseconds;
        final subtitles = _videoContent?.subtitles ?? [];
        
        // Find current subtitle based on position
        int index = subtitles.indexWhere((subtitle) => 
          position >= subtitle.startTime && position <= subtitle.endTime);
        
        if (index != _currentSubtitleIndex) {
          setState(() {
            _currentSubtitleIndex = index;
          });
        }
      }
    });
  }
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
    // YouTube handling
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
      
      // Give the controller a moment to initialize before setting up listener
      Future.delayed(const Duration(milliseconds: 500), () {
        _setupYouTubeListener();
      });
      
      // If we don't have subtitles yet, try to fetch them again
      if (_videoContent!.subtitles.isEmpty) {
        _fetchYouTubeSubtitles(videoId);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid YouTube URL')),
      );
      Navigator.pop(context);
    }
  } else if (_videoContent!.source == VideoSource.instagram) {
    // Instagram videos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instagram videos are currently not supported for playback')),
    );
    Navigator.pop(context);
  } else {
    // Other sources handling
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This video source is not yet supported for playback')),
    );
    Navigator.pop(context);
  }
}

void _showAddTranscriptDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add Transcript'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('You can add a transcript by:'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasteTranscriptDialog();
            },
            child: const Text('Paste from clipboard'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementation for uploading a subtitle file would go here
            },
            child: const Text('Upload SRT file'),
          ),
        ],
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

// Add this method to your _VideoPlayerScreenState class
void _showPasteTranscriptDialog() {
  final TextEditingController controller = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Paste Transcript'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Paste transcript text here...',
        ),
        maxLines: 10,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              _processManualTranscript(controller.text);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  ).then((_) {
    controller.dispose(); // Don't forget to dispose the controller
  });
}
Future<void> _fetchYouTubeSubtitles(String videoId) async {
  try {
    // Show loading indicator when fetching subtitles
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetching video subtitles...')),
      );
    }

    final subtitles = await YouTubeService.getYouTubeSubtitles(videoId);
    
    if (subtitles.isNotEmpty) {
      // Update video content with new subtitles
      final updatedVideoContent = _videoContent!.copyWith(subtitles: subtitles);
      
      // Save updated content
      await _storageService.saveVideo(updatedVideoContent);
      
      setState(() {
        _videoContent = updatedVideoContent;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subtitles loaded successfully!')),
        );
      }
    } else {
      // Show UI for manually adding transcript
      setState(() {
        _showAddTranscriptButton = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No subtitles found. You can add them manually.')),
        );
      }
    }
  } catch (e) {
    print('Error fetching YouTube subtitles: $e');
    // Show UI for manually adding transcript
    setState(() {
      _showAddTranscriptButton = true;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subtitles: ${e.toString()}')),
      );
    }
  }
}

void _processManualTranscript(String text) {
  // This is a simple implementation - in a real app, you'd want a more
  // sophisticated parser that can handle various formats
  final lines = text.split('\n');
  final List<Subtitle> subtitles = [];
  
  // Simple algorithm to convert plain text into timed subtitles
  // This assumes each line is a separate subtitle
  final videoDuration = _youtubeController?.metadata.duration.inMilliseconds ?? 0;
  if (videoDuration > 0 && lines.isNotEmpty) {
    final intervalMs = videoDuration ~/ lines.length;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        subtitles.add(
          Subtitle(
            startTime: i * intervalMs,
            endTime: (i + 1) * intervalMs,
            text: line,
          ),
        );
      }
    }
    
    // Update and save video content with new subtitles
    if (subtitles.isNotEmpty && _videoContent != null) {
      final updatedVideoContent = _videoContent!.copyWith(subtitles: subtitles);
      _storageService.saveVideo(updatedVideoContent);
      
      setState(() {
        _videoContent = updatedVideoContent;
        _showAddTranscriptButton = false;
      });
    }
  }
}
Widget _buildSubtitlesSection() {
  if (_videoContent == null) {
    return const SizedBox.shrink();
  }
  
  if (_videoContent!.subtitles.isEmpty) {
    // Show empty state with add transcript button
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
                      onPressed: _showAddTranscriptDialog,
                      child: const Text('Add Transcript'),
                    ),
                  ],
                ),
              ),
            ),
            
            // Language selector at bottom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                ),
              ),
              child: Text(
                'English',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // When subtitles are available, show the transcript
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
                        // For now we'll just keep it visible
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
              itemCount: _videoContent!.subtitles.length,
              itemBuilder: (context, index) {
                final subtitle = _videoContent!.subtitles[index];
                final isCurrentSubtitle = index == _currentSubtitleIndex;
                
                return InkWell(
                  onTap: () {
                    if (!_isYoutubeVideo && _controller != null) {
                      _controller!.seekTo(Duration(milliseconds: subtitle.startTime));
                      _controller!.play();
                    } else if (_youtubeController != null) {
                      _youtubeController!.seekTo(Duration(milliseconds: subtitle.startTime));
                      _youtubeController!.play();
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
                              _formatTimestampCNN(subtitle.startTime),
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
                              _showWordSelectionDialog(subtitle.text);
                            },
                            child: _buildTappableText(subtitle.text, isCurrentSubtitle),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
              ),
            ),
            child: Text(
              'English',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
                Stack(
                  children: [
                    // Video player section with colored background
                    Container(
                      color: Colors.black,
                      width: double.infinity,
                      child: _isYoutubeVideo 
                        ? _buildYoutubePlayer()
                        : _buildVideoPlayer(),
                    ),
                    
                    // Word count indicator like in Lingopie
                    if (_videoContent != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Words Learned',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Script section
                _buildSubtitlesSection(),
              ],
            ),
    );
  }
  
Widget _buildVideoPlayer() {
  if (!_isInitialized) {
    return const Center(
      child: Text('Error initializing video player'),
    );
  }
  
  // Regular video player for local videos
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
          // Display current word in larger text if a word is selected
          if (_selectedWord != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedWord!.word,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Display the full subtitle with tappable words
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 8,
            children: words.map((word) {
              // Remove punctuation for the selection
              final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
              final isHighlighted = _selectedWord != null && 
                                    _selectedWord!.word.toLowerCase() == cleanWord.toLowerCase();
              
              return InkWell(
                onTap: () => _selectWord(cleanWord),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isHighlighted 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                        : Colors.transparent,
                  ),
                  child: Text(
                    word,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Display translation if available (this would need to be added to your model)
          // if (_videoContent!.translationEnabled)
          //   Padding(
          //     padding: const EdgeInsets.only(top: 8),
          //     child: Text(
          //       "Translation text would go here",
          //       style: const TextStyle(
          //         color: Colors.white70,
          //         fontSize: 16,
          //         fontStyle: FontStyle.italic,
          //       ),
          //       textAlign: TextAlign.center,
          //     ),
          //   ),
        ],
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
  

  
  
  Widget _buildTappableText(String text, bool isHighlighted) {
    final words = text.split(' ');
    
    return Wrap(
      spacing: 4,
      children: words.map((word) {
        final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
        
        if (cleanWord.isEmpty) {
          return Text(
            word,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }
        
        return InkWell(
          onTap: () => _selectWord(cleanWord),
          borderRadius: BorderRadius.circular(4),
          child: Text(
            word,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
  
  String _formatTimestampCNN(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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