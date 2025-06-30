import '../core/services/base_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/sync_service.dart';
import '../features/video/data/models/video_content.dart';
import '../features/vocabulary/models/vocabulary_item.dart';

/// Unified storage service - coordinates local storage and cloud sync
class StorageService extends BaseService {
  static final StorageService _instance = StorageService._internal();
  final LocalStorageService _localStorage = LocalStorageService();
  final SyncService _syncService = SyncService();
  
  @override
  String get serviceName => 'StorageService';
  
  factory StorageService() => _instance;
  StorageService._internal();
  
  /// Initialize storage service and sync data if user is logged in
  Future<void> initialize() async {
    await _localStorage.initialize();
    
    if (_syncService.canSync) {
      try {
        await _syncService.syncFromCloud();
      } catch (e) {
        logger.w('Failed to sync from cloud during initialization: $e');
      }
    }
    
    logger.i('Storage service initialized');
  }
  
  // Video operations
  Future<void> saveVideo(VideoContent video) async {
    await _localStorage.saveVideo(video);
    await _syncService.syncVideoToCloud(video); // Non-blocking sync
  }
  
  Future<void> deleteVideo(String id) async {
    await _localStorage.deleteVideo(id);
    await _syncService.deleteVideoFromCloud(id); // Non-blocking sync
  }
  
  List<VideoContent> getVideos() => _localStorage.getVideos();
  VideoContent? getVideoById(String id) => _localStorage.getVideoById(id);
  
  // Vocabulary operations
  Future<void> saveVocabulary(VocabularyItem item) async {
    await _localStorage.saveVocabulary(item);
    await _syncService.syncVocabularyToCloud(item); // Non-blocking sync
  }
  
  Future<void> saveVocabularyItem(VocabularyItem item) async {
    await saveVocabulary(item); // Alias for backward compatibility
  }
  
  Future<void> deleteVocabulary(String id) async {
    await _localStorage.deleteVocabulary(id);
    await _syncService.deleteVocabularyFromCloud(id); // Non-blocking sync
  }
  
  Future<void> deleteVocabularyByVideo(String videoId) async {
    await _localStorage.deleteVocabularyByVideo(videoId);
    // Cloud cleanup is handled in deleteVideo
  }
  
  List<VocabularyItem> getVocabulary() => _localStorage.getVocabulary();
  List<VocabularyItem> getVocabularyByVideo(String videoId) => _localStorage.getVocabularyByVideo(videoId);
  
  // Sync operations
  Future<void> syncFromCloud() => _syncService.syncFromCloud();
  Future<void> syncAllToCloud() => _syncService.syncAllToCloud();
  bool get canSync => _syncService.canSync;
  
  /// Dispose resources
  Future<void> dispose() async {
    await _localStorage.dispose();
    logger.i('Storage service disposed');
  }
}