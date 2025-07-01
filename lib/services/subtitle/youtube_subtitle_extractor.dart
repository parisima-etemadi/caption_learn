import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/video/data/models/video_content.dart';
import '../../core/services/base_service.dart';

/// Alternative YouTube subtitle extractor using web scraping approach
class YouTubeSubtitleExtractor extends BaseService {
  @override
  String get serviceName => 'YouTubeSubtitleExtractor';
  
  /// Extract subtitles by fetching the YouTube page and parsing player data
  Future<List<Subtitle>> extractFromWebPage(String videoId) async {
    try {
      logger.i('Attempting web page extraction for video: $videoId');
      
      // Fetch the YouTube watch page
      final url = 'https://www.youtube.com/watch?v=$videoId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );
      
      if (response.statusCode != 200) {
        logger.w('Failed to fetch YouTube page: ${response.statusCode}');
        return [];
      }
      
      // Extract the ytInitialPlayerResponse JSON from the page
      final playerResponseMatch = RegExp(
        r'var ytInitialPlayerResponse\s*=\s*({.+?});',
        dotAll: true,
      ).firstMatch(response.body);
      
      if (playerResponseMatch == null) {
        logger.w('Could not find ytInitialPlayerResponse in page');
        return [];
      }
      
      try {
        final playerResponse = json.decode(playerResponseMatch.group(1)!);
        return _extractSubtitlesFromPlayerResponse(playerResponse);
      } catch (e) {
        logger.w('Failed to parse player response: $e');
        return [];
      }
    } catch (e) {
      logger.e('Web page extraction failed: $e');
      return [];
    }
  }
  
  /// Extract subtitle URLs from the player response
  Future<List<Subtitle>> _extractSubtitlesFromPlayerResponse(Map<String, dynamic> playerResponse) async {
    try {
      final captions = playerResponse['captions'];
      if (captions == null) {
        logger.i('No captions object in player response');
        return [];
      }
      
      final playerCaptionsRenderer = captions['playerCaptionsTracklistRenderer'];
      if (playerCaptionsRenderer == null) {
        logger.i('No playerCaptionsTracklistRenderer');
        return [];
      }
      
      final captionTracks = playerCaptionsRenderer['captionTracks'] as List?;
      if (captionTracks == null || captionTracks.isEmpty) {
        logger.i('No caption tracks available');
        return [];
      }
      
      logger.i('Found ${captionTracks.length} caption tracks in player response');
      
      // Find English track or use first available
      Map<String, dynamic>? selectedTrack;
      
      // Try to find English track
      for (final track in captionTracks) {
        final languageCode = track['languageCode'] as String?;
        if (languageCode != null && languageCode.startsWith('en')) {
          selectedTrack = track;
          break;
        }
      }
      
      // Fall back to first track if no English found
      selectedTrack ??= captionTracks.first;
      
      final baseUrl = selectedTrack?['baseUrl'] as String?;
      if (baseUrl == null) {
        logger.w('No baseUrl found in caption track');
        return [];
      }
      
      logger.i('Found caption URL for language: ${selectedTrack?['languageCode']}');
      
      // Fetch and parse the subtitles
      return await _fetchAndParseSubtitles(baseUrl);
    } catch (e) {
      logger.e('Failed to extract from player response: $e');
      return [];
    }
  }
  
  /// Fetch subtitles from the extracted URL
  Future<List<Subtitle>> _fetchAndParseSubtitles(String baseUrl) async {
    try {
      // Request JSON format
      final url = '$baseUrl&fmt=json3';
      logger.i('Fetching subtitles from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Referer': 'https://www.youtube.com/',
        },
      );
      
      logger.i('Response status: ${response.statusCode}, length: ${response.body.length}');
      
      if (response.statusCode != 200) {
        logger.w('Failed to fetch subtitles: ${response.statusCode}');
        return [];
      }
      
      if (response.body.isEmpty) {
        logger.w('Empty response body');
        return [];
      }
      
      // Log first part of response for debugging
      logger.i('Response preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      final data = json.decode(response.body);
      final events = data['events'] as List?;
      
      if (events == null || events.isEmpty) {
        logger.w('No events found in subtitle response');
        return [];
      }
      
      final subtitles = <Subtitle>[];
      
      for (final event in events) {
        // Skip non-text events
        if (event['segs'] == null) continue;
        
        final startMs = event['tStartMs'] as int? ?? 0;
        final durationMs = event['dDurMs'] as int? ?? 0;
        
        // Combine all segments into one text
        final segments = event['segs'] as List;
        final text = segments
            .map((seg) => seg['utf8'] as String? ?? '')
            .join('')
            .trim();
        
        if (text.isNotEmpty) {
          subtitles.add(Subtitle(
            startTime: startMs,
            endTime: startMs + durationMs,
            text: text,
          ));
        }
      }
      
      logger.i('Successfully extracted ${subtitles.length} subtitles');
      return subtitles;
    } catch (e) {
      logger.e('Failed to fetch/parse subtitles: $e');
      return [];
    }
  }
}