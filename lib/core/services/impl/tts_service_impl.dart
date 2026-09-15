import 'package:flutter_tts/flutter_tts.dart';
import '../tts_service.dart';

class TtsServiceImpl implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _initialized = true;
    } catch (e) {
      // Graceful fallback
    }
  }

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    await _init();
    try {
      if (languageCode != null) {
        await _flutterTts.setLanguage(languageCode);
      }
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
