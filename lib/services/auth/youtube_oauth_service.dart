import 'package:http/http.dart' as http;
import '../../core/services/base_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/auth_state_manager.dart';
import '../auth_service.dart';

/// Service to handle YouTube API operations using unified auth
class YouTubeOAuthService extends BaseService {
  static final YouTubeOAuthService _instance = YouTubeOAuthService._internal();
  factory YouTubeOAuthService() => _instance;
  YouTubeOAuthService._internal();

  @override
  String get serviceName => 'YouTubeOAuthService';

  final AuthStateManager _authManager = AuthStateManager();
  final AuthService _authService = AuthService();

  /// Check if user is authenticated for YouTube
  bool get isAuthenticated => _authManager.hasYouTubeAccess;

  /// Sign in with Google for YouTube access
  Future<bool> signIn() async {
    try {
      logger.i('Requesting YouTube access through unified auth');
      
      // If user is not logged in at all, sign in with Google
      if (!_authManager.isAuthenticated) {
        await _authManager.signInWithGoogle();
      }
      
      // If user is logged in but doesn't have YouTube access, request it
      if (!_authManager.hasYouTubeAccess) {
        return await _authManager.requestYouTubeAccess();
      }
      
      return true;
    } catch (e) {
      logger.e('Failed to sign in for YouTube access', e);
      return false;
    }
  }

  /// Sign out (delegates to unified auth)
  Future<void> signOut() async {
    // This now just delegates to the main auth service
    await _authManager.signOut();
  }

  /// Download captions using OAuth
  Future<String?> downloadCaptions(String captionId) async {
    // Check if we have YouTube access
    if (!isAuthenticated) {
      logger.w('Not authenticated for caption download');
      return null;
    }

    // Refresh token if needed
    await _authManager.refreshYouTubeTokenIfNeeded();
    
    final accessToken = _authManager.youtubeAccessToken;
    if (accessToken == null) {
      logger.w('No access token available');
      return null;
    }

    try {
      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/captions/$captionId'
      ).replace(queryParameters: {
        'tfmt': 'srt', // or 'vtt', 'ttml'
        'key': AppConstants.youtubeApiKey,
      });

      logger.i('Downloading caption: $captionId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'text/plain',
        },
      );

      if (response.statusCode == 200) {
        logger.i('Successfully downloaded caption');
        return response.body;
      } else if (response.statusCode == 403) {
        logger.w('Forbidden (403): Caption download disabled by video owner or insufficient permissions.');
        throw Exception('403: The video owner has likely disabled subtitle downloads for third-party apps.');
      } else if (response.statusCode == 401) {
        logger.w('Access token expired, attempting to refresh');
        // Try to refresh token
        await _authService.refreshYouTubeToken();
        // Retry once with new token
        final newToken = _authManager.youtubeAccessToken;
        if (newToken != null && newToken != accessToken) {
          final retryResponse = await http.get(
            url,
            headers: {
              'Authorization': 'Bearer $newToken',
              'Accept': 'text/plain',
            },
          );
          if (retryResponse.statusCode == 200) {
            logger.i('Successfully downloaded caption after token refresh');
            return retryResponse.body;
          }
        }
        return null;
      } else {
        logger.w('Failed to download caption: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Caption download failed', e);
      rethrow;
    }
  }

  /// Get current access token
  String? get accessToken => _authManager.youtubeAccessToken;
}