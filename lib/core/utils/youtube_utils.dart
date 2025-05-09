class YoutubeUtils {
  // Validates if the URL is a YouTube URL
  static bool isYoutubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  // Extract YouTube video ID from URL
  static String? extractYoutubeVideoId(String url) {
    final RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(7);
  }
}
