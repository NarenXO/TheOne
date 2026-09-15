import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/services/tts_service.dart';

class CommunicationTtsService implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  double _speechRate = 0.5;
  double _pitch = 1.0;
  String _language = 'en-US';
  bool _isTamilAvailable = false;

  CommunicationTtsService() {
    _init();
  }

  Future<void> _init() async {
    await _flutterTts.setSharedInstance(true);
    await _flutterTts.awaitSpeakCompletion(true);
    
    // Check Tamil availability
    _isTamilAvailable = await _isLanguageAvailable('ta-IN');
    
    // Set default settings
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setLanguage(_language);
  }

  Future<bool> _isLanguageAvailable(String language) async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.contains(language);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    final language = languageCode ?? _language;
    
    // Check if trying to use Tamil when not available
    if (language == 'ta-IN' && !_isTamilAvailable) {
      // Fall back to English with a note
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.speak(text);
      return;
    }
    
    await _flutterTts.setLanguage(language);
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  // Settings methods
  Future<void> setSpeechRate(double rate) async {
    if (rate < 0.1) rate = 0.1;
    if (rate > 1.0) rate = 1.0;
    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await _flutterTts.setLanguage(language);
  }

  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get language => _language;
  bool get isTamilAvailable => _isTamilAvailable;

  Future<String> getTamilFallbackMessage() async {
    if (!_isTamilAvailable) {
      return 'Tamil TTS voice pack not installed on this device; defaulting to English TTS';
    }
    return '';
  }
}
