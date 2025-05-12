import 'package:firebase_auth/firebase_auth.dart';


class FirebaseAuthErrorMapper {

  static String mapErrorToMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _mapFirebaseAuthExceptionToMessage(error);
    }
    
    return 'Authentication failed. Please try again.';
  }
  static String _mapFirebaseAuthExceptionToMessage(FirebaseAuthException exception) {
    // Map of error codes to user-friendly messages
    final errorMessages = {
      // Account existence errors
      'user-not-found': 'No user found with this email.',
      'user-disabled': 'This user account has been disabled.',
      'email-already-in-use': 'An account already exists with this email.',
      
      // Password errors
      'wrong-password': 'Incorrect password.',
      'weak-password': 'The password is too weak.',
      
      // Validation errors
      'invalid-email': 'The email address is invalid.',
      'invalid-credential': 'The credential is invalid.',
      
      // Permission errors
      'operation-not-allowed': 'This operation is not allowed.',
      'requires-recent-login': 'This operation requires re-authentication.',
      
      // Credential errors
      'account-exists-with-different-credential': 
          'An account already exists with the same email but different sign-in credentials.',
      'credential-already-in-use': 'This credential is already associated with a different user account.',
      'provider-already-linked': 'This provider is already linked to your account.',
      
      // Network and rate limiting errors
      'network-request-failed': 'A network error occurred. Please check your connection.',
      'too-many-requests': 'Too many unsuccessful login attempts. Please try again later.',
      
      // Social sign-in specific errors
      'popup-blocked': 'The authentication popup was blocked by your browser.',
      'popup-closed-by-user': 'The authentication popup was closed before completing the sign-in.',
    };
    
    // Return the mapped message or a default message with the exception message if available
    return errorMessages[exception.code] ?? 
      'Authentication failed: ${exception.message ?? "Unknown error"}';
  }
}