/// Exception thrown when YouTube service operations fail
class YouTubeServiceException implements Exception {
  final String message;
  final String? details;
  
  const YouTubeServiceException(this.message, [this.details]);
  
  @override
  String toString() {
    return details != null 
        ? 'YouTubeServiceException: $message ($details)'
        : 'YouTubeServiceException: $message';
  }
}

/// Exception thrown when subtitle operations fail
class YouTubeSubtitleException implements Exception {
  final String message;
  final String? details;
  
  const YouTubeSubtitleException(this.message, [this.details]);
  
  @override
  String toString() {
    return details != null
        ? 'YouTubeSubtitleException: $message ($details)'
        : 'YouTubeSubtitleException: $message';
  }
}