part of 'auth_bloc.dart';

@immutable
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state when app starts
class AuthInitial extends AuthState {}

// When checking authentication status
class AuthCheckingStatus extends AuthState {}

// When authenticated
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object> get props => [user];
}

// When not authenticated
class Unauthenticated extends AuthState {}

// When authenticating
class Authenticating extends AuthState {}

// When authentication fails
class AuthenticationFailure extends AuthState {
  final String message;

  const AuthenticationFailure(this.message);

  @override
  List<Object> get props => [message];
}

// When registration succeeds
class RegistrationSuccess extends AuthState {}

// When registration fails
class RegistrationFailure extends AuthState {
  final String message;

  const RegistrationFailure(this.message);

  @override
  List<Object> get props => [message];
}