import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../core/services/base_service.dart';
import '../../core/constants/app_constants.dart';

/// Service to handle YouTube OAuth authentication for caption access
class YouTubeOAuthService extends BaseService {
  static final YouTubeOAuthService _instance = YouTubeOAuthService._internal();
  factory YouTubeOAuthService() => _instance;
  YouTubeOAuthService._internal();

  @override
  String get serviceName => 'YouTubeOAuthService';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: AppConstants.googleClientId,
    scopes: [
      'https://www.googleapis.com/auth/youtube.force-ssl',
      'https://www.googleapis.com/auth/youtube.readonly',
    ],
  );

  GoogleSignInAccount? _currentUser;
  String? _accessToken;

  /// Check if user is authenticated for YouTube
  bool get isAuthenticated => _currentUser != null && _accessToken != null;

  /// Sign in with Google for YouTube access
  Future<bool> signIn() async {
    try {
      logger.i('Initiating YouTube OAuth sign in');
      
      final account = await _googleSignIn.signIn();
      if (account == null) {
        logger.w('User cancelled sign in');
        return false;
      }

      _currentUser = account;
      
      // Get auth headers which include the access token
      final auth = await account.authentication;
      _accessToken = auth.accessToken;
      
      logger.i('Successfully signed in as: ${account.email}');
      return true;
    } catch (e) {
      logger.e('Failed to sign in', e);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _accessToken = null;
    logger.i('Signed out from YouTube OAuth');
  }

  /// Download captions using OAuth
  Future<String?> downloadCaptions(String captionId) async {
    if (!isAuthenticated || _accessToken == null) {
      logger.w('Not authenticated for caption download');
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
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'text/plain',
        },
      );

      if (response.statusCode == 200) {
        logger.i('Successfully downloaded caption');
        return response.body;
      } else if (response.statusCode == 403) {
        // **MODIFICATION**: Handle the 403 Forbidden error specifically.
        logger.w('Forbidden (403): Caption download disabled by video owner or insufficient permissions.');
        throw Exception('403: The video owner has likely disabled subtitle downloads for third-party apps.');
      } else if (response.statusCode == 401) {
        logger.w('Access token expired, need to re-authenticate');
        // Try to refresh token
        await _refreshToken();
        return null;
      } else {
        logger.w('Failed to download caption: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Caption download failed', e);
      // Re-throw the exception to be handled by the calling service
      rethrow;
    }
  }

  /// Refresh access token
  Future<void> _refreshToken() async {
    if (_currentUser == null) return;
    
    try {
      final auth = await _currentUser!.authentication;
      _accessToken = auth.accessToken;
      logger.i('Access token refreshed');
    } catch (e) {
      logger.e('Failed to refresh token', e);
    }
  }

  /// Get current access token
  String? get accessToken => _accessToken;
}