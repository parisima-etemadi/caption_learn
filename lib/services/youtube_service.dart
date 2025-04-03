import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_content.dart';

class YouTubeService {
  /// Fetches subtitles from a YouTube video and converts them to the app's Subtitle format
  static Future<List<Subtitle>> getYouTubeSubtitles(String videoId) async {
    final yt = YoutubeExplode();
    final subtitles = <Subtitle>[];
    
    try {
      // Get closed captions manifest
      final manifest = await yt.videos.closedCaptions.getManifest(videoId);
      
      // Get the first available track
      if (manifest.tracks.isNotEmpty) {
        // Try to find English track first
        final track = manifest.tracks
            .firstWhere(
                (t) => t.language.code.toLowerCase() == 'en',
                orElse: () => manifest.tracks.first
            );
        
        // Get the actual closed captions
        final closedCaptions = await yt.videos.closedCaptions.get(track);
        
        // Convert to our app's Subtitle format
        for (final caption in closedCaptions.captions) {
          subtitles.add(
            Subtitle(
              startTime: caption.offset.inMilliseconds,
              endTime: (caption.offset + caption.duration).inMilliseconds,
              text: caption.text,
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching YouTube subtitles: $e');
    } finally {
      yt.close();
    }
    
    return subtitles;
  }
  
  /// Gets video details from YouTube
  static Future<Map<String, dynamic>> getVideoDetails(String videoId) async {
    final yt = YoutubeExplode();
    
    try {
      final video = await yt.videos.get(videoId);
      
      return {
        'title': video.title,
        'author': video.author,
        'duration': video.duration?.inMilliseconds,
        'thumbnailUrl': video.thumbnails.highResUrl,
      };
    } catch (e) {
      print('Error fetching YouTube video details: $e');
      return {};
    } finally {
      yt.close();
    }
  }
} 