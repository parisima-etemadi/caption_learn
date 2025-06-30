import 'package:flutter/material.dart';

/// Common gradient background for authentication screens
class AuthBackground extends StatelessWidget {
  final Widget child;
  
  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8F9FA), Color(0xFFE8EAF6)],
        ),
      ),
      child: child,
    );
  }
}