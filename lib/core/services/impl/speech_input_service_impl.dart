// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../speech_input_service.dart';
import '../../utils/app_logger.dart';

class SpeechInputServiceImpl implements SpeechInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _isListeningStream = false;

  bool get isListening => _speech.isListening || _isListeningStream;

  Future<bool> init() async {
    if (!_initialized) {
      _initialized = await _speech.initialize(
        onError: (e) => AppLogger.e('STT', 'Error: ${e.errorMsg}'),
        onStatus: (s) => AppLogger.i('STT', 'Status: $s'),
      );
    }
    return _initialized;
  }

  // ONE-SHOT (For Voice Q&A & Onboarding)
  @override
  Future<SpeechResult> listen() async {
    final ok = await init();
    if (!ok) return SpeechResult(text: '', confidence: 0.0, languageCode: 'en_IN');

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final completer = Completer<SpeechResult>();
    String latest = '';
    double conf = 0.85;

    try {
      await _speech.listen(
        onResult: (res) {
          latest = res.recognizedWords.trim();
          if (res.hasConfidenceRating && res.confidence > 0) conf = res.confidence;
          if (res.finalResult && !completer.isCompleted) {
            completer.complete(SpeechResult(text: latest, confidence: conf, languageCode: 'en_IN'));
          }
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_IN',
      );
    } catch (e) {
      AppLogger.e('STT', 'Listen error: $e');
      return SpeechResult(text: '', confidence: 0.0, languageCode: 'en_IN');
    }

    return completer.future.timeout(
      const Duration(seconds: 9),
      onTimeout: () {
        return SpeechResult(text: latest, confidence: latest.isEmpty ? 0.0 : conf, languageCode: 'en_IN');
      },
    ).whenComplete(() async {
      try { if (_speech.isListening) await _speech.stop(); } catch (_) {}
    });
  }

  // CONTINUOUS STREAMING FOR WAKE WORD ("Hey Rook")
  Future<void> startContinuousStream(Function(String text, bool isFinal) onResult) async {
    final ok = await init();
    if (!ok) return;

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    try {
      await _speech.listen(
        onResult: (res) => onResult(res.recognizedWords, res.finalResult),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        localeId: 'en_IN',
      );
    } catch (e) {
      AppLogger.e('STT', 'Stream error: $e');
    }
  }

  // STREAMING CAPTIONS (No system chime thrashing)
  Future<void> startCaptionStream({
    required Function(String partialText) onPartial,
    required Function(String finalText, double confidence) onFinal,
  }) async {
    final ok = await init();
    if (!ok) return;

    _isListeningStream = true;

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      await _speech.listen(
        onResult: (res) {
          final text = res.recognizedWords.trim();
          if (text.isEmpty) return;

          if (res.finalResult) {
            onFinal(text, res.confidence > 0 ? res.confidence : 0.85);
          } else {
            onPartial(text);
          }
        },
        listenFor: const Duration(minutes: 30),
        pauseFor: const Duration(seconds: 6),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        localeId: 'en_IN',
      );
    } catch (e) {
      AppLogger.e('STT', 'Caption stream error: $e');
    }
  }

  @override
  Future<void> stop() async {
    _isListeningStream = false;
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {}
  }
}
