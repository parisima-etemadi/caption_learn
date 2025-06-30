import 'dart:async';
import 'base_service.dart';
import '../exceptions/app_exceptions.dart';
import '../../features/video/data/models/video_content.dart';
import '../../features/vocabulary/models/vocabulary_item.dart';
import '../../services/firebase_service.dart';
import 'local_storage_service.dart';

/// Cloud synchronization service - handles data sync between local and remote storage
class SyncService extends BaseService {
  static final SyncService _instance = SyncService._internal();
  final FirebaseService _firebase = FirebaseService();
  final LocalStorageService _localStorage = LocalStorageService();
  
  @override
  String get serviceName => 'SyncService';
  
  factory SyncService() => _instance;
  SyncService._internal();
  
  /// Check if sync is available (user logged in)
  bool get canSync => _firebase.isUserLoggedIn;
  
  /// Sync all data from cloud to local storage
  Future<void> syncFromCloud() async {
    if (!canSync) {
      logger.w('Cannot sync: User not logged in');
      return;
    }
    
    try {
      logger.i('Starting sync from cloud to local');
      
      // Sync videos
      final cloudVideos = await _firebase.getVideos();
      for (final video in cloudVideos) {
        await _localStorage.saveVideo(video);
      }
      
      // Sync vocabulary
      final cloudVocabulary = await _firebase.getVocabularyItems();
      for (final item in cloudVocabulary) {
        await _localStorage.saveVocabulary(item);
      }
      
      logger.i('Successfully synced ${cloudVideos.length} videos and ${cloudVocabulary.length} vocabulary items from cloud');
    } catch (e) {
      logger.e('Failed to sync from cloud', e);
      throw NetworkException('Failed to sync from cloud', originalError: e);
    }
  }
  
  /// Sync video to cloud (if possible)
  Future<void> syncVideoToCloud(VideoContent video) async {
    if (!canSync) {
      logger.d('Skipping cloud sync - user not logged in');
      return;
    }
    
    try {
      await _firebase.saveVideo(video);
      logger.d('Video synced to cloud: ${video.id}');
    } catch (e) {
      logger.w('Failed to sync video to cloud: ${e.toString()}');
      // Don't throw - this is optional sync
    }
  }
  
  /// Sync vocabulary to cloud (if possible)
  Future<void> syncVocabularyToCloud(VocabularyItem item) async {
    if (!canSync) {
      logger.d('Skipping cloud sync - user not logged in');
      return;
    }
    
    try {
      await _firebase.saveVocabularyItem(item);
      logger.d('Vocabulary synced to cloud: ${item.id}');
    } catch (e) {
      logger.w('Failed to sync vocabulary to cloud: ${e.toString()}');
      // Don't throw - this is optional sync
    }
  }
  
  /// Delete video from cloud (if possible)
  Future<void> deleteVideoFromCloud(String id) async {
    if (!canSync) {
      logger.d('Skipping cloud delete - user not logged in');
      return;
    }
    
    try {
      await _firebase.deleteVideo(id);
      await _firebase.deleteVocabularyByVideoId(id);
      logger.d('Video deleted from cloud: $id');
    } catch (e) {
      logger.w('Failed to delete video from cloud: ${e.toString()}');
      // Don't throw - this is optional sync
    }
  }
  
  /// Delete vocabulary from cloud (if possible)
  Future<void> deleteVocabularyFromCloud(String id) async {
    if (!canSync) {
      logger.d('Skipping cloud delete - user not logged in');
      return;
    }
    
    try {
      await _firebase.deleteVocabularyItem(id);
      logger.d('Vocabulary deleted from cloud: $id');
    } catch (e) {
      logger.w('Failed to delete vocabulary from cloud: ${e.toString()}');
      // Don't throw - this is optional sync
    }
  }
  
  /// Force sync all local data to cloud
  Future<void> syncAllToCloud() async {
    if (!canSync) {
      throw const NetworkException('Cannot sync: User not logged in');
    }
    
    try {
      logger.i('Starting full sync to cloud');
      
      // Sync all videos
      final localVideos = _localStorage.getVideos();
      for (final video in localVideos) {
        await _firebase.saveVideo(video);
      }
      
      // Sync all vocabulary
      final localVocabulary = _localStorage.getVocabulary();
      for (final item in localVocabulary) {
        await _firebase.saveVocabularyItem(item);
      }
      
      logger.i('Successfully synced ${localVideos.length} videos and ${localVocabulary.length} vocabulary items to cloud');
    } catch (e) {
      logger.e('Failed to sync all data to cloud', e);
      throw NetworkException('Failed to sync all data to cloud', originalError: e);
    }
  }
}