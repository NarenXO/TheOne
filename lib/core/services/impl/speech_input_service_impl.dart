import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../speech_input_service.dart';

class SpeechInputServiceImpl implements SpeechInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (val) {},
        onStatus: (val) {},
      );
    }
    return _isInitialized;
  }

  @override
  Future<SpeechResult> listen() async {
    final ready = await init();
    if (!ready) {
      return SpeechResult(text: "", confidence: 0.0, languageCode: "en");
    }

    String recognizedText = "";
    double speechConfidence = 0.85;

    await _speech.listen(
      onResult: (result) {
        recognizedText = result.recognizedWords;
        if (result.confidence > 0) {
          speechConfidence = result.confidence;
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 6),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: "en_IN",
      ),
    );

    // Wait for listening to complete active speech
    int checks = 0;
    while (_speech.isListening && checks < 30) {
      await Future.delayed(const Duration(milliseconds: 200));
      checks++;
    }

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
