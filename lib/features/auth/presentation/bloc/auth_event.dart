part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

// Public events
class AuthCheckRequested extends AuthEvent {}
class SignInWithGoogleRequested extends AuthEvent {}
class SignInWithAppleRequested extends AuthEvent {}
class SignOutRequested extends AuthEvent {}

class SendPhoneCodeEvent extends AuthEvent {
  final String phoneNumber;
  const SendPhoneCodeEvent(this.phoneNumber);
  @override
  List<Object> get props => [phoneNumber];
}

class VerifyPhoneCodeEvent extends AuthEvent {
  final String smsCode;
  final String verificationId;
  const VerifyPhoneCodeEvent(this.smsCode, this.verificationId);
  @override
  List<Object> get props => [smsCode, verificationId];
}

// Internal events
class _AuthStateChanged extends AuthEvent {
  final AuthenticationState authState;
  const _AuthStateChanged(this.authState);
  @override
  List<Object> get props => [authState];
}

class _LoadingStateChanged extends AuthEvent {
  final bool isLoading;
  const _LoadingStateChanged(this.isLoading);
  @override
  List<Object> get props => [isLoading];
}