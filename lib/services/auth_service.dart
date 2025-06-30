import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/constants/app_constants.dart';
import '../core/services/base_service.dart';

class AuthService extends BaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(clientId: AppConstants.googleClientId);
  
  @override
  String get serviceName => 'AuthService';
  
  // Store verification ID for phone auth
  String? _verificationId;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
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
  
  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign in aborted');
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
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
      logger.i('User signed out');
    } catch (e) {
      logger.e('Error signing out', e);
      rethrow;
    }
  }
}