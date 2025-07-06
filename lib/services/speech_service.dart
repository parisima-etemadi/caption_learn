import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

enum SpeechStatus {
  notListening,
  listening,
  done,
  unavailable,
  error,
}

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  final ValueNotifier<SpeechStatus> statusNotifier =
      ValueNotifier(SpeechStatus.notListening);

  final ValueNotifier<String> recognizedWordsNotifier = ValueNotifier('');

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          statusNotifier.value = SpeechStatus.error;
          debugPrint('Speech recognition error: $error');
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done') {
            statusNotifier.value = SpeechStatus.done;
          } else if (status == 'notListening') {
            statusNotifier.value = SpeechStatus.notListening;
          }
        },
      );

      if (!_isInitialized) {
        statusNotifier.value = SpeechStatus.unavailable;
      }
    } catch (e) {
      statusNotifier.value = SpeechStatus.error;
      debugPrint('Error initializing speech recognition: $e');
    }
  }

  void startListening() {
    if (!_isInitialized || _speechToText.isListening) return;

    recognizedWordsNotifier.value = '';
    statusNotifier.value = SpeechStatus.listening;

    _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        recognizedWordsNotifier.value = result.recognizedWords;
        if (result.finalResult) {
          statusNotifier.value = SpeechStatus.done;
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void stopListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
      statusNotifier.value = SpeechStatus.notListening;
    }
  }

  void cancelListening() {
    if (_speechToText.isListening) {
      _speechToText.cancel();
      statusNotifier.value = SpeechStatus.notListening;
    }
  }

  void dispose() {
    statusNotifier.dispose();
    recognizedWordsNotifier.dispose();
  }
} 