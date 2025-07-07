import 'package:flutter/material.dart';

class VideoUrlInput extends StatelessWidget {
  final TextEditingController controller;
  
  const VideoUrlInput({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'YouTube URL',
        hintText: 'https://youtube.com/watch?v=...',
        prefixIcon: Icon(Icons.link),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.url,
    );
  }
}