class AuthValidators {
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    
    // Simple phone validation
    final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validatePassword(String? value, {
    required bool hasMinLength,
    required bool hasLetterAndNumber,
    required bool hasSpecialChar,
  }) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (!hasMinLength) {
      return 'Password must be 8-20 characters';
    }
    if (!hasLetterAndNumber) {
      return 'Password must contain at least 1 letter and 1 number';
    }
    if (!hasSpecialChar) {
      return 'Password must contain at least 1 special character';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}