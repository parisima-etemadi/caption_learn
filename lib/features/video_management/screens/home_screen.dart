import 'package:caption_learn/screens/add_video_screen.dart';
import 'package:caption_learn/screens/settings_screen.dart';
import 'package:caption_learn/screens/video_player/video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_repository.dart';
import '../../../core/utils/logger.dart';
import '../models/video_content.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _logger = const Logger('HomeScreen');
  late final VideoStorageRepository _videoRepository;
  List<VideoContent> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _videoRepository = Provider.of<VideoStorageRepository>(context, listen: false);
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final videos = await _videoRepository.getVideos();
      videos.sort((a, b) => b.dateAdded.compareTo(a.dateAdded)); // Sort by newest first

      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading videos', e);
      
      if (mounted) {
        setState(() {
          _videos = [];
          _isLoading = false;
        });
        
        _showErrorSnackbar('Error loading videos');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _videoRepository.delete(id);
        await _loadVideos();
      } catch (e) {
        _logger.e('Error deleting video', e);
        _showErrorSnackbar('Error deleting video');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? _buildEmptyState()
              : _buildVideoList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddVideo,
        tooltip: 'Add Video',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _navigateToAddVideo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVideoScreen()),
    );
    if (result == true) {
      _loadVideos();
    }
  }

  Future<void> _navigateToVideoPlayer(String videoId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoId: videoId),
      ),
    );
    // Refresh in case anything changed
    _loadVideos();
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
            onPressed: _navigateToAddVideo,
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
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      itemBuilder: (context, index) => _buildVideoItem(_videos[index]),
    );
  }

  Widget _buildVideoItem(VideoContent video) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
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
          tooltip: 'Delete Video',
        ),
        onTap: () => _navigateToVideoPlayer(video.id),
      ),
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
      case VideoSource.instagram:
        return Colors.purple;
      case VideoSource.local:
        return Colors.blue;
    }
  }
} 