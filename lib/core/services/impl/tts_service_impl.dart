import 'package:flutter_tts/flutter_tts.dart';
import '../../utils/app_logger.dart';
import '../tts_service.dart';

class TtsServiceImpl implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  TtsServiceImpl() {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      _initialized = true;
    } catch (_) {}
  }

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    try {
      await _init();
      AppLogger.i('TTS', 'Speaking out loud: "$text"');
      await _flutterTts.stop();
      if (languageCode != null) {
        await _flutterTts.setLanguage(languageCode);
      } else {
        await _flutterTts.setLanguage("en-US");
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
