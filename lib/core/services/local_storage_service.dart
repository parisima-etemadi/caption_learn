import 'base_service.dart';
import '../exceptions/app_exceptions.dart';
import '../../features/video/data/models/video_content.dart';
import '../../features/vocabulary/models/vocabulary_item.dart';
import '../../services/hive_service.dart';

/// Local-only storage service - handles offline data persistence
class LocalStorageService extends BaseService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  final HiveService _hive = HiveService();
  
  @override
  String get serviceName => 'LocalStorageService';
  
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();
  
  /// Initialize local storage
  Future<void> initialize() async {
    try {
      await _hive.openBoxes();
      logger.i('Local storage initialized');
    } catch (e) {
      logger.e('Failed to initialize local storage', e);
      throw StorageException('Failed to initialize local storage', originalError: e);
    }
  }
  
  // Video operations
  Future<void> saveVideo(VideoContent video) async {
    try {
      await _hive.saveVideo(video);
      logger.d('Video saved locally: ${video.id}');
    } catch (e) {
      logger.e('Failed to save video locally', e);
      throw StorageException('Failed to save video locally', originalError: e);
    }
  }
  
  Future<void> deleteVideo(String id) async {
    try {
      await _hive.deleteVideo(id);
      await _hive.deleteVocabularyByVideoId(id); // Clean up related data
      logger.d('Video deleted locally: $id');
    } catch (e) {
      logger.e('Failed to delete video locally', e);
      throw StorageException('Failed to delete video locally', originalError: e);
    }
  }
  
  List<VideoContent> getVideos() {
    try {
      return _hive.getVideos();
    } catch (e) {
      logger.e('Failed to get videos from local storage', e);
      return [];
    }
  }
  
  VideoContent? getVideoById(String id) {
    try {
      return _hive.getVideoById(id);
    } catch (e) {
      logger.e('Failed to get video by ID from local storage', e);
      return null;
    }
  }
  
  // Vocabulary operations
  Future<void> saveVocabulary(VocabularyItem item) async {
    try {
      await _hive.saveVocabularyItem(item);
      logger.d('Vocabulary saved locally: ${item.id}');
    } catch (e) {
      logger.e('Failed to save vocabulary locally', e);
      throw StorageException('Failed to save vocabulary locally', originalError: e);
    }
  }
  
  Future<void> deleteVocabulary(String id) async {
    try {
      await _hive.deleteVocabularyItem(id);
      logger.d('Vocabulary deleted locally: $id');
    } catch (e) {
      logger.e('Failed to delete vocabulary locally', e);
      throw StorageException('Failed to delete vocabulary locally', originalError: e);
    }
  }
  
  Future<void> deleteVocabularyByVideo(String videoId) async {
    try {
      await _hive.deleteVocabularyByVideoId(videoId);
      logger.d('Video vocabulary deleted locally: $videoId');
    } catch (e) {
      logger.e('Failed to delete video vocabulary locally', e);
      throw StorageException('Failed to delete video vocabulary locally', originalError: e);
    }
  }
  
  List<VocabularyItem> getVocabulary() {
    try {
      return _hive.getVocabularyItems();
    } catch (e) {
      logger.e('Failed to get vocabulary from local storage', e);
      return [];
    }
  }
  
  List<VocabularyItem> getVocabularyByVideo(String videoId) {
    try {
      return _hive.getVocabularyByVideoId(videoId);
    } catch (e) {
      logger.e('Failed to get vocabulary by video from local storage', e);
      return [];
    }
  }
  
  /// Clean up resources
  Future<void> dispose() async {
    try {
      await _hive.closeBoxes();
      logger.i('Local storage disposed');
    } catch (e) {
      logger.e('Error disposing local storage', e);
    }
  }
}