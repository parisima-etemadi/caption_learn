import '../core/services/base_service.dart';
import '../features/video/data/models/video_content.dart';
import '../features/vocabulary/models/vocabulary_item.dart';
import 'firebase_service.dart';
import 'hive_service.dart';

/// Primary storage service - handles local and remote storage with sync
class StorageService extends BaseService {
  static final StorageService _instance = StorageService._internal();
  final _firebase = FirebaseService();
  final _hive = HiveService();
  
  @override
  String get serviceName => 'StorageService';
  
  factory StorageService() => _instance;
  StorageService._internal();
  
  /// Initialize storage service and sync data if user is logged in
  Future<void> initialize() async {
    await _hive.openBoxes();
    if (_firebase.isUserLoggedIn) {
      try {
        await syncFromCloud();
      } catch (e) {
        logger.w('Failed to sync from cloud during initialization: $e');
      }
    }
  }
  
  /// Sync data from cloud to local storage
  Future<void> syncFromCloud() async {
    if (!_firebase.isUserLoggedIn) return;
    
    try {
      final videos = await _firebase.getVideos();
      for (final video in videos) {
        await _hive.saveVideo(video);
      }
      
      final vocabulary = await _firebase.getVocabularyItems();
      for (final item in vocabulary) {
        await _hive.saveVocabularyItem(item);
      }
      
      logger.i('Successfully synced data from cloud');
    } catch (e) {
      logger.e('Failed to sync from cloud: $e');
      rethrow;
    }
  }
  
  // Video operations
  Future<void> saveVideo(VideoContent video) async {
    await _hive.saveVideo(video);
    try {
      if (_firebase.isUserLoggedIn) await _firebase.saveVideo(video);
    } catch (e) {
      logger.w('Failed to sync video to cloud: $e');
    }
  }
  
  Future<void> deleteVideo(String id) async {
    await _hive.deleteVideo(id);
    await deleteVocabularyByVideo(id); // Also delete related vocabulary
    try {
      if (_firebase.isUserLoggedIn) {
        await _firebase.deleteVideo(id);
        await _firebase.deleteVocabularyByVideoId(id);
      }
    } catch (e) {
      logger.w('Failed to delete video from cloud: $e');
    }
  }
  
  List<VideoContent> getVideos() => _hive.getVideos();
  VideoContent? getVideoById(String id) => _hive.getVideoById(id);
  
  // Vocabulary operations
  Future<void> saveVocabulary(VocabularyItem item) async {
    await _hive.saveVocabularyItem(item);
    try {
      if (_firebase.isUserLoggedIn) await _firebase.saveVocabularyItem(item);
    } catch (e) {
      logger.w('Failed to sync vocabulary to cloud: $e');
    }
  }
  
  Future<void> deleteVocabulary(String id) async {
    await _hive.deleteVocabularyItem(id);
    try {
      if (_firebase.isUserLoggedIn) await _firebase.deleteVocabularyItem(id);
    } catch (e) {
      logger.w('Failed to delete vocabulary from cloud: $e');
    }
  }
  
  Future<void> deleteVocabularyByVideo(String videoId) async {
    await _hive.deleteVocabularyByVideoId(videoId);
    try {
      if (_firebase.isUserLoggedIn) await _firebase.deleteVocabularyByVideoId(videoId);
    } catch (e) {
      logger.w('Failed to delete video vocabulary from cloud: $e');
    }
  }
  
  List<VocabularyItem> getVocabulary() => _hive.getVocabularyItems();
  List<VocabularyItem> getVocabularyByVideo(String videoId) => _hive.getVocabularyByVideoId(videoId);
  
  /// Dispose resources
  Future<void> dispose() async {
    await _hive.closeBoxes();
  }
}