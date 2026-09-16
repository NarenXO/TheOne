// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../speech_input_service.dart';
import '../../utils/app_logger.dart';

class SpeechInputServiceImpl implements SpeechInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    if (!_initialized) {
      _initialized = await _speech.initialize(
        onError: (e) => AppLogger.e('STT', 'Error: $e'),
        onStatus: (s) => AppLogger.i('STT', 'Status: $s'),
      );
    }
    return _initialized;
  }

  // ONE-SHOT (For Voice Q&A / Onboarding)
  @override
  Future<SpeechResult> listen() async {
    final ok = await init();
    if (!ok) return SpeechResult(text: '', confidence: 0.0, languageCode: 'en_IN');

    if (_speech.isListening) await _speech.stop();

    final completer = Completer<SpeechResult>();
    String latest = '';
    double conf = 0.0;

    await _speech.listen(
      onResult: (res) {
        latest = res.recognizedWords.trim();
        if (res.hasConfidenceRating && res.confidence > 0) conf = res.confidence;
        if (res.finalResult && !completer.isCompleted) {
          completer.complete(SpeechResult(text: latest, confidence: conf > 0 ? conf : 0.85, languageCode: 'en_IN'));
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_IN',
    );

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        AppLogger.w('STT', 'One-shot timeout. Using partial: "$latest"');
        return SpeechResult(text: latest, confidence: latest.isEmpty ? 0.0 : 0.8, languageCode: 'en_IN');
      },
    ).whenComplete(() => _speech.stop());
  }

  // CONTINUOUS STREAM (For Captions & Hey Rook)
  Future<void> startContinuousStream(Function(String text, bool isFinal) onResult) async {
    final ok = await init();
    if (!ok) return;

    if (_speech.isListening) await _speech.stop();

    await _speech.listen(
      onResult: (res) => onResult(res.recognizedWords, res.finalResult),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.dictation,
      localeId: 'en_IN',
    );
  }

  @override
  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }
}
