// lib/features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// When the app starts, check authentication state
class AuthCheckRequested extends AuthEvent {}

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

// Phone verification - sending code to phone
class SendPhoneCodeEvent extends AuthEvent {
  final String phoneNumber;
  
  const SendPhoneCodeEvent({
    required this.phoneNumber,
  });
  
  @override
  List<Object> get props => [phoneNumber];
}

// Verify the SMS code entered by user
class VerifyPhoneCodeEvent extends AuthEvent {
  final String smsCode;
  final String? verificationId;
  
  const VerifyPhoneCodeEvent({
    required this.smsCode,
    this.verificationId,
  });
  
  @override
  List<Object?> get props => [smsCode, verificationId];
}