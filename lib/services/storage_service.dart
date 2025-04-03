import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_content.dart';
import '../models/vocabulary_item.dart';

class StorageService {
  static const String _videosKey = 'saved_videos';
  static const String _vocabularyKey = 'saved_vocabulary';
  
  // Save a video to persistent storage
  Future<void> saveVideo(VideoContent video) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> videos = prefs.getStringList(_videosKey) ?? [];
    
    // Convert video to JSON string
    final videoJson = jsonEncode(video.toJson());
    
    // Check if video already exists (by ID) and update it, or add it as new
    final index = videos.indexWhere((v) {
      final Map<String, dynamic> decoded = jsonDecode(v);
      return decoded['id'] == video.id;
    });
    
    if (index >= 0) {
      videos[index] = videoJson;
    } else {
      videos.add(videoJson);
    }
    
    await prefs.setStringList(_videosKey, videos);
  }
  
  // Get all saved videos
  Future<List<VideoContent>> getVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> videos = prefs.getStringList(_videosKey) ?? [];
    
    final List<VideoContent> result = [];
    
    for (final videoJson in videos) {
      try {
        final Map<String, dynamic> json = jsonDecode(videoJson);
        result.add(VideoContent.fromJson(json));
      } catch (e) {
        // Skip invalid entries instead of failing the entire operation
        print('Error parsing video: $e');
      }
    }
    
    return result;
  }
  
  // Get a specific video by ID
  Future<VideoContent?> getVideoById(String id) async {
    final videos = await getVideos();
    try {
      return videos.firstWhere((v) => v.id == id);
    } catch (e) {
      return null; // Video not found
    }
  }
  
  // Delete a video
  Future<void> deleteVideo(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> videos = prefs.getStringList(_videosKey) ?? [];
    
    final newList = videos.where((v) {
      final Map<String, dynamic> decoded = jsonDecode(v);
      return decoded['id'] != id;
    }).toList();
    
    await prefs.setStringList(_videosKey, newList);
    
    // Also delete associated vocabulary items
    await deleteVocabularyByVideoId(id);
  }
  
  // Save a vocabulary item
  Future<void> saveVocabularyItem(VocabularyItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> vocabulary = prefs.getStringList(_vocabularyKey) ?? [];
    
    // Convert item to JSON string
    final itemJson = jsonEncode(item.toJson());
    
    // Check if item already exists (by ID) and update it, or add it as new
    final index = vocabulary.indexWhere((v) {
      final Map<String, dynamic> decoded = jsonDecode(v);
      return decoded['id'] == item.id;
    });
    
    if (index >= 0) {
      vocabulary[index] = itemJson;
    } else {
      vocabulary.add(itemJson);
    }
    
    await prefs.setStringList(_vocabularyKey, vocabulary);
  }
  
  // Get all vocabulary items
  Future<List<VocabularyItem>> getVocabularyItems() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> vocabulary = prefs.getStringList(_vocabularyKey) ?? [];
    
    return vocabulary.map((v) {
      final Map<String, dynamic> json = jsonDecode(v);
      return VocabularyItem.fromJson(json);
    }).toList();
  }
  
  // Get vocabulary items for a specific video
  Future<List<VocabularyItem>> getVocabularyByVideoId(String videoId) async {
    final items = await getVocabularyItems();
    return items.where((item) => item.sourceVideoId == videoId).toList();
  }
  
  // Delete a vocabulary item
  Future<void> deleteVocabularyItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> vocabulary = prefs.getStringList(_vocabularyKey) ?? [];
    
    final newList = vocabulary.where((v) {
      final Map<String, dynamic> decoded = jsonDecode(v);
      return decoded['id'] != id;
    }).toList();
    
    await prefs.setStringList(_vocabularyKey, newList);
  }
  
  // Delete all vocabulary items associated with a video
  Future<void> deleteVocabularyByVideoId(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> vocabulary = prefs.getStringList(_vocabularyKey) ?? [];
    
    final newList = vocabulary.where((v) {
      final Map<String, dynamic> decoded = jsonDecode(v);
      return decoded['sourceVideoId'] != videoId;
    }).toList();
    
    await prefs.setStringList(_vocabularyKey, newList);
  }
} 