import 'package:flutter/material.dart';
import 'package:caption_learn/core/widgets/social_icon_button.dart';

class SocialLoginSection extends StatelessWidget {
  final bool isLoading;
  final String dividerText;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;

  const SocialLoginSection({
    Key? key,
    required this.isLoading,
    required this.dividerText,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDivider(),
        const SizedBox(height: 24),
        _buildButtons(),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey.shade400,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            dividerText,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey.shade400,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SocialIconButton.google(
          onPressed: onGoogleSignIn,
          isLoading: isLoading,
        ),
        const SizedBox(width: 24),
        SocialIconButton.apple(
          onPressed: onAppleSignIn,
          isLoading: isLoading,
        ),
      ],
    );
  }
}