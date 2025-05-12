import 'package:caption_learn/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:caption_learn/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../video/data/models/video_content.dart';
import '../../../video/domain/enum/video_source.dart';
import '../../../video/presentation/screens/add_video_screen.dart';
import '../../../video/presentation/screens/video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _logger = const Logger('HomeScreen');
  final StorageService _storageService = StorageService();
  
  List<VideoContent> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get videos from StorageService (which manages both local and remote storage)
      final videos = _storageService.getVideos();
      
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Delete video using StorageService
        await _storageService.deleteVideo(id);
        
        // Reload videos
        await _loadVideos();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _logger.e('Error deleting video', e);
        _showErrorSnackbar('Error deleting video');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmSignOut == true) {
      context.read<AuthBloc>().add(SignOutRequested());
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddVideo,
        tooltip: 'Add YouTube Video',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_videos.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildVideoList();
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
      // When coming back from add screen, refresh the videos
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
            'Add YouTube videos to start learning',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddVideo,
            icon: const Icon(Icons.add),
            label: const Text('Add YouTube Video'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
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
        leading: _buildYouTubeThumbnail(),
        title: Text(
          video.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'YouTube',
          style: TextStyle(color: Colors.red),
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

  Widget _buildYouTubeThumbnail() {
    return const CircleAvatar(
      backgroundColor: Color(0xFFFFEEEE), // Light red background
      radius: 28,
      child: Icon(
        Icons.play_circle_filled,
        color: Colors.red,
        size: 32,
      ),
    );
  }
}