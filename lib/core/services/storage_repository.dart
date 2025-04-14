import '../../features/video_management/models/video_content.dart';
import '../../features/vocabulary/models/vocabulary_item.dart';

/// Interface for generic storage operations
abstract class BaseRepository<T> {
  Future<void> save(T item);
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<void> delete(String id);
}

/// Interface for video storage operations
abstract class VideoStorageRepository extends BaseRepository<VideoContent> {
  @override
  Future<void> save(VideoContent video);
  
  @override
  Future<VideoContent?> getById(String id);
  
  @override
  Future<List<VideoContent>> getAll();
  
  @override
  Future<void> delete(String id);
  
  Future<List<VideoContent>> getVideos();
  Future<VideoContent?> getVideoById(String id);
}

/// Interface for vocabulary storage operations
abstract class VocabularyStorageRepository extends BaseRepository<VocabularyItem> {
  @override
  Future<void> save(VocabularyItem item);
  
  @override
  Future<VocabularyItem?> getById(String id);
  
  @override
  Future<List<VocabularyItem>> getAll();
  
  @override
  Future<void> delete(String id);
  
  Future<List<VocabularyItem>> getVocabularyItems();
  Future<List<VocabularyItem>> getVocabularyByVideoId(String videoId);
  Future<void> deleteVocabularyByVideoId(String videoId);
} 