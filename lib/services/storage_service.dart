import 'dart:convert';
import 'package:caption_learn/features/video/data/models/video_content.dart';
import 'package:caption_learn/features/vocabulary/models/vocabulary_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';


class StorageService {
  static final StorageService _instance = StorageService._internal();
  final Logger _logger = const Logger('StorageService');
  
  factory StorageService() {
    return _instance;
  }
  
  StorageService._internal();
  
  // Videos
  Future<void> saveVideo(VideoContent video) async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
  
  Future<List<VideoContent>> getVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> videos = prefs.getStringList(AppConstants.videosStorageKey) ?? [];
      
      final List<VideoContent> result = [];
      
      for (final videoJson in videos) {
        try {
          final Map<String, dynamic> json = jsonDecode(videoJson);
          result.add(VideoContent.fromJson(json));
        } catch (e) {
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
  
  Future<VideoContent?> getVideoById(String id) async {
    try {
      final videos = await getVideos();
      final video = videos.firstWhere((v) => v.id == id, orElse: () => throw Exception('Video not found'));
      _logger.d('Retrieved video with ID: $id');
      return video;
    } catch (e) {
      _logger.w('Video with ID $id not found');
      return null;
    }
  }
  
  Future<void> deleteVideo(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> videos = prefs.getStringList(AppConstants.videosStorageKey) ?? [];
      
      final newList = videos.where((v) {
        final Map<String, dynamic> decoded = jsonDecode(v);
        return decoded['id'] != id;
      }).toList();
      
      await prefs.setStringList(AppConstants.videosStorageKey, newList);
      _logger.i('Deleted video with ID: $id');
      
      // Also delete associated vocabulary items
      await deleteVocabularyByVideoId(id);
    } catch (e, stackTrace) {
      _logger.e('Failed to delete video', e, stackTrace);
      rethrow;
    }
  }
  
  // Vocabulary
  Future<void> saveVocabularyItem(VocabularyItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
  
  Future<List<VocabularyItem>> getVocabularyItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
  
  Future<void> deleteVocabularyItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
  
  Future<void> deleteVocabularyByVideoId(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
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