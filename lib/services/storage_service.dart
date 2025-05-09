import 'dart:convert';
import 'package:caption_learn/features/video/data/models/video_content.dart';
import 'package:caption_learn/features/vocabulary/models/vocabulary_item.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

// Interface for items that can be stored and have an ID.
abstract class Storable {
  String get id;
  Map<String, dynamic> toJson(); // Keep for now, might be used elsewhere
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  final Logger _logger = const Logger('StorageService');

  // In-memory stores
  final List<VideoContent> _videos = [];
  final List<VocabularyItem> _vocabularyItems = [];

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  // Generic helper to save an item (add or update)
  void _saveItem<T extends Storable>(List<T> list, T item, String itemType) {
    final index = list.indexWhere((existingItem) => existingItem.id == item.id);
    if (index >= 0) {
      list[index] = item;
      _logger.i('Updated $itemType with ID: ${item.id}');
    } else {
      list.add(item);
      _logger.i('Added new $itemType with ID: ${item.id}');
    }
  }

  // Generic helper to get all items
  List<T> _getItems<T extends Storable>(List<T> list, String itemType) {
    _logger.d('Retrieved ${list.length} $itemType(s)');
    return List<T>.from(list); // Return a copy
  }

  // Generic helper to get an item by ID
  T? _getItemById<T extends Storable>(
    List<T> list,
    String id,
    String itemType,
  ) {
    try {
      final item = list.firstWhere((existingItem) => existingItem.id == id);
      _logger.d('Retrieved $itemType with ID: $id');
      return item;
    } catch (e) {
      _logger.w('$itemType with ID $id not found');
      return null;
    }
  }

  // Generic helper to delete an item by ID
  void _deleteItem<T extends Storable>(
    List<T> list,
    String id,
    String itemType,
  ) {
    final initialLength = list.length;
    list.removeWhere((existingItem) => existingItem.id == id);
    if (list.length < initialLength) {
      _logger.i('Deleted $itemType with ID: $id');
    } else {
      _logger.w('$itemType with ID $id not found for deletion.');
    }
  }

  // Videos
  void saveVideo(VideoContent video) {
    // No try-catch needed for in-memory, unless specific logic requires it.
    _saveItem<VideoContent>(_videos, video, 'video');
  }

  List<VideoContent> getVideos() {
    return _getItems<VideoContent>(_videos, 'video');
  }

  VideoContent? getVideoById(String id) {
    return _getItemById<VideoContent>(_videos, id, 'video');
  }

  void deleteVideo(String id) {
    _deleteItem<VideoContent>(_videos, id, 'video');
    // Also delete associated vocabulary items
    deleteVocabularyByVideoId(id);
  }

  // Vocabulary
  void saveVocabularyItem(VocabularyItem item) {
    _saveItem<VocabularyItem>(_vocabularyItems, item, 'vocabulary item');
  }

  List<VocabularyItem> getVocabularyItems() {
    return _getItems<VocabularyItem>(_vocabularyItems, 'vocabulary item');
  }

  List<VocabularyItem> getVocabularyByVideoId(String videoId) {
    final filteredItems =
        _vocabularyItems
            .where((item) => item.sourceVideoId == videoId)
            .toList();
    _logger.d(
      'Retrieved ${filteredItems.length} vocabulary items for video: $videoId',
    );
    return filteredItems;
  }

  void deleteVocabularyItem(String id) {
    _deleteItem<VocabularyItem>(_vocabularyItems, id, 'vocabulary item');
  }

  void deleteVocabularyByVideoId(String videoId) {
    final initialCount = _vocabularyItems.length;
    _vocabularyItems.removeWhere((item) => item.sourceVideoId == videoId);
    final deletedCount = initialCount - _vocabularyItems.length;
    if (deletedCount > 0) {
      _logger.i('Deleted $deletedCount vocabulary items for video: $videoId');
    }
  }
}
