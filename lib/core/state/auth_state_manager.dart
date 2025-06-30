import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/base_service.dart';
import '../exceptions/app_exceptions.dart';
import '../../services/auth_service.dart';

/// Simplified authentication state management
class AuthStateManager extends BaseService {
  static final AuthStateManager _instance = AuthStateManager._internal();
  final AuthService _authService = AuthService();
  
  // Stream controllers for state
  final StreamController<AuthenticationState> _stateController = 
      StreamController<AuthenticationState>.broadcast();
  final StreamController<bool> _loadingController = 
      StreamController<bool>.broadcast();
  
  @override
  String get serviceName => 'AuthStateManager';
  
  factory AuthStateManager() => _instance;
  AuthStateManager._internal() {
    _initializeAuthListener();
  }
  
  // State getters
  Stream<AuthenticationState> get authState => _stateController.stream;
  Stream<bool> get isLoading => _loadingController.stream;
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  /// Initialize authentication state listener
  void _initializeAuthListener() {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _stateController.add(AuthenticationState.authenticated(user));
        logger.i('User authenticated: ${user.uid}');
      } else {
        _stateController.add(const AuthenticationState.unauthenticated());
        logger.i('User unauthenticated');
      }
    });
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _loadingController.add(loading);
  }
  
  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      await _authService.signInWithGoogle();
    } on Exception catch (e) {
      logger.e('Google sign in failed', e);
      throw AuthException('Google sign in failed: ${e.toString()}', originalError: e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Sign in with Apple
  Future<void> signInWithApple() async {
    try {
      _setLoading(true);
      await _authService.signInWithApple();
    } on Exception catch (e) {
      logger.e('Apple sign in failed', e);
      throw AuthException('Apple sign in failed: ${e.toString()}', originalError: e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Start phone verification
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      _setLoading(true);
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          _setLoading(false);
          onCodeSent(verificationId);
        },
        onVerificationFailed: (error) {
          _setLoading(false);
          onError(error.message ?? 'Phone verification failed');
        },
        onVerificationCompleted: (credential) async {
          try {
            await _authService.signInWithCredential(credential);
          } catch (e) {
            onError('Auto verification failed');
          } finally {
            _setLoading(false);
          }
        },
      );
    } catch (e) {
      _setLoading(false);
      logger.e('Phone verification failed', e);
      throw AuthException('Phone verification failed: ${e.toString()}', originalError: e);
    }
  }
  
  /// Complete phone verification with SMS code
  Future<void> verifyPhoneCode(String smsCode, [String? verificationId]) async {
    try {
      _setLoading(true);
      await _authService.signInWithPhoneCode(smsCode, verificationId);
    } on Exception catch (e) {
      logger.e('Phone code verification failed', e);
      throw AuthException('Invalid verification code', originalError: e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
    } on Exception catch (e) {
      logger.e('Sign out failed', e);
      throw AuthException('Sign out failed: ${e.toString()}', originalError: e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Dispose resources
  void dispose() {
    _stateController.close();
    _loadingController.close();
    logger.i('AuthStateManager disposed');
  }
}

/// Authentication state model
class AuthenticationState {
  final User? user;
  final bool isAuthenticated;
  
  const AuthenticationState._(this.user, this.isAuthenticated);
  
  const AuthenticationState.authenticated(User user) : this._(user, true);
  const AuthenticationState.unauthenticated() : this._(null, false);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthenticationState &&
          runtimeType == other.runtimeType &&
          user?.uid == other.user?.uid &&
          isAuthenticated == other.isAuthenticated;
  
  @override
  int get hashCode => user?.uid.hashCode ?? 0;
}