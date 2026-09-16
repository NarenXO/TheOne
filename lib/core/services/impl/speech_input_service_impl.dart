// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../speech_input_service.dart';
import '../../utils/app_logger.dart';
import 'tts_service_impl.dart';

class SpeechInputServiceImpl implements SpeechInputService {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _isBusy = false;
  Function(String status)? _onStatusListener;

  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      AppLogger.e('STT', 'Microphone permission not granted');
      return false;
    }

    if (!_initialized) {
      try {
        _initialized = await _speech.initialize(
          onError: (e) {
            AppLogger.e('STT', 'Native Error: ${e.errorMsg} (${e.permanent})');
            _isBusy = false;
            final msg = e.errorMsg.toLowerCase();
            if (msg.contains('error_client') || msg.contains('error_audio') || msg.contains('5') || msg.contains('3')) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _resetInstance();
              });
            }
          },
          onStatus: (s) {
            AppLogger.i('STT', 'Status: $s');
            if (s == 'done' || s == 'notListening') {
              _isBusy = false;
            }
            _onStatusListener?.call(s);
          },
        );
      } catch (e) {
        AppLogger.e('STT', 'Init exception: $e');
        _initialized = false;
        _isBusy = false;
      }
    }
    return _initialized;
  }

  Future<void> _resetInstance() async {
    try {
      if (_speech.isListening) await _speech.stop();
      await _speech.cancel();
    } catch (_) {}
    _speech = stt.SpeechToText();
    _initialized = false;
    _isBusy = false;
    await Future.delayed(const Duration(milliseconds: 500));
    await init();
  }

  // ONE-SHOT VOICE QUERY (With Session Lock & Timeout Fallback)
  @override
  Future<SpeechResult> listen() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return SpeechResult(text: '', confidence: 0.0, languageCode: 'en_IN');
    }

    // Pause if TTS is currently speaking out loud
    if (TtsServiceImpl.isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (_isBusy) {
      AppLogger.w('STT', 'STT busy, waiting for lock...');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isBusy = true;

    try {
      await _speech.cancel();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 300));

    final ok = await init();
    if (!ok) {
      _isBusy = false;
      return SpeechResult(text: '', confidence: 0.0, languageCode: 'en_IN');
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
            _isBusy = false;
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
        _isBusy = false;
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
    Function(String status)? onStatus,
  }) async {
    _onStatusListener = onStatus;
    _isBusy = false;
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    if (TtsServiceImpl.isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 200));
    }

    bool ok = await init();
    if (!ok) return;

    _isBusy = false;

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
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.deviceDefault,
        localeId: 'en_IN',
      );
    } catch (e) {
      AppLogger.e('STT', 'Stream exception: $e');
      _isBusy = false;
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
      _onStatusListener = null;
      if (_speech.isListening) await _speech.stop();
    } catch (_) {}
  }
}
