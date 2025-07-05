import 'package:caption_learn/features/video/data/models/video_content.dart';
import 'package:flutter/material.dart';

class SubtitleDisplay extends StatelessWidget {
  final Subtitle? currentSubtitle;
  final Function(String) onWordTap;

  const SubtitleDisplay({
    Key? key,
    required this.currentSubtitle,
    required this.onWordTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentSubtitle == null) {
      return const SizedBox(height: 80); // Placeholder when no subtitle
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black.withOpacity(0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTappableSubtitle(context, currentSubtitle!.text),
          if (currentSubtitle!.translation != null &&
              currentSubtitle!.translation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              currentSubtitle!.translation!, // Display the translation
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[300],
                fontWeight: FontWeight.w500,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTappableSubtitle(BuildContext context, String text) {
    final words = text.split(' ');
    
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        children: words.map((word) {
          final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
          
          if (cleanWord.isEmpty) {
            return TextSpan(text: '$word ');
          }
          
          return WidgetSpan(
            child: GestureDetector(
              onTap: () => onWordTap(cleanWord),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: Colors.transparent, // No highlight by default
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
} 