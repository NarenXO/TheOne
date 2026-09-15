import 'package:flutter_tts/flutter_tts.dart';
import '../../utils/app_logger.dart';
import '../tts_service.dart';

class TtsServiceImpl implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsServiceImpl() {
    _init();
  }

  void _init() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (_) {}
  }

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    try {
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
