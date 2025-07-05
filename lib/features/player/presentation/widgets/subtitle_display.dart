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

    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;

    final backgroundColor = isLightTheme
        ? Colors.grey.shade200.withOpacity(0.9)
        : Colors.black.withOpacity(0.8);
    
    final textColor = isLightTheme ? Colors.black87 : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: backgroundColor,
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
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;
    final textColor = isLightTheme ? Colors.black87 : Colors.white;
    final highlightColor = theme.colorScheme.secondary;


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
        style: TextStyle(
          fontSize: 24,
          color: textColor,
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: 0.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? highlightColor.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  word.text,
                  style: TextStyle(
                    fontSize: 24,
                    color: textColor,
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
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