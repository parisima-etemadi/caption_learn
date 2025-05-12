import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:caption_learn/core/utils/error_handler.dart';
import 'package:caption_learn/services/auth_service.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final ErrorHandler _errorHandler = ErrorHandler('AuthBloc');
  late StreamSubscription<User?> _authStateSubscription;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithEmailPasswordRequested>(_onSignInWithEmailPasswordRequested);
    on<SignUpWithEmailPasswordRequested>(_onSignUpWithEmailPasswordRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Listen to authentication state changes
    _authStateSubscription = _authService.authStateChanges.listen(
      (user) => add(AuthStateChanged(user)),
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthCheckingStatus());
    final user = _authService.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInWithEmailPasswordRequested(
    SignInWithEmailPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(Authenticating());
    try {
      await _authService.signInWithEmailPassword(
        event.email,
        event.password,
      );
      // The AuthStateChanged event will handle the state update
    } catch (e) {
      emit(AuthenticationFailure(_errorHandler.handleAuthError(e)));
    }
  }

  Future<void> _onSignUpWithEmailPasswordRequested(
    SignUpWithEmailPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(Authenticating());
    try {
      await _authService.createAccount(
        event.email,
        event.password,
      );
      emit(RegistrationSuccess());
      // The AuthStateChanged event will handle the state update
    } catch (e) {
      emit(RegistrationFailure(_errorHandler.handleAuthError(e)));
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(Authenticating());
    try {
      await _authService.signInWithGoogle();
      // The AuthStateChanged event will handle the state update
    } catch (e) {
      emit(AuthenticationFailure(_errorHandler.handleAuthError(e)));
    }
  }

  Future<void> _onSignInWithAppleRequested(
    SignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(Authenticating());
    try {
      await _authService.signInWithApple();
      // The AuthStateChanged event will handle the state update
    } catch (e) {
      emit(AuthenticationFailure(_errorHandler.handleAuthError(e)));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.signOut();
      // The AuthStateChanged event will handle the state update
    } catch (e) {
      // Even if sign out fails, we should show the user as unauthenticated
      emit(Unauthenticated());
    }
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(Authenticated(event.user!));
    } else {
      emit(Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}