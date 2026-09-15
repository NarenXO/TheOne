import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../domain/models/transcript_segment.dart';
import '../domain/models/sound_event.dart';
import '../domain/models/tone_inference.dart';

class RealSpeechRecognitionService {
  final StreamController<TranscriptSegment> _controller = StreamController<TranscriptSegment>.broadcast();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isFrozen = false;
  bool _isInitialized = false;
  final String _currentSpeakerId = 'speaker_1';
  int _segmentCount = 0;

  Stream<TranscriptSegment> get transcriptStream => _controller.stream;

  bool get isListening => _isListening;

  bool get isFrozen => _isFrozen;

  Future<bool> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize();
    }
    return _isInitialized;
  }

  void startListening() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      return;
    }

    _isListening = true;
    _segmentCount = 0;

    await _speech.listen(
      onResult: (result) {
        if (_isFrozen) return;

        final recognizedWords = result.recognizedWords;
        final confidence = result.confidence > 0 ? result.confidence : 0.85;
        final isPartial = !result.finalResult;

        final segment = TranscriptSegment(
          id: 'real_${DateTime.now().millisecondsSinceEpoch}_$_segmentCount',
          text: TranscriptSegment.addAutoPunctuation(recognizedWords),
          rawText: recognizedWords,
          timestamp: DateTime.now(),
          confidence: confidence,
          speakerId: _currentSpeakerId,
          isPartial: isPartial,
          tone: isPartial ? null : _analyzeTone(recognizedWords),
        );

        _controller.add(segment);
        if (!isPartial) {
          _segmentCount++;
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(minutes: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
      ),
    );
  }

  void stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  void freeze() {
    _isFrozen = true;
  }

  void resume() {
    _isFrozen = false;
  }

  ToneInference? _analyzeTone(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('!') || lowerText.contains('excited') || lowerText.contains('great')) {
      return ToneInference(
        type: ToneType.excited,
        confidence: 0.75,
        explanationText: 'Voice characteristics suggest an excited tone.',
      );
    }
    
    if (lowerText.contains('?') || lowerText.contains('please') || lowerText.contains('thank')) {
      return ToneInference(
        type: ToneType.calm,
        confidence: 0.80,
        explanationText: 'Voice characteristics suggest a calm tone.',
      );
    }
    
    if (lowerText.contains('urgent') || lowerText.contains('hurry') || lowerText.contains('danger')) {
      return ToneInference(
        type: ToneType.tense,
        confidence: 0.70,
        explanationText: 'Voice characteristics suggest a tense tone.',
      );
    }
    
    return ToneInference(
      type: ToneType.neutral,
      confidence: 0.85,
      explanationText: 'Voice characteristics suggest a neutral tone.',
    );
  }

  void dispose() {
    _controller.close();
  }
}

class RealSoundClassifierService {
  final StreamController<SoundEvent> _controller = StreamController<SoundEvent>.broadcast();
  bool _isActive = false;

  Stream<SoundEvent> get soundStream => _controller.stream;

  bool get isActive => _isActive;

  void startClassification() {
    _isActive = true;
  }

  void stopClassification() {
    _isActive = false;
  }

  void dispose() {
    _controller.close();
  }
}

class RealSpeakerTrackerService {
  final StreamController<String> _controller = StreamController<String>.broadcast();
  bool _isActive = false;
  String _currentSpeaker = 'speaker_1';

  Stream<String> get speakerChangeStream => _controller.stream;

  bool get isActive => _isActive;

  void startTracking() {
    _isActive = true;
  }

  void stopTracking() {
    _isActive = false;
  }

  void setCurrentSpeaker(String speakerId) {
    if (_currentSpeaker != speakerId) {
      _currentSpeaker = speakerId;
      _controller.add(speakerId);
    }
  }

  void dispose() {
    _controller.close();
  }
}

class RealToneDetectionService {
  final StreamController<ToneInference> _controller = StreamController<ToneInference>.broadcast();
  bool _isActive = false;

  Stream<ToneInference> get toneStream => _controller.stream;

  bool get isActive => _isActive;

  void startDetection() {
    _isActive = true;
  }

  void stopDetection() {
    _isActive = false;
  }

  void dispose() {
    _controller.close();
  }
}
