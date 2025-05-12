import 'dart:async';
import 'dart:convert';
import 'package:caption_learn/services/firebase_service.dart';
import 'package:caption_learn/services/hive_service.dart';
import 'package:caption_learn/features/video/data/models/video_content.dart';
import 'package:caption_learn/features/vocabulary/models/vocabulary_item.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

// Interface for items that can be stored and have an ID.
abstract class Storable {
  String get id;
  Map<String, dynamic> toJson();
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  final Logger _logger = const Logger('StorageService');
  final FirebaseService _firebaseService = FirebaseService();
  final HiveService _hiveService = HiveService();
  
  // Queue for operations that need to be synchronized when back online
  final List<_PendingOperation> _pendingOperations = [];
  
  // Connectivity status
  bool _isOnline = true;
  
late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal() {
    // Initialize connectivity listener
    _initConnectivityListener();
  }
  
  // Initialize connectivity listener
void _initConnectivityListener() {
  _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
    // Use the first result or a default if the list is empty
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    
    final wasOffline = !_isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    if (wasOffline && _isOnline) {
      _logger.i('Back online, processing pending operations');
      _processPendingOperations();
    } else if (!_isOnline) {
      _logger.w('Device is offline, operations will be queued');
    }
  });
  
  // Check initial connectivity
  Connectivity().checkConnectivity().then((results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _isOnline = result != ConnectivityResult.none;
    if (_isOnline) {
      _logger.i('Device is online');
    } else {
      _logger.w('Device is offline');
    }
  });
}
  
  // Process pending operations
  Future<void> _processPendingOperations() async {
    if (_pendingOperations.isEmpty) return;
    
    _logger.i('Processing ${_pendingOperations.length} pending operations');
    
    final operationsToProcess = List<_PendingOperation>.from(_pendingOperations);
    _pendingOperations.clear();
    
    for (final operation in operationsToProcess) {
      try {
        switch (operation.type) {
          case _OperationType.saveVideo:
            await _firebaseService.saveVideo(operation.data as VideoContent);
            break;
          case _OperationType.deleteVideo:
            await _firebaseService.deleteVideo(operation.id);
            break;
          case _OperationType.saveVocabulary:
            await _firebaseService.saveVocabularyItem(operation.data as VocabularyItem);
            break;
          case _OperationType.deleteVocabulary:
            await _firebaseService.deleteVocabularyItem(operation.id);
            break;
          case _OperationType.deleteVideoVocabulary:
            await _firebaseService.deleteVocabularyByVideoId(operation.id);
            break;
        }
        _logger.i('Successfully processed operation: ${operation.type}');
      } catch (e) {
        _logger.e('Failed to process pending operation', e);
        // Re-add to pending operations if still failing
        _pendingOperations.add(operation);
      }
    }
  }
  
  // Add operation to pending queue
  void _addPendingOperation(_PendingOperation operation) {
    _pendingOperations.add(operation);
    _logger.i('Added pending operation: ${operation.type}');
  }
  
  // Initialize the storage service
  Future<void> initialize() async {
    await _hiveService.openBoxes();
    
    // If online, try to sync from Firebase to Hive
    if (_isOnline && _firebaseService.isUserLoggedIn) {
      try {
        await syncFromFirebase();
      } catch (e) {
        _logger.e('Failed to sync from Firebase during initialization', e);
      }
    }
  }
  
  // Sync data from Firebase to Hive
  Future<void> syncFromFirebase() async {
    if (!_isOnline || !_firebaseService.isUserLoggedIn) {
      _logger.w('Cannot sync from Firebase: ${!_isOnline ? 'Offline' : 'Not logged in'}');
      return;
    }
    
    try {
      _logger.i('Starting sync from Firebase to Hive');
      
      // Sync videos
      final firebaseVideos = await _firebaseService.getVideos();
      for (final video in firebaseVideos) {
        await _hiveService.saveVideo(video);
      }
      
      // Sync vocabulary
      final firebaseVocabulary = await _firebaseService.getVocabularyItems();
      for (final item in firebaseVocabulary) {
        await _hiveService.saveVocabularyItem(item);
      }
      
      _logger.i('Successfully synced data from Firebase to Hive');
    } catch (e) {
      _logger.e('Failed to sync from Firebase to Hive', e);
      throw Exception('Failed to sync from Firebase: $e');
    }
  }
  
  // Clean up resources
  Future<void> dispose() async {
    await _connectivitySubscription.cancel();
    await _hiveService.closeBoxes();
  }

  // VIDEOS
  
  // Save video
  Future<void> saveVideo(VideoContent video) async {
    try {
      // Always save to Hive
      await _hiveService.saveVideo(video);
      _logger.i('Saved video to Hive: ${video.id}');
      
      // If online and logged in, save to Firebase
      if (_isOnline && _firebaseService.isUserLoggedIn) {
        await _firebaseService.saveVideo(video);
        _logger.i('Saved video to Firebase: ${video.id}');
      } else {
        // Add to pending operations
        _addPendingOperation(_PendingOperation(
          type: _OperationType.saveVideo,
          id: video.id,
          data: video,
        ));
      }
    } catch (e) {
      _logger.e('Failed to save video', e);
      throw Exception('Failed to save video: $e');
    }
  }

  // Get all videos
  List<VideoContent> getVideos() {
    try {
      final videos = _hiveService.getVideos();
      _logger.i('Retrieved ${videos.length} videos from Hive');
      return videos;
    } catch (e) {
      _logger.e('Failed to get videos', e);
      return [];
    }
  }

  // Get video by ID
  VideoContent? getVideoById(String id) {
    try {
      final video = _hiveService.getVideoById(id);
      if (video != null) {
        _logger.i('Retrieved video from Hive: $id');
      } else {
        _logger.w('Video with ID $id not found');
      }
      return video;
    } catch (e) {
      _logger.e('Failed to get video by ID', e);
      return null;
    }
  }

  // Delete video
  Future<void> deleteVideo(String id) async {
    try {
      // Always delete from Hive
      await _hiveService.deleteVideo(id);
      _logger.i('Deleted video from Hive: $id');
      
      // If online and logged in, delete from Firebase
      if (_isOnline && _firebaseService.isUserLoggedIn) {
        await _firebaseService.deleteVideo(id);
        _logger.i('Deleted video from Firebase: $id');
      } else {
        // Add to pending operations
        _addPendingOperation(_PendingOperation(
          type: _OperationType.deleteVideo,
          id: id,
        ));
      }
      
      // Also delete associated vocabulary
      await deleteVocabularyByVideoId(id);
    } catch (e) {
      _logger.e('Failed to delete video', e);
      throw Exception('Failed to delete video: $e');
    }
  }

  // VOCABULARY
  
  // Save vocabulary item
  Future<void> saveVocabularyItem(VocabularyItem item) async {
    try {
      // Always save to Hive
      await _hiveService.saveVocabularyItem(item);
      _logger.i('Saved vocabulary item to Hive: ${item.id}');
      
      // If online and logged in, save to Firebase
      if (_isOnline && _firebaseService.isUserLoggedIn) {
        await _firebaseService.saveVocabularyItem(item);
        _logger.i('Saved vocabulary item to Firebase: ${item.id}');
      } else {
        // Add to pending operations
        _addPendingOperation(_PendingOperation(
          type: _OperationType.saveVocabulary,
          id: item.id,
          data: item,
        ));
      }
    } catch (e) {
      _logger.e('Failed to save vocabulary item', e);
      throw Exception('Failed to save vocabulary item: $e');
    }
  }

  // Get all vocabulary items
  List<VocabularyItem> getVocabularyItems() {
    try {
      final items = _hiveService.getVocabularyItems();
      _logger.i('Retrieved ${items.length} vocabulary items from Hive');
      return items;
    } catch (e) {
      _logger.e('Failed to get vocabulary items', e);
      return [];
    }
  }

  // Get vocabulary by video ID
  List<VocabularyItem> getVocabularyByVideoId(String videoId) {
    try {
      final items = _hiveService.getVocabularyByVideoId(videoId);
      _logger.i('Retrieved ${items.length} vocabulary items for video: $videoId');
      return items;
    } catch (e) {
      _logger.e('Failed to get vocabulary by video ID', e);
      return [];
    }
  }

  // Delete vocabulary item
  Future<void> deleteVocabularyItem(String id) async {
    try {
      // Always delete from Hive
      await _hiveService.deleteVocabularyItem(id);
      _logger.i('Deleted vocabulary item from Hive: $id');
      
      // If online and logged in, delete from Firebase
      if (_isOnline && _firebaseService.isUserLoggedIn) {
        await _firebaseService.deleteVocabularyItem(id);
        _logger.i('Deleted vocabulary item from Firebase: $id');
      } else {
        // Add to pending operations
        _addPendingOperation(_PendingOperation(
          type: _OperationType.deleteVocabulary,
          id: id,
        ));
      }
    } catch (e) {
      _logger.e('Failed to delete vocabulary item', e);
      throw Exception('Failed to delete vocabulary item: $e');
    }
  }

  // Delete all vocabulary items for a video
  Future<void> deleteVocabularyByVideoId(String videoId) async {
    try {
      // Always delete from Hive
      await _hiveService.deleteVocabularyByVideoId(videoId);
      _logger.i('Deleted vocabulary items for video from Hive: $videoId');
      
      // If online and logged in, delete from Firebase
      if (_isOnline && _firebaseService.isUserLoggedIn) {
        await _firebaseService.deleteVocabularyByVideoId(videoId);
        _logger.i('Deleted vocabulary items for video from Firebase: $videoId');
      } else {
        // Add to pending operations
        _addPendingOperation(_PendingOperation(
          type: _OperationType.deleteVideoVocabulary,
          id: videoId,
        ));
      }
    } catch (e) {
      _logger.e('Failed to delete vocabulary by video ID', e);
      throw Exception('Failed to delete vocabulary by video ID: $e');
    }
  }
}

// Helper class for pending operations
enum _OperationType {
  saveVideo,
  deleteVideo,
  saveVocabulary,
  deleteVocabulary,
  deleteVideoVocabulary,
}

class _PendingOperation {
  final _OperationType type;
  final String id;
  final dynamic data;
  
  _PendingOperation({
    required this.type,
    required this.id,
    this.data,
  });
}