// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../speech_input_service.dart';
import '../../utils/app_logger.dart';
import 'tts_service_impl.dart';

class SpeechInputServiceImpl implements SpeechInputService {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _isBusy = false;

  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    if (!_initialized) {
      try {
        _initialized = await _speech.initialize(
          onError: (e) {
            AppLogger.e('STT', 'Native Error: ${e.errorMsg}');
          },
          onStatus: (s) => AppLogger.i('STT', 'Status: $s'),
        );
      } catch (e) {
        AppLogger.e('STT', 'Init exception: $e');
        _initialized = false;
      }
    }
    return _initialized;
  }

  Future<void> _resetInstance() async {
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {}
    _speech = stt.SpeechToText();
    _initialized = false;
    await Future.delayed(const Duration(milliseconds: 600));
    await init();
  }

  // ONE-SHOT VOICE QUERY (With Session Lock & Timeout Fallback)
  @override
  Future<SpeechResult> listen() async {
    // Pause if TTS is currently speaking out loud
    if (TtsServiceImpl.isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (_isBusy) {
      AppLogger.w('STT', 'STT busy, waiting for lock...');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isBusy = true;
    final ok = await init();
    if (!ok) {
      _isBusy = false;
      return SpeechResult(text: '', confidence: 0.0, languageCode: 'en_IN');
    }

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 400));
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
      AppLogger.e('STT', 'Listen exception: $e');
      await _resetInstance();
      _isBusy = false;
      return SpeechResult(text: '', confidence: 0.0, languageCode: 'en_IN');
    }

    final result = await completer.future.timeout(
      const Duration(seconds: 9),
      onTimeout: () {
        return SpeechResult(text: latest, confidence: latest.isEmpty ? 0.0 : conf, languageCode: 'en_IN');
      },
    );

    try { if (_speech.isListening) await _speech.stop(); } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 300));
    _isBusy = false;

    AppLogger.i('STT', 'One-shot final captured: "${result.text}" (conf: ${result.confidence})');
    return result;
  }

  // CONTINUOUS CAPTION / WAKE STREAM
  Future<void> startCaptionStream({
    required Function(String partialText) onPartial,
    required Function(String finalText, double confidence) onFinal,
  }) async {
    _isBusy = false;
    if (TtsServiceImpl.isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    final ok = await init();
    if (!ok) return;

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
        listenFor: const Duration(hours: 1),
        pauseFor: const Duration(seconds: 30),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        localeId: 'en_IN',
      );
    } catch (e) {
      AppLogger.e('STT', 'Stream exception: $e');
      await _resetInstance();
    }
  }

  // CONTINUOUS STREAMING FOR WAKE WORD ("Hey Rook")
  Future<void> startContinuousStream(Function(String text, bool isFinal) onResult) async {
    if (TtsServiceImpl.isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    final ok = await init();
    if (!ok) return;

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 300));
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
      AppLogger.e('STT', 'Continuous stream exception: $e');
      await _resetInstance();
    }
  }

  @override
  Future<void> stop() async {
    try {
      _isBusy = false;
      if (_speech.isListening) await _speech.stop();
    } catch (_) {}
  }
}
