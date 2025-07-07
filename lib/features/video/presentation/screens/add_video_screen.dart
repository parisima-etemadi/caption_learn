import 'dart:io';
import 'dart:async'; // Add this import
import 'package:caption_learn/core/widgets/loading_overlay.dart';
import 'package:caption_learn/features/video/domain/enum/video_source.dart';
import 'package:caption_learn/features/video/domain/services/video_processor.dart' hide VideoSource;
import 'package:caption_learn/features/video/presentation/widgets/file_selector.dart';
import 'package:caption_learn/features/video/presentation/widgets/video_url_input.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/utils/logger.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final _processor = VideoProcessor();
  final _urlController = TextEditingController();
  final Logger _logger = const Logger('AddVideoScreen');
  
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
      _logger.i('Starting video processing...');
      _logger.i('Source: $_source');
      _logger.i('URL: ${_urlController.text}');
      _logger.i('Video file: ${_videoFile?.path}');
      _logger.i('Subtitle file: ${_subtitleFile?.path}');
      
      // Add timeout to prevent infinite waiting
      await _processor.process(
        source: _source,
        url: _urlController.text.trim(),
        videoFile: _videoFile,
        subtitleFile: _subtitleFile,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Video processing took too long');
        },
      );
      
      _logger.i('Video processing completed successfully');
      
      if (mounted) {
        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Force navigation back
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    } catch (e) {
      _logger.e('Video processing failed', e);
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError(e is TimeoutException 
          ? 'Processing timed out. Please try again.' 
          : 'Error: ${e.toString()}');
      }
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
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
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
      body: LoadingOverlay(
        isLoading: _isProcessing,
        message: 'Processing video...',
        child: _buildForm(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _processVideo,
        icon: const Icon(Icons.add),
        label: const Text('Add Video'),
      ),
    );
  }

  Widget _buildSourceToggle() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ToggleButtons(
        isSelected: [
          _source == VideoSource.youtube,
          _source == VideoSource.local,
        ],
        onPressed: _isProcessing ? null : (index) {
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
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
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