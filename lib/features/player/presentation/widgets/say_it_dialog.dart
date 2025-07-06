import 'dart:async';
import 'package:caption_learn/services/speech_service.dart';
import 'package:caption_learn/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';

class SayItDialog extends StatefulWidget {
  final String correctText;
  final SpeechService speechService;
  final TtsService ttsService;

  const SayItDialog({
    Key? key,
    required this.correctText,
    required this.speechService,
    required this.ttsService,
  }) : super(key: key);

  @override
  _SayItDialogState createState() => _SayItDialogState();
}

class _SayItDialogState extends State<SayItDialog> {
  @override
  void initState() {
    super.initState();
    // Start listening as soon as the dialog opens
    widget.speechService.startListening();
  }

  @override
  void dispose() {
    // Ensure we stop listening and speaking if the dialog is closed prematurely
    widget.speechService.stopListening();
    widget.ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: ValueListenableBuilder<SpeechStatus>(
        valueListenable: widget.speechService.statusNotifier,
        builder: (context, status, _) {
          switch (status) {
            case SpeechStatus.listening:
              return _buildListeningUI();
            case SpeechStatus.done:
            case SpeechStatus.notListening:
              return _buildResultUI();
            case SpeechStatus.unavailable:
              return _buildErrorUI("Speech recognition is not available.");
            case SpeechStatus.error:
              return _buildErrorUI("An error occurred.");
          }
        },
      ),
    );
  }

  Widget _buildListeningUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Listening...", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        ValueListenableBuilder<String>(
          valueListenable: widget.speechService.recognizedWordsNotifier,
          builder: (context, recognizedText, _) {
            return Text(
              recognizedText,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            );
          },
        ),
      ],
    );
  }

  Widget _buildResultUI() {
    final recognizedText = widget.speechService.recognizedWordsNotifier.value;
    final similarity = recognizedText.similarityTo(widget.correctText);
    final score = (similarity * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const Icon(Icons.mic_rounded, size: 60, color: Colors.blueAccent),
        const SizedBox(height: 16),
        const Text("Let's Check", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          "You scored $score/100",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 24),
        IconButton(
          icon: const Icon(Icons.play_circle_fill_rounded, size: 50),
          color: Colors.pinkAccent,
          onPressed: () {
            widget.ttsService.speak(widget.correctText);
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () {
            widget.speechService.startListening();
          },
          child: const Text("Say it Again", style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildErrorUI(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 50),
        const SizedBox(height: 20),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        ElevatedButton(
          child: const Text("Close"),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
} 