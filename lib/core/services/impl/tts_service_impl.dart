import 'package:flutter_tts/flutter_tts.dart';
import '../tts_service.dart';
import '../../utils/app_logger.dart';

class TtsServiceImpl implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    try {
      await _flutterTts.awaitSpeakCompletion(true); // Critical for Onboarding
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      _initialized = true;
      AppLogger.i('TTS', 'Initialized successfully');
    } catch (e) {
      AppLogger.e('TTS', 'Init error: $e');
    }
  }

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    await _init();
    try {
      await _flutterTts.stop();
      if (languageCode != null) {
        await _flutterTts.setLanguage(languageCode);
      } else {
        await _flutterTts.setLanguage("en-US");
      }
      AppLogger.i('TTS', 'Speaking: "$text"');
      await _flutterTts.speak(text);
    } catch (e) {
      AppLogger.e('TTS', 'Speak error: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
