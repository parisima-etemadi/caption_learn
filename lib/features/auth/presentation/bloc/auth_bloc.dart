import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/state/auth_state_manager.dart';
import '../../../../core/exceptions/app_exceptions.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Simplified auth bloc using AuthStateManager
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthStateManager _authManager = AuthStateManager();
  late StreamSubscription<AuthenticationState> _authStateSubscription;
  late StreamSubscription<bool> _loadingSubscription;

  AuthBloc() : super(const AuthState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogle);
    on<SignInWithAppleRequested>(_onSignInWithApple);
    on<SignOutRequested>(_onSignOut);
    on<_AuthStateChanged>(_onAuthStateChanged);
    on<_LoadingStateChanged>(_onLoadingStateChanged);
    on<SendPhoneCodeEvent>(_onSendPhoneCode);
    on<VerifyPhoneCodeEvent>(_onVerifyPhoneCode);

    // Listen to auth state changes
    _authStateSubscription = _authManager.authState.listen(
      (authState) => add(_AuthStateChanged(authState)),
    );
    
    // Listen to loading state changes
    _loadingSubscription = _authManager.isLoading.listen(
      (isLoading) => add(_LoadingStateChanged(isLoading)),
    );
  }

  void _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) {
    // AuthStateManager handles this automatically
  }

  Future<void> _onSignInWithGoogle(SignInWithGoogleRequested event, Emitter<AuthState> emit) async {
    try {
      await _authManager.signInWithGoogle();
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    }
  }

  Future<void> _onSignInWithApple(SignInWithAppleRequested event, Emitter<AuthState> emit) async {
    try {
      await _authManager.signInWithApple();
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    }
  }

  Future<void> _onSignOut(SignOutRequested event, Emitter<AuthState> emit) async {
    try {
      await _authManager.signOut();
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    }
  }

  void _onAuthStateChanged(_AuthStateChanged event, Emitter<AuthState> emit) {
    if (event.authState.isAuthenticated) {
      emit(AuthState.authenticated(event.authState.user!));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }
  
  void _onLoadingStateChanged(_LoadingStateChanged event, Emitter<AuthState> emit) {
    if (event.isLoading) {
      emit(const AuthState.loading());
    }
  }

  Future<void> _onSendPhoneCode(SendPhoneCodeEvent event, Emitter<AuthState> emit) async {
    try {
      await _authManager.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        onCodeSent: (verificationId) {
          if (!emit.isDone) {
            emit(AuthState.phoneCodeSent(verificationId, event.phoneNumber));
          }
        },
        onError: (error) {
          if (!emit.isDone) {
            emit(AuthState.failure(error));
          }
        },
      );
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    }
  }

  Future<void> _onVerifyPhoneCode(VerifyPhoneCodeEvent event, Emitter<AuthState> emit) async {
    try {
      await _authManager.verifyPhoneCode(event.smsCode, event.verificationId);
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    _loadingSubscription.cancel();
    _authManager.dispose();
    return super.close();
  }
}