import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../core/utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final Logger _logger = const Logger('AuthProvider');
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  
  AuthProvider() {
    _init();
  }
  
  void _init() {
    _user = _authService.currentUser;
    
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }
  
  Future<void> signInWithEmailPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signInWithEmailPassword(email, password);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> createAccount(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.createAccount(email, password);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> signInWithApple() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signInWithApple();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    _logger.e('Auth error: $_error');
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}