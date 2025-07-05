// lib/features/video/presentation/screens/add_video_screen.dart
import 'dart:io';

import 'package:caption_learn/services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/logger.dart';
import '../../../video/domain/services/video_service.dart';
import '../../../../core/utils/youtube_utils.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  _AddVideoScreenState createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _videoService = VideoService();
  final _storageService = StorageService();
  final _logger = Logger('AddVideoScreen');

  bool _isProcessing = false;
  File? _subtitleFile;

  @override
  void dispose() {
    _urlController.dispose();
    _videoService.dispose();
    super.dispose();
  }

  Future<void> _pickSubtitleFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt'],
    );

    if (result != null) {
      setState(() {
        _subtitleFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _processVideo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final url = _urlController.text.trim();

      // Check if URL is a YouTube URL
      if (!YoutubeUtils.isYoutubeUrl(url)) {
        throw Exception('Only YouTube URLs are supported');
      }

      String? subtitleContent;
      if (_subtitleFile != null) {
        subtitleContent = await _subtitleFile!.readAsString();
      }

      // Process the video URL to get details and subtitles
      final videoContent = await _videoService.processVideoUrl(
        url,
        manualSubtitleContent: subtitleContent,
      );

      // Check if subtitles were found and handle warnings
      if (videoContent.subtitles.isEmpty && mounted) {
        if (videoContent.subtitleWarning != null) {
          // Show specific warning message - video will still be added
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${videoContent.subtitleWarning}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          // Show generic dialog for truly missing subtitles
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Subtitles Found'),
              content: const Text(
                'This video doesn\'t have subtitles available. You can still add it, but you won\'t be able to use the subtitle features.\n\nDo you want to continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );

          if (proceed != true) {
            setState(() {
              _isProcessing = false;
            });
            return;
          }
        }
      }

      // Save the video using StorageService which handles both Firebase and Hive
      await _storageService.saveVideo(videoContent);

      if (mounted) {
        String message;
        if (videoContent.subtitles.isNotEmpty) {
          message = 'Video added: ${videoContent.title}';
        } else if (videoContent.subtitleWarning != null) {
          message = 'Video added: ${videoContent.title} (Subtitles had issues but video is ready)';
        } else {
          message = 'Video added: ${videoContent.title} (No subtitles available)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      _logger.e('Error processing video', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add YouTube Video'), centerTitle: true),
      body:
          _isProcessing
              ? _buildLoadingState()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildForm(),
              ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // YouTube logo and title
          Center(
            child: Column(
              children: [
                Icon(Icons.play_circle_filled, color: Colors.red, size: 64),
                SizedBox(height: 8),
                Text(
                  'Add YouTube Video',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),

          // URL input field
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'YouTube URL',
              hintText: 'Paste a YouTube video URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
              helperText:
                  'Example: https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            ),
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a URL';
              }
              if (!YoutubeUtils.isYoutubeUrl(value)) {
                // Use the corrected utility method
                return 'Please enter a valid YouTube URL';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Manual subtitle picker
          _buildSubtitlePicker(),

          const SizedBox(height: 12),

          // Info message
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'YouTube videos will automatically fetch available transcripts for learning.',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Process button
          ElevatedButton.icon(
            onPressed: _processVideo,
            icon: const Icon(Icons.download),
            label: const Text('Process Video'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitlePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Manual Subtitle (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickSubtitleFile,
          icon: const Icon(Icons.subtitles),
          label: const Text('Select Subtitle File (.srt)'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_subtitleFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${_subtitleFile!.path.split('/').last}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _subtitleFile = null;
                    });
                  },
                )
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Processing video...', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text(
            'This may take a moment while we fetch transcripts',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
