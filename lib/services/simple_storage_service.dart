import '../core/services/base_service.dart';
import '../features/video/data/models/video_content.dart';
import '../features/vocabulary/models/vocabulary_item.dart';
import 'firebase_service.dart';
import 'hive_service.dart';

/// Simplified storage service - handles local and remote storage
class SimpleStorageService extends BaseService {
  static final SimpleStorageService _instance = SimpleStorageService._internal();
  final _firebase = FirebaseService();
  final _hive = HiveService();
  
  @override
  String get serviceName => 'SimpleStorageService';
  
  factory SimpleStorageService() => _instance;
  SimpleStorageService._internal();
  
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
    try {
      if (_firebase.isUserLoggedIn) await _firebase.deleteVideo(id);
    } catch (e) {
      logger.w('Failed to delete video from cloud: $e');
    }
  }
  
  Future<List<VideoContent>> getVideos() async => _hive.getVideos();
  
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
  
  Future<List<VocabularyItem>> getVocabulary() async => _hive.getVocabularyItems();
  Future<List<VocabularyItem>> getVocabularyByVideo(String videoId) async => _hive.getVocabularyByVideoId(videoId);
}