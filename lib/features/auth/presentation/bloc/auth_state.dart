part of 'auth_bloc.dart';

/// Simplified auth state using sealed classes pattern
class AuthState extends Equatable {
  final User? user;
  final bool isLoading;
  final String? error;
  final String? verificationId;
  final String? phoneNumber;

  const AuthState._({
    this.user,
    this.isLoading = false,
    this.error,
    this.verificationId,
    this.phoneNumber,
  });

  // Named constructors for different states
  const AuthState.initial() : this._();
  const AuthState.loading() : this._(isLoading: true);
  const AuthState.authenticated(User user) : this._(user: user);
  const AuthState.unauthenticated() : this._();
  const AuthState.failure(String error) : this._(error: error);
  const AuthState.phoneCodeSent(String verificationId, String phoneNumber) 
      : this._(verificationId: verificationId, phoneNumber: phoneNumber);

  // Getters for convenience
  bool get isAuthenticated => user != null;
  bool get hasError => error != null;
  bool get isPhoneCodeSent => verificationId != null;

  @override
  List<Object?> get props => [user?.uid, isLoading, error, verificationId, phoneNumber];

  @override
  String toString() {
    if (isLoading) return 'AuthState.loading';
    if (isAuthenticated) return 'AuthState.authenticated(${user!.uid})';
    if (hasError) return 'AuthState.failure($error)';
    if (isPhoneCodeSent) return 'AuthState.phoneCodeSent($phoneNumber)';
    return 'AuthState.unauthenticated';
  }
}