// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../speech_input_service.dart';

class SpeechInputServiceImpl implements SpeechInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    if (!_initialized) {
      _initialized = await _speech.initialize();
    }
    return _initialized;
  }

  // One-shot for specific prompts
  @override
  Future<SpeechResult> listen() async {
    final ok = await init();
    if (!ok) return SpeechResult(text: '', confidence: 0.0, languageCode: 'en_IN');

    final completer = Completer<SpeechResult>();
    String latest = '';
    
    await _speech.listen(
      onResult: (res) {
        latest = res.recognizedWords;
        if (res.finalResult && !completer.isCompleted) {
          completer.complete(SpeechResult(text: latest, confidence: 0.9, languageCode: 'en_IN'));
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_IN',
    );

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => SpeechResult(text: latest, confidence: 0.8, languageCode: 'en_IN'),
    ).whenComplete(() => _speech.stop());
  }

  // True continuous streaming for Wake Word & Captions
  Future<void> startContinuousStream(Function(String text, bool isFinal) onResult) async {
    final ok = await init();
    if (!ok) return;

    if (_speech.isListening) await _speech.stop();

    await _speech.listen(
      onResult: (res) => onResult(res.recognizedWords, res.finalResult),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.dictation,
      localeId: 'ta_IN', // Supports Tamil and English mixed
    );
  }

  @override
  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }
}
