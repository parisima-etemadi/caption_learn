import 'package:flutter/material.dart';
import '../models/video_content.dart';
import '../services/storage_service.dart';
import 'add_video_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<VideoContent> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videos = await _storageService.getVideos();
      videos.sort((a, b) => b.dateAdded.compareTo(a.dateAdded)); // Sort by newest first

      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading videos: $e');
      if (mounted) {
        setState(() {
          _videos = [];
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading videos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caption Learn'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? _buildEmptyState()
              : _buildVideoList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVideoScreen()),
          );
          if (result == true) {
            _loadVideos();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No videos yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add videos to start learning',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddVideoScreen()),
              );
              if (result == true) {
                _loadVideos();
              }
            },
            child: const Text('Add Video'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    if (_videos.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      itemCount: _videos.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final video = _videos[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: _buildVideoThumbnail(video),
            title: Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _getVideoSourceLabel(video.source),
              style: TextStyle(color: _getColorForSource(video.source)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteVideo(video.id),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(videoId: video.id),
                ),
              );
              // Refresh in case anything changed
              _loadVideos();
            },
          ),
        );
      },
    );
  }

  Widget _buildVideoThumbnail(VideoContent video) {
    IconData iconData;
    Color color;

    switch (video.source) {
      case VideoSource.youtube:
        iconData = Icons.play_circle_filled;
        color = Colors.red;
        break;
      case VideoSource.tiktok:
        iconData = Icons.music_note;
        color = Colors.black;
        break;
      case VideoSource.instagram:
        iconData = Icons.camera_alt;
        color = Colors.purple;
        break;
      case VideoSource.local:
        iconData = Icons.folder;
        color = Colors.blue;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      radius: 28,
      child: Icon(
        iconData,
        color: color,
        size: 32,
      ),
    );
  }

  String _getVideoSourceLabel(VideoSource source) {
    switch (source) {
      case VideoSource.youtube:
        return 'YouTube';
      case VideoSource.tiktok:
        return 'TikTok';
      case VideoSource.instagram:
        return 'Instagram';
      case VideoSource.local:
        return 'Local Video';
    }
  }

  Color _getColorForSource(VideoSource source) {
    switch (source) {
      case VideoSource.youtube:
        return Colors.red;
      case VideoSource.tiktok:
        return Colors.black;
      case VideoSource.instagram:
        return Colors.purple;
      case VideoSource.local:
        return Colors.blue;
    }
  }

  Future<void> _deleteVideo(String id) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text(
          'Are you sure you want to delete this video? This will also delete all vocabulary items associated with it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await _storageService.deleteVideo(id);
      _loadVideos();
    }
  }
} 