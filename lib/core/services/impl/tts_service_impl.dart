import 'package:flutter_tts/flutter_tts.dart';
import '../tts_service.dart';
import '../../utils/app_logger.dart';

class TtsServiceImpl implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  static bool isSpeaking = false;

  Future<void> _init() async {
    if (_initialized) return;
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        isSpeaking = true;
        AppLogger.i('TTS', 'Playback started');
      });

      _flutterTts.setCompletionHandler(() {
        isSpeaking = false;
        AppLogger.i('TTS', 'Playback completed');
      });

      _flutterTts.setErrorHandler((msg) {
        isSpeaking = false;
        AppLogger.e('TTS', 'Playback error: $msg');
      });

      _initialized = true;
    } catch (e) {
      AppLogger.e('TTS', 'Init error: $e');
    }
  }

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    await _init();
    try {
      isSpeaking = true;
      await _flutterTts.stop();
      if (languageCode != null) {
        await _flutterTts.setLanguage(languageCode);
      } else {
        await _flutterTts.setLanguage("en-US");
      }
      AppLogger.i('TTS', 'Speaking: "$text"');
      await _flutterTts.speak(text);
    } catch (e) {
      isSpeaking = false;
      AppLogger.e('TTS', 'Speak exception: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      isSpeaking = false;
      await _flutterTts.stop();
    } catch (_) {}
  }
}
