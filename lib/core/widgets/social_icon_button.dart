import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// A button widget for social media icons with consistent styling
///
/// This widget creates a circular button with an icon that can be used
/// for social sign-in buttons like Google, Apple, Facebook, etc.
class SocialIconButton extends StatelessWidget {
  /// The icon to display
  final Widget icon;

  /// The callback function when the button is pressed
  final VoidCallback? onPressed;

  /// The background color of the button
  final Color backgroundColor;

  /// The button size (diameter)
  final double buttonSize;

  /// Whether the button is in a loading or disabled state
  final bool isLoading;

  const SocialIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.white,
    this.buttonSize = 48.0,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          elevation: 2,
        ),
        child:
            isLoading
                ? SizedBox(
                  width: buttonSize * 0.5,
                  height: buttonSize * 0.5,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
                : icon,
      ),
    );
  }

  /// Factory constructor for creating a Google sign-in button
  factory SocialIconButton.google({
    required VoidCallback onPressed,
    bool isLoading = false,
    double buttonSize = 48.0,
  }) {
    return SocialIconButton(
      icon: SvgPicture.asset(
        'assets/icons/google_logo.svg',
        width: 20,
        height: 20,
      ),
      onPressed: onPressed,
      backgroundColor: Colors.white,
      isLoading: isLoading,
      buttonSize: buttonSize,
    );
  }

  /// Factory constructor for creating an Apple sign-in button
  factory SocialIconButton.apple({
    required VoidCallback onPressed,
    bool isLoading = false,
    double buttonSize = 48.0,
  }) {
    return SocialIconButton(
      icon: SvgPicture.asset('assets/icons/apple_logo.svg'),
      onPressed: onPressed,
      backgroundColor: Colors.white,
      isLoading: isLoading,
      buttonSize: buttonSize,
    );
  }
}
