import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final double strength;
  final String strengthText;
  final Color strengthColor;
  final bool hasMinLength;
  final bool hasLetterAndNumber;
  final bool hasSpecialChar;

  const PasswordStrengthIndicator({
    Key? key,
    required this.strength,
    required this.strengthText,
    required this.strengthColor,
    required this.hasMinLength,
    required this.hasLetterAndNumber,
    required this.hasSpecialChar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, thickness: 1),
        const SizedBox(height: 16),
        const Text(
          'Your password must have at least:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        _buildRequirement('8 characters (20 max)', hasMinLength),
        const SizedBox(height: 8),
        _buildRequirement('1 letter and 1 number', hasLetterAndNumber),
        const SizedBox(height: 8),
        _buildRequirement('1 special character (Example: # ? ! \$ & @)', hasSpecialChar),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: strength,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password strength:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirement(String requirement, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.check_circle_outline,
          color: isMet ? Colors.green : Colors.grey.shade400,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          requirement,
          style: TextStyle(
            color: isMet ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}