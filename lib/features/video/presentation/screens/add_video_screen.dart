// lib/features/video/presentation/screens/add_video_screen.dart
import 'dart:io';
import 'package:caption_learn/core/widgets/loading_overlay.dart';
import 'package:caption_learn/features/video/domain/enum/video_source.dart';
import 'package:caption_learn/features/video/domain/services/video_processor.dart' hide VideoSource;
import 'package:caption_learn/features/video/presentation/widgets/file_selector.dart';
import 'package:caption_learn/features/video/presentation/widgets/video_url_input.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';


class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final _processor = VideoProcessor();
  final _urlController = TextEditingController();
  
  bool _isProcessing = false;
  File? _subtitleFile;
  File? _videoFile;
  VideoSource _source = VideoSource.youtube;

  @override
  void dispose() {
    _urlController.dispose();
    _processor.dispose();
    super.dispose();
  }

  Future<void> _processVideo() async {
    if (!_validate()) return;

    setState(() => _isProcessing = true);
    
    try {
      await _processor.process(
        source: _source,
        url: _urlController.text.trim(),
        videoFile: _videoFile,
        subtitleFile: _subtitleFile,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  bool _validate() {
    if (_source == VideoSource.youtube && _urlController.text.isEmpty) {
      _showError('Please enter a YouTube URL');
      return false;
    }
    if (_source == VideoSource.local && _videoFile == null) {
      _showError('Please select a video file');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Video'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildSourceToggle(),
        ),
      ),
      body: _isProcessing 
        ? const LoadingIndicator(message: 'Processing video...')
        : _buildForm(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _processVideo,
        icon: const Icon(Icons.add),
        label: const Text('Add Video'),
      ),
    );
  }

  Widget _buildSourceToggle() {
    return ToggleButtons(
      isSelected: [
        _source == VideoSource.youtube,
        _source == VideoSource.local,
      ],
      onPressed: (index) {
        setState(() {
          _source = index == 0 ? VideoSource.youtube : VideoSource.local;
        });
      },
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('YouTube'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('Local File'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_source == VideoSource.youtube)
            VideoUrlInput(controller: _urlController)
          else
            FileSelector(
              label: 'Video File',
              file: _videoFile,
              onSelected: (file) => setState(() => _videoFile = file),
              extensions: ['mp4', 'mov', 'avi', 'mkv'],
            ),
          const SizedBox(height: 16),
          FileSelector(
            label: 'Subtitle File (Optional)',
            file: _subtitleFile,
            onSelected: (file) => setState(() => _subtitleFile = file),
            extensions: ['srt', 'vtt'],
          ),
        ],
      ),
    );
  }
}