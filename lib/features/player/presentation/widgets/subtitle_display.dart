import 'package:caption_learn/features/video/data/models/video_content.dart';
import 'package:flutter/material.dart';

class SubtitleDisplay extends StatelessWidget {
  final Subtitle? currentSubtitle;
  final Function(String) onWordTap;
  final int currentPositionMs;

  const SubtitleDisplay({
    Key? key,
    required this.currentSubtitle,
    required this.onWordTap,
    required this.currentPositionMs,
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
          _buildTappableSubtitle(context),
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

  Widget _buildTappableSubtitle(BuildContext context) {
    final timedWords = currentSubtitle!.words;
    if (timedWords.isEmpty) {
      return Text(
        currentSubtitle!.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        children: timedWords.expand((word) {
          final isHighlighted = currentPositionMs >= word.startTime &&
              currentPositionMs < word.endTime;
          final cleanWord = word.text.replaceAll(RegExp(r'[^\w\s]'), '');

          final span = WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => onWordTap(cleanWord.isEmpty ? word.text : cleanWord),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.blueAccent.withOpacity(0.7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  word.text,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );

          return [span, const TextSpan(text: ' ')];
        }).toList()..removeLast(),
      ),
    );
  }
} 