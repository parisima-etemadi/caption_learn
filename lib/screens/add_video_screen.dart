import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/video_service.dart';
import '../services/storage_service.dart';

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
  final _imagePicker = ImagePicker();
  
  bool _isProcessing = false;
  bool _isUrlOption = true; // Toggle between URL and local file upload
  String? _localFilePath;
  String? _localFileName;
  final _localFileTitleController = TextEditingController();
  
  @override
  void dispose() {
    _urlController.dispose();
    _localFileTitleController.dispose();
    _videoService.dispose();
    super.dispose();
  }

  Future<void> _processUrlVideo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final url = _urlController.text.trim();
      final videoContent = await _videoService.processVideoUrl(url);
      await _storageService.saveVideo(videoContent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video added: ${videoContent.title}')),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  Future<void> _pickLocalVideo() async {
    try {
      final XFile? videoFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      
      if (videoFile != null) {
        setState(() {
          _localFilePath = videoFile.path;
          _localFileName = videoFile.name;
          _localFileTitleController.text = _localFileName ?? 'Local Video';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _processLocalVideo() async {
    if (_localFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video file')),
      );
      return;
    }
    
    if (_localFileTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for the video')),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final videoFile = File(_localFilePath!);
      final title = _localFileTitleController.text.trim();
      
      final videoContent = await _videoService.processLocalVideo(videoFile, title);
      await _storageService.saveVideo(videoContent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video added: $title')),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
      appBar: AppBar(
        title: const Text('Add Video'),
        centerTitle: true,
      ),
      body: _isProcessing 
          ? _buildLoadingState() 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSourceToggle(),
                  const SizedBox(height: 24),
                  _isUrlOption ? _buildUrlForm() : _buildLocalFileForm(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSourceToggle() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isUrlOption = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isUrlOption ? Theme.of(context).primaryColor : Colors.grey.shade300,
              foregroundColor: _isUrlOption ? Colors.white : Colors.black,
            ),
            child: const Text('Video URL'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isUrlOption = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: !_isUrlOption ? Theme.of(context).primaryColor : Colors.grey.shade300,
              foregroundColor: !_isUrlOption ? Colors.white : Colors.black,
            ),
            child: const Text('Local Video'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUrlForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Video URL',
              hintText: 'Paste YouTube or Instagram URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a URL';
              }
              
              final url = value.toLowerCase();
              if (!url.contains('youtube.com') && 
                  !url.contains('youtu.be') &&
                  !url.contains('instagram.com')) {
                return 'Only YouTube and Instagram URLs are supported';
              }
              
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'YouTube videos will automatically fetch available transcripts.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue[700]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _processUrlVideo,
            icon: const Icon(Icons.download),
            label: const Text('Process Video'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          _buildSupportedPlatforms(),
        ],
      ),
    );
  }
  
  Widget _buildLocalFileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _pickLocalVideo,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: _localFilePath != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_file, size: 48, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text(
                        _localFileName ?? 'Selected Video',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _pickLocalVideo,
                        child: const Text('Change'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.upload_file, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to select a video from gallery'),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _localFileTitleController,
          decoration: const InputDecoration(
            labelText: 'Video Title',
            hintText: 'Enter a title for this video',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _processLocalVideo,
          icon: const Icon(Icons.add),
          label: const Text('Add Local Video'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Note: For local videos, you\'ll need to provide your own subtitles manually.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }
  
  Widget _buildSupportedPlatforms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supported Platforms:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPlatformItem(Icons.play_circle_filled, 'YouTube', Colors.red),
            _buildPlatformItem(Icons.music_note, 'Instagram', Colors.purple),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPlatformItem(IconData icon, String name, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(name),
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Processing video...',
            style: TextStyle(fontSize: 18),
          ),
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