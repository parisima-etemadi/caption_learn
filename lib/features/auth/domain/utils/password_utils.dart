import 'dart:math';
import 'package:flutter/material.dart';

class PasswordStrength {
  final double score;
  final String text;
  final bool hasMinLength;
  final bool hasLetterAndNumber;
  final bool hasSpecialChar;
  final Color color;

  PasswordStrength({
    required this.score,
    required this.text,
    required this.color,
    required this.hasMinLength,
    required this.hasLetterAndNumber,
    required this.hasSpecialChar,
  });

  bool get isValid => hasMinLength && hasLetterAndNumber && hasSpecialChar;
}

class PasswordUtils {
  /// Generates a strong password that meets all requirements
  static String generateStrongPassword() {
    const String upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowerCase = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String specialChars = '!@#\$%^&*(),.?":{}|<>';
    
    final Random random = Random.secure();
    
    // Ensure at least one of each type of character
    String password = '';
    password += upperCase[random.nextInt(upperCase.length)];
    password += lowerCase[random.nextInt(lowerCase.length)];
    password += numbers[random.nextInt(numbers.length)];
    password += specialChars[random.nextInt(specialChars.length)];
    
    // Add more random characters
    const String allChars = upperCase + lowerCase + numbers + specialChars;
    final int remainingLength = 8 + random.nextInt(8); // Length between 8-16 chars
    
    for (int i = 0; i < remainingLength - 4; i++) {
      password += allChars[random.nextInt(allChars.length)];
    }
    
    // Shuffle the password characters
    List<String> passwordChars = password.split('');
    passwordChars.shuffle(random);
    return passwordChars.join('');
  }
  
  /// Evaluates password strength and returns a PasswordStrength object
  static PasswordStrength calculateStrength(String password) {
    // Check minimum 8 characters
    bool hasMinLength = password.length >= 8 && password.length <= 20;
    
    // Check for at least one letter and one number
    bool hasLetterAndNumber = RegExp(r'(?=.*[a-zA-Z])(?=.*[0-9])').hasMatch(password);
    
    // Check for at least one special character
    bool hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    
    // Calculate strength
    int strength = 0;
    if (hasMinLength) strength++;
    if (hasLetterAndNumber) strength++;
    if (hasSpecialChar) strength++;
    
    if (password.isEmpty) {
      return PasswordStrength(
        score: 0.0,
        text: '',
        color: Colors.grey.shade400,
        hasMinLength: hasMinLength,
        hasLetterAndNumber: hasLetterAndNumber,
        hasSpecialChar: hasSpecialChar,
      );
    } else if (strength == 1) {
      return PasswordStrength(
        score: 0.33,
        text: 'Weak',
        color: Colors.red,
        hasMinLength: hasMinLength,
        hasLetterAndNumber: hasLetterAndNumber, 
        hasSpecialChar: hasSpecialChar,
      );
    } else if (strength == 2) {
      return PasswordStrength(
        score: 0.66,
        text: 'Medium',
        color: Colors.orange,
        hasMinLength: hasMinLength,
        hasLetterAndNumber: hasLetterAndNumber,
        hasSpecialChar: hasSpecialChar,
      );
    } else {
      return PasswordStrength(
        score: 1.0,
        text: 'Strong',
        color: Colors.green,
        hasMinLength: hasMinLength,
        hasLetterAndNumber: hasLetterAndNumber,
        hasSpecialChar: hasSpecialChar,
      );
    }
  }
}