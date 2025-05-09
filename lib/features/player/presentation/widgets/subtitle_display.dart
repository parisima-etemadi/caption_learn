import 'package:caption_learn/features/video/data/models/video_content.dart';
import 'package:flutter/material.dart';

class SubtitleDisplay extends StatelessWidget {
  final Subtitle subtitle;
  final bool isHighlighted;
  final Function(String) onWordTap;

  const SubtitleDisplay({
    Key? key,
    required this.subtitle,
    required this.isHighlighted,
    required this.onWordTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildTappableText(context, subtitle.text, isHighlighted);
  }

  Widget buildTappableText(BuildContext context, String text, bool isHighlighted) {
    final words = text.split(' ');
    
    return Wrap(
      spacing: 4,
      children: words.map((word) {
        final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
        
        if (cleanWord.isEmpty) {
          return Text(
            word,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }
        
        return InkWell(
          onTap: () => onWordTap(cleanWord),
          borderRadius: BorderRadius.circular(4),
          child: Text(
            word,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
} 