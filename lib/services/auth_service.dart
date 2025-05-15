import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(clientId: '1028174393649-3cu65svme7gqnjb847fkeid9te7jrlgv.apps.googleusercontent.com');
  final Logger _logger = const Logger('AuthService');
  
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
          _logger.i('Phone verification completed automatically');
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _logger.e('Phone verification failed', e);
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _logger.i('Verification code sent to $phoneNumber');
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _logger.i('Auto retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _logger.e('Error sending verification code', e);
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
      _logger.i('Signed in with phone: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      _logger.e('Error signing in with phone code', e);
      rethrow;
    }
  }
  
  // Sign in with a credential (used for phone auth auto-verification)
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      _logger.i('Signed in with credential: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      _logger.e('Error signing in with credential', e);
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
      _logger.i('Signed in with Google: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      _logger.e('Error signing in with Google', e);
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
      _logger.i('Signed in with Apple: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      _logger.e('Error signing in with Apple', e);
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _logger.i('User signed out');
    } catch (e) {
      _logger.e('Error signing out', e);
      rethrow;
    }
  }
}