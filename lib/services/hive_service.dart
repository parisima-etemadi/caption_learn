import 'package:caption_learn/core/utils/logger.dart';
import 'package:caption_learn/features/video/data/models/video_content.dart';
import 'package:caption_learn/features/video/domain/enum/video_source.dart';
import 'package:caption_learn/features/vocabulary/models/vocabulary_item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';


class HiveService {
  static final HiveService _instance = HiveService._internal();
  final Logger _logger = const Logger('HiveService');

  // Box names
  static const String videosBoxName = 'videos';
  static const String vocabularyBoxName = 'vocabulary';

  // Boxes
  late Box<VideoContent> _videosBox;
  late Box<VocabularyItem> _vocabularyBox;

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  // Initialize Hive
  static Future<void> initialize() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocDir.path);

      // Register adapters
      Hive.registerAdapter(VideoSourceAdapter());
      Hive.registerAdapter(SubtitleAdapter());
      Hive.registerAdapter(VideoContentAdapter());
      Hive.registerAdapter(VocabularyItemAdapter());

      final logger = Logger('HiveService');
      logger.i('Hive initialized successfully');
    } catch (e, stackTrace) {
      final logger = Logger('HiveService');
      logger.e('Failed to initialize Hive', e, stackTrace);
      rethrow;
    }
  }

  // Open boxes
  Future<void> openBoxes() async {
    try {
      _videosBox = await Hive.openBox<VideoContent>(videosBoxName);
      _vocabularyBox = await Hive.openBox<VocabularyItem>(vocabularyBoxName);
      _logger.i('Hive boxes opened successfully');
    } catch (e) {
      _logger.e('Failed to open Hive boxes', e);
      rethrow;
    }
  }

  // Close boxes
  Future<void> closeBoxes() async {
    try {
      await _videosBox.close();
      await _vocabularyBox.close();
      _logger.i('Hive boxes closed successfully');
    } catch (e) {
      _logger.e('Failed to close Hive boxes', e);
      rethrow;
    }
  }

  // VIDEOS METHODS

  // Save video to Hive
  Future<void> saveVideo(VideoContent video) async {
    try {
      await _videosBox.put(video.id, video);
      _logger.i('Video saved to Hive: ${video.id}');
    } catch (e) {
      _logger.e('Failed to save video to Hive', e);
      rethrow;
    }
  }

  // Get all videos
  List<VideoContent> getVideos() {
    try {
      final videos = _videosBox.values.toList();
      _logger.i('Fetched ${videos.length} videos from Hive');
      return videos;
    } catch (e) {
      _logger.e('Failed to fetch videos from Hive', e);
      return [];
    }
  }

  // Get a specific video
  VideoContent? getVideoById(String id) {
    try {
      final video = _videosBox.get(id);
      if (video != null) {
        _logger.i('Fetched video from Hive: $id');
      } else {
        _logger.w('Video not found in Hive: $id');
      }
      return video;
    } catch (e) {
      _logger.e('Failed to fetch video from Hive', e);
      return null;
    }
  }

  // Delete a video
  Future<void> deleteVideo(String id) async {
    try {
      await _videosBox.delete(id);
      _logger.i('Video deleted from Hive: $id');
      // Also delete related vocabulary items
      await deleteVocabularyByVideoId(id);
    } catch (e) {
      _logger.e('Failed to delete video from Hive', e);
      rethrow;
    }
  }

  // VOCABULARY METHODS

  // Save vocabulary item
  Future<void> saveVocabularyItem(VocabularyItem item) async {
    try {
      await _vocabularyBox.put(item.id, item);
      _logger.i('Vocabulary item saved to Hive: ${item.id}');
    } catch (e) {
      _logger.e('Failed to save vocabulary to Hive', e);
      rethrow;
    }
  }

  // Get all vocabulary items
  List<VocabularyItem> getVocabularyItems() {
    try {
      final items = _vocabularyBox.values.toList();
      _logger.i('Fetched ${items.length} vocabulary items from Hive');
      return items;
    } catch (e) {
      _logger.e('Failed to fetch vocabulary from Hive', e);
      return [];
    }
  }

  // Get vocabulary items for a specific video
  List<VocabularyItem> getVocabularyByVideoId(String videoId) {
    try {
      final items = _vocabularyBox.values
          .where((item) => item.sourceVideoId == videoId)
          .toList();
      _logger.i('Fetched ${items.length} vocabulary items for video $videoId');
      return items;
    } catch (e) {
      _logger.e('Failed to fetch vocabulary for video $videoId', e);
      return [];
    }
  }

  // Delete a vocabulary item
  Future<void> deleteVocabularyItem(String id) async {
    try {
      await _vocabularyBox.delete(id);
      _logger.i('Vocabulary item deleted from Hive: $id');
    } catch (e) {
      _logger.e('Failed to delete vocabulary from Hive', e);
      rethrow;
    }
  }

  // Delete all vocabulary items for a video
  Future<void> deleteVocabularyByVideoId(String videoId) async {
    try {
      // Get keys of vocabulary items to delete
      final keysToDelete = _vocabularyBox.values
          .where((item) => item.sourceVideoId == videoId)
          .map((item) => item.id)
          .toList();

      // Delete all keys
      for (final key in keysToDelete) {
        await _vocabularyBox.delete(key);
      }

      _logger.i('Deleted ${keysToDelete.length} vocabulary items for video $videoId');
    } catch (e) {
      _logger.e('Failed to delete vocabulary for video $videoId', e);
      rethrow;
    }
  }
}

