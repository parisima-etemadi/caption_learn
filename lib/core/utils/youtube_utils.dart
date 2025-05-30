// lib/core/utils/youtube_utils.dart
class YoutubeUtils {
  static bool isYoutubeUrl(String url) {
    // Regex to match various YouTube URL formats
    final RegExp youtubeRegExp = RegExp(
      r'^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?$',
      caseSensitive: false,
    );
    return youtubeRegExp.hasMatch(url);
  }

  static String? extractYoutubeVideoId(String url) {
    final RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?v=)|(youtu.be\/))([^#&?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    // Group 8 should capture the ID for standard YouTube URLs,
    // ensure the regex correctly captures IDs from various valid formats.
    // The original regex used group 7; this might need adjustment based on a more universal regex.
    // For a more robust solution, consider the regex from the updated isYoutubeUrl or a dedicated library.
    if (url.contains('youtu.be/')) {
      // Handle youtu.be short URLs
       final uri = Uri.parse(url);
       return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    final uri = Uri.parse(url);
    return uri.queryParameters['v'];
  }
}
