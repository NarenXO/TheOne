// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../speech_input_service.dart';
import '../../utils/app_logger.dart';

class SpeechInputServiceImpl implements SpeechInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _isProcessingError = false;

  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    if (!_initialized) {
      _initialized = await _speech.initialize(
        onError: (e) {
          AppLogger.e('STT', 'Error: ${e.errorMsg}');
          _isProcessingError = true;
        },
        onStatus: (s) => AppLogger.i('STT', 'Status: $s'),
      );
    }
    return _initialized;
  }

  @override
  Future<SpeechResult> listen() async {
    final ok = await init();
    if (!ok) return SpeechResult(text: '', confidence: 0.0, languageCode: 'en_IN');

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (_isProcessingError) {
      await Future.delayed(const Duration(milliseconds: 1000));
      _isProcessingError = false;
    }

    final completer = Completer<SpeechResult>();
    String latest = '';
    double conf = 0.0;

    try {
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
    } catch (e) {
      AppLogger.e('STT', 'Listen call error: $e');
      return SpeechResult(text: '', confidence: 0.0, languageCode: 'en_IN');
    }

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        AppLogger.w('STT', 'Timeout. captured: "$latest"');
        return SpeechResult(text: latest, confidence: latest.isEmpty ? 0.0 : 0.8, languageCode: 'en_IN');
      },
    ).whenComplete(() async {
      try { if (_speech.isListening) await _speech.stop(); } catch (_) {}
    });
  }

  Future<void> startContinuousStream(Function(String text, bool isFinal) onResult) async {
    final ok = await init();
    if (!ok) return;

    if (_isProcessingError) {
      await Future.delayed(const Duration(milliseconds: 1500));
      _isProcessingError = false;
    }

    try {
      if (_speech.isListening) await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 200));

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

  @override
  Future<void> stop() async {
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {}
  }
}
