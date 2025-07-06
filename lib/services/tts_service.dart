import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService {
  late FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;

  TtsService() {
    flutterTts = FlutterTts();
    _setAwaitOptions();
    _setHandlers();
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  void _setHandlers() {
    flutterTts.setStartHandler(() {
      debugPrint("TTS: Playing");
      ttsState = TtsState.playing;
    });

    flutterTts.setCompletionHandler(() {
      debugPrint("TTS: Complete");
      ttsState = TtsState.stopped;
    });

    flutterTts.setCancelHandler(() {
      debugPrint("TTS: Cancel");
      ttsState = TtsState.stopped;
    });

    flutterTts.setErrorHandler((msg) {
      debugPrint("TTS: Error: $msg");
      ttsState = TtsState.stopped;
    });
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    var result = await flutterTts.stop();
    if (result == 1) {
      ttsState = TtsState.stopped;
    }
  }

  void dispose() {
    flutterTts.stop();
  }
} 