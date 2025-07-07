// lib/features/video/presentation/screens/add_video_screen.dart
import 'dart:io';

import 'package:caption_learn/services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../video/domain/services/video_service.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../data/models/video_content.dart';
import '../../domain/enum/video_source.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  _AddVideoScreenState createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _videoService = VideoService();
  final _storageService = StorageService();
  final _logger = Logger('AddVideoScreen');

  bool _isProcessing = false;
  File? _subtitleFile;
  File? _videoFile;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _videoService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(Function(File) onFilePicked,
      {required List<String> allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null) {
      setState(() {
        onFilePicked(File(result.files.single.path!));
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
      final isYouTube = _tabController.index == 0;
      final url = _urlController.text.trim();
      String? subtitleContent;

      if (_subtitleFile != null) {
        subtitleContent = await _subtitleFile!.readAsString();
      }

      VideoContent videoContent;

      if (isYouTube) {
        if (!YoutubeUtils.isYoutubeUrl(url)) {
          throw const VideoException('Please enter a valid YouTube URL');
        }
        videoContent = await _videoService.processVideoUrl(
          url,
          manualSubtitleContent: subtitleContent,
        );
      } else {
        if (_videoFile == null) {
          throw const VideoException('Please select a local video file');
        }
        // This is a placeholder; we will implement this service logic next.
        // For now, let's create a basic VideoContent object.
        videoContent = VideoContent(
          id: _videoFile!.path,
          title: _videoFile!.path.split('/').last,
          sourceUrl: _videoFile!.path,
          source: VideoSource.local,
          localPath: _videoFile!.path,
          subtitles: subtitleContent != null
              ? await _videoService.parseSubtitles(subtitleContent)
              : [],
          dateAdded: DateTime.now(),
        );
      }

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
    } on NetworkException catch (e) {
      _logger.e('Network error processing video', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } on VideoException catch (e) {
      _logger.e('Video processing error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _logger.e('An unexpected error occurred', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Video'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.link), text: 'From YouTube'),
            Tab(icon: Icon(Icons.folder), text: 'From Device'),
          ],
        ),
      ),
      body: _isProcessing
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildYouTubeTab(),
                _buildLocalFileTab(),
              ],
            ),
    );
  }

  Widget _buildYouTubeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'YouTube URL',
                hintText: 'Paste a YouTube video URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (_tabController.index == 0 && (value == null || value.isEmpty)) {
                  return 'Please enter a URL';
                }
                if (_tabController.index == 0 && !YoutubeUtils.isYoutubeUrl(value!)) {
                  return 'Please enter a valid YouTube URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildSubtitlePicker(isYouTube: true),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _processVideo,
              icon: const Icon(Icons.download),
              label: const Text('Process Video'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalFileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        // The form key might need to be different if validators are different
        // but for now we can share it.
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilePicker(
              title: 'Video File',
              file: _videoFile,
              icon: Icons.movie,
              onPressed: () => _pickFile(
                (file) => _videoFile = file,
                allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
              ),
            ),
            const SizedBox(height: 20),
            _buildSubtitlePicker(isYouTube: false),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _processVideo,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Local Video'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitlePicker({required bool isYouTube}) {
    return _buildFilePicker(
      title: 'Subtitle File (Optional)',
      file: _subtitleFile,
      icon: Icons.subtitles,
      onPressed: () => _pickFile(
        (file) => _subtitleFile = file,
        allowedExtensions: ['srt'],
      ),
    );
  }

  Widget _buildFilePicker({
    required String title,
    required File? file,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text('Select File...'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${file.path.split('/').last}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      if (title.contains('Video')) {
                        _videoFile = null;
                      } else {
                        _subtitleFile = null;
                      }
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
