// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../speech_input_service.dart';
import '../../utils/app_logger.dart';

class SpeechInputServiceImpl implements SpeechInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _available = false;

  Future<bool> _ensureInit() async {
    if (_initialized) return _available;
    _available = await _speech.initialize(
      onError: (e) => AppLogger.e('STT', 'Error: $e'),
      onStatus: (s) => AppLogger.i('STT', 'Status: $s'),
    );
    _initialized = true;
    AppLogger.i('STT', 'Initialized available=$_available');
    return _available;
  }

  @override
  Future<SpeechResult> listen({
    Duration listenFor = const Duration(seconds: 8),
    Duration pauseFor = const Duration(seconds: 3),
    String localeId = 'en_IN',
  }) async {
    final ok = await _ensureInit();
    if (!ok) {
      AppLogger.e('STT', 'Speech recognition unavailable on device');
      return SpeechResult(text: '', confidence: 0.0, languageCode: localeId);
    }

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 250));
    }

    final completer = Completer<SpeechResult>();
    String latest = '';
    double conf = 0.0;

    AppLogger.i('STT', 'Listening start locale=$localeId');

    await _speech.listen(
      onResult: (result) {
        latest = result.recognizedWords.trim();
        if (result.hasConfidenceRating && result.confidence > 0) {
          conf = result.confidence;
        } else if (latest.isNotEmpty) {
          conf = 0.88;
        }
        AppLogger.i('STT', 'Partial/final="$latest" final=${result.finalResult} conf=$conf');
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(SpeechResult(
            text: latest,
            confidence: conf > 0 ? conf : 0.85,
            languageCode: localeId,
          ));
        }
      },
      listenFor: listenFor,
      pauseFor: pauseFor,
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
      localeId: localeId,
    );

    // Timeout fallback if finalResult never fires
    final result = await completer.future.timeout(
      listenFor + const Duration(seconds: 2),
      onTimeout: () {
        AppLogger.w('STT', 'Timeout. latest="$latest"');
        return SpeechResult(
          text: latest,
          confidence: latest.isEmpty ? 0.0 : (conf > 0 ? conf : 0.8),
          languageCode: localeId,
        );
      },
    );

    try {
      await _speech.stop();
    } catch (_) {}

    AppLogger.i('STT', 'Final captured: "${result.text}" conf=${result.confidence}');
    return result;
  }

  @override
  Future<void> stop() async {
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {}
  }
}
