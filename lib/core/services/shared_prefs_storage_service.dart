import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/video_management/models/video_content.dart';
import '../../features/vocabulary/models/vocabulary_item.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';
import 'storage_repository.dart';

/// Implementation of video storage repository using SharedPreferences
class VideoStorage implements VideoStorageRepository {
  final Logger _logger = const Logger('VideoStorage');
  
  // For easier testing and dependency injection
  Future<SharedPreferences> _getPreferences() async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<void> save(VideoContent video) async {
    try {
      await saveVideo(video);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<VideoContent?> getById(String id) async {
    try {
      return await getVideoById(id);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<List<VideoContent>> getAll() async {
    try {
      return await getVideos();
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await deleteVideo(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveVideo(VideoContent video) async {
    try {
      final prefs = await _getPreferences();
      final List<String> videos = prefs.getStringList(AppConstants.videosStorageKey) ?? [];
      
      // Convert video to JSON string
      final videoJson = jsonEncode(video.toJson());
      
      // Check if video already exists (by ID) and update it, or add it as new
      final index = videos.indexWhere((v) {
        final Map<String, dynamic> decoded = jsonDecode(v);
        return decoded['id'] == video.id;
      });
      
      if (index >= 0) {
        videos[index] = videoJson;
        _logger.i('Updated video with ID: ${video.id}');
      } else {
        videos.add(videoJson);
        _logger.i('Added new video with ID: ${video.id}');
      }
      
      await prefs.setStringList(AppConstants.videosStorageKey, videos);
    } catch (e, stackTrace) {
      _logger.e('Failed to save video', e, stackTrace);
      rethrow;
    }
  }
  
  @override
  Future<List<VideoContent>> getVideos() async {
    try {
      final prefs = await _getPreferences();
      final List<String> videos = prefs.getStringList(AppConstants.videosStorageKey) ?? [];
      
      final List<VideoContent> result = [];
      
      for (final videoJson in videos) {
        try {
          final Map<String, dynamic> json = jsonDecode(videoJson);
          // Verify that the required fields exist in the parsed JSON
          if (json.containsKey('id') && json.containsKey('title') && 
              json.containsKey('sourceUrl') && json.containsKey('source') &&
              json.containsKey('subtitles') && json.containsKey('dateAdded')) {
            // Check if subtitles is a list
            if (json['subtitles'] is List) {
              result.add(VideoContent.fromJson(json));
            } else {
              _logger.w('Error parsing video: subtitles is not a list');
            }
          } else {
            _logger.w('Error parsing video: Missing required fields in JSON');
          }
        } catch (e) {
          // Skip invalid entries instead of failing the entire operation
          _logger.e('Error parsing video', e);
        }
      }
      
      _logger.d('Retrieved ${result.length} videos');
      return result;
    } catch (e, stackTrace) {
      _logger.e('Failed to get videos', e, stackTrace);
      rethrow;
    }
  }
  
  @override
  Future<VideoContent?> getVideoById(String id) async {
    try {
      final videos = await getVideos();
      final video = videos.firstWhere((v) => v.id == id, orElse: () => throw Exception('Video not found'));
      _logger.d('Retrieved video with ID: $id');
      return video;
    } catch (e) {
      _logger.w('Video with ID $id not found');
      return null; // Video not found
    }
  }
  
  @override
  Future<void> deleteVideo(String id) async {
    try {
      final prefs = await _getPreferences();
      final List<String> videos = prefs.getStringList(AppConstants.videosStorageKey) ?? [];
      
      final newList = videos.where((v) {
        final Map<String, dynamic> decoded = jsonDecode(v);
        return decoded['id'] != id;
      }).toList();
      
      await prefs.setStringList(AppConstants.videosStorageKey, newList);
      _logger.i('Deleted video with ID: $id');
      
      // Also delete associated vocabulary items
      VocabularyStorage().deleteVocabularyByVideoId(id);
    } catch (e, stackTrace) {
      _logger.e('Failed to delete video', e, stackTrace);
      rethrow;
    }
  }
}

/// Implementation of vocabulary storage repository using SharedPreferences
class VocabularyStorage implements VocabularyStorageRepository {
  final Logger _logger = const Logger('VocabularyStorage');
  
  // For easier testing and dependency injection
  Future<SharedPreferences> _getPreferences() async {
    return await SharedPreferences.getInstance();
  }
  
  @override
  Future<void> save(VocabularyItem item) async {
    try {
      await saveVocabularyItem(item);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<List<VocabularyItem>> getAll() async {
    try {
      return await getVocabularyItems();
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<VocabularyItem?> getById(String id) async {
    try {
      final items = await getVocabularyItems();
      return items.firstWhere((item) => item.id == id, orElse: () => throw Exception('Vocabulary item not found'));
    } catch (e) {
      _logger.w('Vocabulary item with ID $id not found');
      return null;
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await deleteVocabularyItem(id);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<void> saveVocabularyItem(VocabularyItem item) async {
    try {
      final prefs = await _getPreferences();
      final List<String> vocabulary = prefs.getStringList(AppConstants.vocabularyStorageKey) ?? [];
      
      // Convert item to JSON string
      final itemJson = jsonEncode(item.toJson());
      
      // Check if item already exists (by ID) and update it, or add it as new
      final index = vocabulary.indexWhere((v) {
        final Map<String, dynamic> decoded = jsonDecode(v);
        return decoded['id'] == item.id;
      });
      
      if (index >= 0) {
        vocabulary[index] = itemJson;
        _logger.i('Updated vocabulary item with ID: ${item.id}');
      } else {
        vocabulary.add(itemJson);
        _logger.i('Added new vocabulary item with ID: ${item.id}');
      }
      
      await prefs.setStringList(AppConstants.vocabularyStorageKey, vocabulary);
    } catch (e, stackTrace) {
      _logger.e('Failed to save vocabulary item', e, stackTrace);
      rethrow;
    }
  }
  
  @override
  Future<List<VocabularyItem>> getVocabularyItems() async {
    try {
      final prefs = await _getPreferences();
      final List<String> vocabulary = prefs.getStringList(AppConstants.vocabularyStorageKey) ?? [];
      
      final List<VocabularyItem> result = [];
      
      for (final itemJson in vocabulary) {
        try {
          final Map<String, dynamic> json = jsonDecode(itemJson);
          result.add(VocabularyItem.fromJson(json));
        } catch (e) {
          _logger.e('Error parsing vocabulary item', e);
        }
      }
      
      _logger.d('Retrieved ${result.length} vocabulary items');
      return result;
    } catch (e, stackTrace) {
      _logger.e('Failed to get vocabulary items', e, stackTrace);
      rethrow;
    }
  }
  
  @override
  Future<List<VocabularyItem>> getVocabularyByVideoId(String videoId) async {
    try {
      final items = await getVocabularyItems();
      final filteredItems = items.where((item) => item.sourceVideoId == videoId).toList();
      _logger.d('Retrieved ${filteredItems.length} vocabulary items for video: $videoId');
      return filteredItems;
    } catch (e, stackTrace) {
      _logger.e('Failed to get vocabulary items by video ID', e, stackTrace);
      rethrow;
    }
  }
  
  @override
  Future<void> deleteVocabularyItem(String id) async {
    try {
      final prefs = await _getPreferences();
      final List<String> vocabulary = prefs.getStringList(AppConstants.vocabularyStorageKey) ?? [];
      
      final newList = vocabulary.where((v) {
        final Map<String, dynamic> decoded = jsonDecode(v);
        return decoded['id'] != id;
      }).toList();
      
      await prefs.setStringList(AppConstants.vocabularyStorageKey, newList);
      _logger.i('Deleted vocabulary item with ID: $id');
    } catch (e, stackTrace) {
      _logger.e('Failed to delete vocabulary item', e, stackTrace);
      rethrow;
    }
  }
  
  @override
  Future<void> deleteVocabularyByVideoId(String videoId) async {
    try {
      final prefs = await _getPreferences();
      final List<String> vocabulary = prefs.getStringList(AppConstants.vocabularyStorageKey) ?? [];
      
      final List<String> originalList = List.from(vocabulary);
      final newList = vocabulary.where((v) {
        final Map<String, dynamic> decoded = jsonDecode(v);
        return decoded['sourceVideoId'] != videoId;
      }).toList();
      
      await prefs.setStringList(AppConstants.vocabularyStorageKey, newList);
      
      final int deletedCount = originalList.length - newList.length;
      _logger.i('Deleted $deletedCount vocabulary items for video: $videoId');
    } catch (e, stackTrace) {
      _logger.e('Failed to delete vocabulary items by video ID', e, stackTrace);
      rethrow;
    }
  }
} 