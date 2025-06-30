import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../features/video/data/models/video_content.dart';
import '../../features/video/domain/enum/video_source.dart';
import 'youtube_exceptions.dart';

/// Simple, fast YouTube video processor
class YouTubeVideoProcessor {
  final YoutubeExplode _yt;
  final Map<String, VideoContent> _cache = {};
  
  YouTubeVideoProcessor(this._yt);
  
  /// Process YouTube URL - simplified and faster
  Future<VideoContent> processVideoUrl(String url) async {
    final videoId = VideoId.parseVideoId(url);
    if (videoId == null) throw YouTubeServiceException('Invalid YouTube URL');
    
    final id = videoId.toString();
    if (_cache.containsKey(id)) return _cache[id]!;
    
    try {
      final video = await _yt.videos.get(videoId);
      ClosedCaptionManifest? manifest;
      
      try {
        manifest = await _yt.videos.closedCaptions.getManifest(videoId);
      } catch (_) {
        manifest = null;
      }
      
      List<Subtitle> subtitles = [];
      String? warning;
      
      if (manifest?.tracks.isNotEmpty == true) {
        try {
          final track = manifest!.tracks.where((t) => t.language.code.startsWith('en')).firstOrNull ?? manifest.tracks.first;
          final captions = await _yt.videos.closedCaptions.get(track);
          subtitles = captions.captions.map((c) => Subtitle(
            startTime: c.offset.inMilliseconds,
            endTime: (c.offset + c.duration).inMilliseconds,
            text: c.text,
          )).toList();
        } catch (_) {
          warning = 'Subtitles unavailable';
        }
      } else {
        warning = 'No subtitles found';
      }
      
      final result = VideoContent(
        id: id,
        title: video.title,
        sourceUrl: url,
        subtitles: subtitles,
        source: VideoSource.youtube,
        dateAdded: DateTime.now(),
        subtitleWarning: warning,
      );
      
      return _cache[id] = result;
    } catch (e) {
      throw YouTubeServiceException('Failed to process video: $e');
    }
  }
  
  void clearCache() => _cache.clear();
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}