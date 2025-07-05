import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/constants/app_constants.dart';
import '../core/services/base_service.dart';
import 'hive_service.dart';

class AuthService extends BaseService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Single GoogleSignIn instance with all required scopes including YouTube
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConstants.googleAndroidClientId,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube.force-ssl',
      'https://www.googleapis.com/auth/youtube.readonly',
    ],
  );
  
  @override
  String get serviceName => 'AuthService';
  
  // Store verification ID for phone auth
  String? _verificationId;
  
  // Cache for YouTube access token
  String? _youtubeAccessToken;
  DateTime? _tokenExpiry;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Check if user has YouTube access
  bool get hasYouTubeAccess => _youtubeAccessToken != null && 
      (_tokenExpiry == null || _tokenExpiry!.isAfter(DateTime.now()));
  
  // Get YouTube access token
  String? get youtubeAccessToken => hasYouTubeAccess ? _youtubeAccessToken : null;
  
  /// Initialize service and restore any saved tokens
  Future<void> initialize() async {
    try {
      // Check if user is already signed in
      if (currentUser != null) {
        await _restoreYouTubeToken();
      }
      
      logger.i('Auth service initialized');
    } catch (e) {
      logger.e('Failed to initialize auth service', e);
    }
  }
  
  // Send phone verification code
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    Function(PhoneAuthCredential)? onVerificationCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          logger.i('Phone verification completed automatically');
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          logger.e('Phone verification failed', e);
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          logger.i('Verification code sent to $phoneNumber');
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          logger.i('Auto retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: AppConstants.phoneVerificationTimeout,
      );
    } catch (e) {
      logger.e('Error sending verification code', e);
      rethrow;
    }
  }
  
  // Sign in with phone verification code
  Future<UserCredential> signInWithPhoneCode(String smsCode, [String? verificationId]) async {
    try {
      // Use provided verification ID or stored one
      final String vid = verificationId ?? _verificationId ?? '';
      
      if (vid.isEmpty) {
        throw Exception('Verification ID not found. Please request a new code.');
      }
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: smsCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      logger.i('Signed in with phone: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      logger.e('Error signing in with phone code', e);
      rethrow;
    }
  }
  
  // Sign in with a credential (used for phone auth auto-verification)
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      logger.i('Signed in with credential: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      logger.e('Error signing in with credential', e);
      rethrow;
    }
  }
  
  // Sign in with Google (includes YouTube permissions)
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Sign out from any existing Google session to ensure fresh consent
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign in aborted');
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Store YouTube access token
      if (googleAuth.accessToken != null) {
        await _saveYouTubeToken(googleAuth.accessToken!);
      }
      
      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      logger.i('Signed in with Google: ${userCredential.user?.uid}');
      
      return userCredential;
    } catch (e) {
      logger.e('Error signing in with Google', e);
      rethrow;
    }
  }
  
  // Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      logger.i('Signed in with Apple: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      logger.e('Error signing in with Apple', e);
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await _clearYouTubeToken();
      logger.i('User signed out');
    } catch (e) {
      logger.e('Error signing out', e);
      rethrow;
    }
  }
  
  /// Request YouTube permissions for existing user
  Future<bool> requestYouTubeAccess() async {
    try {
      if (!(_auth.currentUser?.providerData.any((info) => info.providerId == 'google.com') ?? false)) {
        logger.w('User is not signed in with Google');
        return false;
      }
      
      // Sign in again to get YouTube permissions
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        logger.w('User cancelled YouTube permission request');
        return false;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Store YouTube access token
      if (googleAuth.accessToken != null) {
        await _saveYouTubeToken(googleAuth.accessToken!);
        return true;
      }
      
      return false;
    } catch (e) {
      logger.e('Failed to request YouTube access', e);
      return false;
    }
  }
  
  /// Refresh YouTube access token
  Future<void> refreshYouTubeToken() async {
    try {
      if (_googleSignIn.currentUser == null) {
        // Try to sign in silently
        await _googleSignIn.signInSilently();
      }
      
      if (_googleSignIn.currentUser != null) {
        final auth = await _googleSignIn.currentUser!.authentication;
        if (auth.accessToken != null) {
          await _saveYouTubeToken(auth.accessToken!);
          logger.i('YouTube token refreshed');
        }
      }
    } catch (e) {
      logger.e('Failed to refresh YouTube token', e);
    }
  }
  
  /// Save YouTube token to persistent storage
  Future<void> _saveYouTubeToken(String token) async {
    try {
      _youtubeAccessToken = token;
      _tokenExpiry = DateTime.now().add(const Duration(minutes: 55)); // Tokens typically last 1 hour
      
      // Save to Hive for persistence
      await HiveService().saveData('youtube_access_token', token);
      await HiveService().saveData('youtube_token_expiry', _tokenExpiry!.toIso8601String());
      
      logger.i('YouTube token saved');
    } catch (e) {
      logger.e('Failed to save YouTube token', e);
    }
  }
  
  /// Restore YouTube token from storage
  Future<void> _restoreYouTubeToken() async {
    try {
      final token = await HiveService().getData('youtube_access_token');
      final expiryStr = await HiveService().getData('youtube_token_expiry');
      
      if (token != null && expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && expiry.isAfter(DateTime.now())) {
          _youtubeAccessToken = token;
          _tokenExpiry = expiry;
          logger.i('YouTube token restored from storage');
        } else {
          // Token expired, try to refresh
          await refreshYouTubeToken();
        }
      }
    } catch (e) {
      logger.e('Failed to restore YouTube token', e);
    }
  }
  
  /// Clear YouTube token
  Future<void> _clearYouTubeToken() async {
    try {
      _youtubeAccessToken = null;
      _tokenExpiry = null;
      await HiveService().deleteData('youtube_access_token');
      await HiveService().deleteData('youtube_token_expiry');
    } catch (e) {
      logger.e('Failed to clear YouTube token', e);
    }
  }
}