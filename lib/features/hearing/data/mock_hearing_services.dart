import 'dart:async';
import 'dart:math';
import '../domain/models/transcript_segment.dart';
import '../domain/models/sound_event.dart';
import '../domain/models/tone_inference.dart';

class MockSpeechRecognitionService {
  final StreamController<TranscriptSegment> _controller = StreamController<TranscriptSegment>.broadcast();
  bool _isListening = false;
  bool _isFrozen = false;
  int _dialogIndex = 0;
  final Random _random = Random();

  final List<String> _mockDialogues = [
    'Hello, how are you today?',
    'I am doing well, thank you for asking.',
    'What time is our meeting?',
    'The meeting is at three o clock this afternoon.',
    'Can you help me with this project?',
    'Of course, I would be happy to help.',
    'Where is the conference room?',
    'It is on the second floor, down the hall.',
    'Is there anything else you need?',
    'No, that is all for now, thank you.',
  ];

  Stream<TranscriptSegment> get transcriptStream => _controller.stream;

  bool get isListening => _isListening;

  bool get isFrozen => _isFrozen;

  void startListening() {
    _isListening = true;
    _emitMockTranscripts();
  }

  void stopListening() {
    _isListening = false;
  }

  void freeze() {
    _isFrozen = true;
  }

  void resume() {
    _isFrozen = false;
  }

  void _emitMockTranscripts() {
    if (!_isListening) return;

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isListening || _isFrozen) {
        if (!_isListening) timer.cancel();
        return;
      }

      _emitNextTranscript();
    });
  }

  void _emitNextTranscript() {
    final text = _mockDialogues[_dialogIndex % _mockDialogues.length];
    _dialogIndex++;

    final words = text.split(' ');
    var currentText = '';

    for (var i = 0; i < words.length; i++) {
      currentText += (i > 0 ? ' ' : '') + words[i];

      final isPartial = i < words.length - 1;
      final confidence = _random.nextDouble() * 0.3 + 0.7;

      final segment = TranscriptSegment(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}_$i',
        text: TranscriptSegment.addAutoPunctuation(currentText),
        rawText: currentText,
        timestamp: DateTime.now(),
        confidence: confidence,
        speakerId: _random.nextBool() ? 'speaker_1' : 'speaker_2',
        isPartial: isPartial,
        tone: isPartial ? null : _generateMockTone(),
      );

      _controller.add(segment);

      if (isPartial) {
        Future.delayed(const Duration(milliseconds: 150));
      }
    }
  }

  ToneInference _generateMockTone() {
    final tones = [
      ToneInference(
        type: ToneType.calm,
        confidence: 0.85,
        explanationText: 'Voice characteristics suggest a calm tone.',
      ),
      ToneInference(
        type: ToneType.neutral,
        confidence: 0.72,
        explanationText: 'Voice characteristics suggest a neutral tone.',
      ),
      ToneInference(
        type: ToneType.excited,
        confidence: 0.68,
        explanationText: 'Voice characteristics suggest an excited tone.',
      ),
    ];

    return tones[_random.nextInt(tones.length)];
  }

  void dispose() {
    _controller.close();
  }
}

class MockSoundClassifierService {
  final StreamController<SoundEvent> _controller = StreamController<SoundEvent>.broadcast();
  bool _isActive = false;

  final List<SoundEvent> _mockSounds = [
    SoundEvent(
      category: SoundCategory.doorbell,
      label: 'Doorbell',
      confidence: 0.92,
    ),
    SoundEvent(
      category: SoundCategory.knock,
      label: 'Knock',
      confidence: 0.88,
    ),
    SoundEvent(
      category: SoundCategory.phoneRing,
      label: 'Phone Ring',
      confidence: 0.95,
    ),
    SoundEvent(
      category: SoundCategory.alarm,
      label: 'Fire Alarm',
      confidence: 0.91,
    ),
    SoundEvent(
      category: SoundCategory.horn,
      label: 'Vehicle Horn',
      confidence: 0.87,
    ),
    SoundEvent(
      category: SoundCategory.shouting,
      label: 'Shouting',
      confidence: 0.83,
    ),
  ];

  Stream<SoundEvent> get soundStream => _controller.stream;

  bool get isActive => _isActive;

  void startClassification() {
    _isActive = true;
    _emitMockSounds();
  }

  void stopClassification() {
    _isActive = false;
  }

  void _emitMockSounds() {
    if (!_isActive) return;

    Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      final random = Random();
      final sound = _mockSounds[random.nextInt(_mockSounds.length)];
      _controller.add(sound);
    });
  }

  void dispose() {
    _controller.close();
  }
}

class MockSpeakerTrackerService {
  final StreamController<String> _controller = StreamController<String>.broadcast();
  bool _isActive = false;
  String _currentSpeaker = 'speaker_1';

  Stream<String> get speakerChangeStream => _controller.stream;

  bool get isActive => _isActive;

  void startTracking() {
    _isActive = true;
    _emitMockSpeakerChanges();
  }

  void stopTracking() {
    _isActive = false;
  }

  void _emitMockSpeakerChanges() {
    if (!_isActive) return;

    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      _currentSpeaker = _currentSpeaker == 'speaker_1' ? 'speaker_2' : 'speaker_1';
      _controller.add(_currentSpeaker);
    });
  }

  void dispose() {
    _controller.close();
  }
}

class MockToneDetectionService {
  final StreamController<ToneInference> _controller = StreamController<ToneInference>.broadcast();
  bool _isActive = false;

  final List<ToneInference> _mockTones = [
    ToneInference(
      type: ToneType.calm,
      confidence: 0.85,
      explanationText: 'Voice characteristics suggest a calm tone.',
    ),
    ToneInference(
      type: ToneType.neutral,
      confidence: 0.78,
      explanationText: 'Voice characteristics suggest a neutral tone.',
    ),
    ToneInference(
      type: ToneType.excited,
      confidence: 0.72,
      explanationText: 'Voice characteristics suggest an excited tone.',
    ),
    ToneInference(
      type: ToneType.tense,
      confidence: 0.65,
      explanationText: 'Voice characteristics suggest a tense tone.',
    ),
  ];

  Stream<ToneInference> get toneStream => _controller.stream;

  bool get isActive => _isActive;

  void startDetection() {
    _isActive = true;
    _emitMockTones();
  }

  void stopDetection() {
    _isActive = false;
  }

  void _emitMockTones() {
    if (!_isActive) return;

    Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      final random = Random();
      final tone = _mockTones[random.nextInt(_mockTones.length)];
      _controller.add(tone);
    });
  }

  void dispose() {
    _controller.close();
  }
}
