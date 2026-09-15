import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../utils/app_logger.dart';
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

    AppLogger.i('STT', 'Listening for microphone speech input...');

    String recognizedText = "";
    double speechConfidence = 0.85;

    await _speech.listen(
      onResult: (result) {
        recognizedText = result.recognizedWords;
        if (result.hasConfidenceRating && result.confidence > 0) {
          speechConfidence = result.confidence;
        } else if (recognizedText.isNotEmpty) {
          speechConfidence = 0.88;
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        cancelOnError: false,
        localeId: 'en_IN',
      ),
    );

    // wait until not listening, max 15s
    final start = DateTime.now();
    while (_speech.isListening && DateTime.now().difference(start).inSeconds < 15) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    await _speech.stop();

    AppLogger.i('STT', 'Captured speech: "$recognizedText" (conf: $speechConfidence)');

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
