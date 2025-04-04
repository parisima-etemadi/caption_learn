// lib/services/tiktok_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:path_provider/path_provider.dart';
import '../models/video_content.dart';

class TikTokService {
  // Extract video data from TikTok URL
  static Future<Map<String, dynamic>> getTikTokVideoData(String url) async {
    try {
      // Fetch the TikTok page
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load TikTok page');
      }
      
      // Parse the HTML document
      var document = parser.parse(response.body);
      
      // Extract the title - TikTok usually has title in meta tags
      var titleElement = document.querySelector('meta[property="og:title"]');
      var title = titleElement?.attributes['content'] ?? 'TikTok Video';
      
      // Extract author name
      var authorElement = document.querySelector('meta[property="og:author"]');
      var author = authorElement?.attributes['content'] ?? 'TikTok User';
      
      // Extract video URL from og:video tag if available
      var videoElement = document.querySelector('meta[property="og:video"]');
      var videoUrl = videoElement?.attributes['content'];
      
      // Extract thumbnail
      var thumbnailElement = document.querySelector('meta[property="og:image"]');
      var thumbnailUrl = thumbnailElement?.attributes['content'];
      
      return {
        'title': title,
        'author': author,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
      };
    } catch (e) {
      print('Error extracting TikTok data: $e');
      return {
        'title': 'TikTok Video',
        'author': 'Unknown',
      };
    }
  }
  
  // Download TikTok video to local storage (if direct URL is available)
  static Future<String?> downloadTikTokVideo(String videoUrl, String fileName) async {
    try {
      if (videoUrl.isEmpty) return null;
      
      final response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download video');
      }
      
      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName.mp4';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      return filePath;
    } catch (e) {
      print('Error downloading TikTok video: $e');
      return null;
    }
  }
  
  // Extract subtitles or captions if available
  static Future<List<Subtitle>> extractTikTokCaptions(String url) async {
    // TikTok doesn't easily expose captions in a way we can extract them
    // This is a placeholder function that attempts to find captions
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return [];
      }
      
      // This is where we would parse the HTML to look for captions
      // TikTok doesn't have a standard way to include captions, so this is challenging
      // Often captions are embedded in the video itself rather than as separate data
      
      // For some TikTok videos, captions might be in the JSON-LD data
      var document = parser.parse(response.body);
      var scriptElements = document.querySelectorAll('script[type="application/ld+json"]');
      
      for (var script in scriptElements) {
        if (script.text.contains('"transcript"')) {
          // If we found transcript data, we could parse it here
          // This is just a very simple implementation assuming a basic format
          // In reality, this would need much more sophisticated parsing
          
          // Example of what we're looking for (format may vary):
          // "transcript": [{"text": "Caption text", "startOffset": 1000, "endOffset": 5000}, ...]
          
          // For now, we'll just create a simple caption for the entire video duration
          return [
            Subtitle(
              startTime: 0,
              endTime: 60000, // Assuming 60 seconds, would need to extract actual duration
              text: "Caption for TikTok video", // Would need to extract actual caption
            )
          ];
        }
      }
      
      return [];
    } catch (e) {
      print('Error extracting TikTok captions: $e');
      return [];
    }
  }
  
  // Advanced method to attempt direct video URL extraction (more experimental)
  static Future<String?> attemptDirectVideoExtraction(String tiktokUrl) async {
    try {
      // This is a more aggressive approach to extract video URLs
      // It's more likely to break with TikTok updates
      
      final response = await http.get(Uri.parse(tiktokUrl));
      if (response.statusCode != 200) {
        return null;
      }
      
      // Look for video URLs in the page source
      final bodyText = response.body;
      
      // TikTok often has video URLs in a specific format
      // These patterns may need to be updated as TikTok changes
      final regexPatterns = [
        RegExp(r'(https://v[0-9]+\.tiktokcdn\.com/[^"&\s]+)'),
        RegExp(r'(https://sf[0-9]+\.tiktokcdn\.com/[^"&\s]+)'),
        RegExp(r'video_url":"(https:\/\/[^"]+)"'),
      ];
      
      for (var regex in regexPatterns) {
        final matches = regex.allMatches(bodyText);
        for (var match in matches) {
          final url = match.group(1);
          if (url != null && url.contains('.mp4')) {
            // Clean up the URL if needed (some are escaped in JSON)
            return url.replaceAll(r'\/', '/');
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error in direct video extraction: $e');
      return null;
    }
  }
}