part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// When the app starts, check authentication state
class AuthCheckRequested extends AuthEvent {}

// User tries to login with email & password
class SignInWithEmailPasswordRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailPasswordRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

// User tries to register with email & password
class SignUpWithEmailPasswordRequested extends AuthEvent {
  final String email;
  final String password;

  const SignUpWithEmailPasswordRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

// User tries to sign in with Google
class SignInWithGoogleRequested extends AuthEvent {}

// User tries to sign in with Apple
class SignInWithAppleRequested extends AuthEvent {}

// When user signs out
class SignOutRequested extends AuthEvent {}

// When authentication state changes from Firebase
class AuthStateChanged extends AuthEvent {
  final User? user;

  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}