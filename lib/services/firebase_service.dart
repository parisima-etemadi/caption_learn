import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../core/utils/logger.dart';
import '../firebase_options.dart';
import '../features/video/data/models/video_content.dart';
import '../features/vocabulary/models/vocabulary_item.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final Logger _logger = const Logger('FirebaseService');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // References to collections
  late final CollectionReference _videosCollection;
  late final CollectionReference _vocabularyCollection;

  // Getter for current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isUserLoggedIn => _auth.currentUser != null;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal() {
    _videosCollection = _firestore.collection('videos');
    _vocabularyCollection = _firestore.collection('vocabulary');
  }

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final logger = Logger('FirebaseService');
      logger.i('Firebase initialized successfully');
    } catch (e, stackTrace) {
      final logger = Logger('FirebaseService');
      logger.e('Failed to initialize Firebase', e, stackTrace);
      rethrow;
    }
  }

  // VIDEOS METHODS

  // Save video to Firestore
  Future<void> saveVideo(VideoContent video) async {
    if (currentUserId == null) {
      _logger.w('Cannot save video: No user logged in');
      throw Exception('User must be logged in to save videos');
    }

    try {
      final videoData = video.toJson();
      // Add user ID to the data
      videoData['userId'] = currentUserId;
      
      await _videosCollection.doc(video.id).set(videoData);
      _logger.i('Video saved to Firestore: ${video.id}');
    } catch (e) {
      _logger.e('Failed to save video to Firestore', e);
      rethrow;
    }
  }

  // Get all videos for current user
  Future<List<VideoContent>> getVideos() async {
    if (currentUserId == null) {
      _logger.w('Cannot fetch videos: No user logged in');
      return [];
    }

    try {
      final snapshot = await _videosCollection
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      final videos = snapshot.docs
          .map((doc) => VideoContent.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      _logger.i('Fetched ${videos.length} videos from Firestore');
      return videos;
    } catch (e) {
      _logger.e('Failed to fetch videos from Firestore', e);
      return [];
    }
  }

  // Get a specific video
  Future<VideoContent?> getVideoById(String id) async {
    try {
      final doc = await _videosCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Verify the video belongs to the current user
        if (data['userId'] == currentUserId) {
          _logger.i('Fetched video from Firestore: $id');
          return VideoContent.fromJson(data);
        } else {
          _logger.w('Video $id does not belong to the current user');
          return null;
        }
      } else {
        _logger.w('Video not found in Firestore: $id');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to fetch video from Firestore', e);
      return null;
    }
  }

  // Delete a video
  Future<void> deleteVideo(String id) async {
    try {
      // First, get the video to check ownership
      final videoDoc = await _videosCollection.doc(id).get();
      if (videoDoc.exists) {
        final data = videoDoc.data() as Map<String, dynamic>;
        
        // Verify the video belongs to the current user
        if (data['userId'] == currentUserId) {
          // Delete the video document
          await _videosCollection.doc(id).delete();
          
          // Also delete related vocabulary items
          await deleteVocabularyByVideoId(id);
          
          _logger.i('Video deleted from Firestore: $id');
        } else {
          _logger.w('Cannot delete video $id: Does not belong to current user');
          throw Exception('You can only delete your own videos');
        }
      } else {
        _logger.w('Cannot delete video: Not found in Firestore: $id');
      }
    } catch (e) {
      _logger.e('Failed to delete video from Firestore', e);
      rethrow;
    }
  }

  // VOCABULARY METHODS

  // Save vocabulary item
  Future<void> saveVocabularyItem(VocabularyItem item) async {
    if (currentUserId == null) {
      _logger.w('Cannot save vocabulary: No user logged in');
      throw Exception('User must be logged in to save vocabulary');
    }

    try {
      final vocabData = item.toJson();
      // Add user ID to the data
      vocabData['userId'] = currentUserId;
      
      await _vocabularyCollection.doc(item.id).set(vocabData);
      _logger.i('Vocabulary item saved to Firestore: ${item.id}');
    } catch (e) {
      _logger.e('Failed to save vocabulary to Firestore', e);
      rethrow;
    }
  }

  // Get all vocabulary items for current user
  Future<List<VocabularyItem>> getVocabularyItems() async {
    if (currentUserId == null) {
      _logger.w('Cannot fetch vocabulary: No user logged in');
      return [];
    }

    try {
      final snapshot = await _vocabularyCollection
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      final items = snapshot.docs
          .map((doc) => VocabularyItem.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      _logger.i('Fetched ${items.length} vocabulary items from Firestore');
      return items;
    } catch (e) {
      _logger.e('Failed to fetch vocabulary from Firestore', e);
      return [];
    }
  }

  // Get vocabulary items for a specific video
  Future<List<VocabularyItem>> getVocabularyByVideoId(String videoId) async {
    if (currentUserId == null) {
      _logger.w('Cannot fetch vocabulary: No user logged in');
      return [];
    }

    try {
      final snapshot = await _vocabularyCollection
          .where('userId', isEqualTo: currentUserId)
          .where('sourceVideoId', isEqualTo: videoId)
          .get();
      
      final items = snapshot.docs
          .map((doc) => VocabularyItem.fromJson(doc.data() as Map<String, dynamic>))
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
      // First, get the item to check ownership
      final itemDoc = await _vocabularyCollection.doc(id).get();
      if (itemDoc.exists) {
        final data = itemDoc.data() as Map<String, dynamic>;
        
        // Verify the item belongs to the current user
        if (data['userId'] == currentUserId) {
          await _vocabularyCollection.doc(id).delete();
          _logger.i('Vocabulary item deleted from Firestore: $id');
        } else {
          _logger.w('Cannot delete vocabulary $id: Does not belong to current user');
          throw Exception('You can only delete your own vocabulary items');
        }
      } else {
        _logger.w('Cannot delete vocabulary: Not found in Firestore: $id');
      }
    } catch (e) {
      _logger.e('Failed to delete vocabulary from Firestore', e);
      rethrow;
    }
  }

  // Delete all vocabulary items for a video
  Future<void> deleteVocabularyByVideoId(String videoId) async {
    if (currentUserId == null) {
      _logger.w('Cannot delete vocabulary: No user logged in');
      return;
    }

    try {
      final batch = _firestore.batch();
      final snapshot = await _vocabularyCollection
          .where('userId', isEqualTo: currentUserId)
          .where('sourceVideoId', isEqualTo: videoId)
          .get();
      
      // Add each document to batch delete
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch
      await batch.commit();
      _logger.i('Deleted ${snapshot.docs.length} vocabulary items for video $videoId');
    } catch (e) {
      _logger.e('Failed to delete vocabulary for video $videoId', e);
      rethrow;
    }
  }
}