import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../speech_input_service.dart';

class SpeechInputServiceImpl implements SpeechInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> init() async {
    if (!_isAvailable) {
      _isAvailable = await _speech.initialize();
    }
    return _isAvailable;
  }

  @override
  Future<SpeechResult> listen() async {
    final ready = await init();
    if (!ready) {
      return SpeechResult(text: "", confidence: 0.0, languageCode: "en");
    }

    String recognizedText = "";
    double speechConfidence = 0.0;

    await _speech.listen(
      onResult: (result) {
        recognizedText = result.recognizedWords;
        speechConfidence = result.confidence > 0 ? result.confidence : 0.85;
      },
    );

    // Give a short window for speech capture
    await Future.delayed(const Duration(seconds: 4));
    await _speech.stop();

    return SpeechResult(
      text: recognizedText,
      confidence: speechConfidence,
      languageCode: "en_IN",
    );
  }

  @override
  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
