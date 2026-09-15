import 'dart:async';
import 'dart:math';
import '../models/sign_recognition_candidate.dart';
import 'sign_recognition_service.dart';

class MockSignRecognitionService implements SignRecognitionService {
  final _controller = StreamController<SignRecognitionCandidate>.broadcast();
  Timer? _simulationTimer;
  bool _isRunning = false;
  final Random _random = Random();

  // Mock sign database for simulation
  static const List<String> _mockSigns = [
    'Hello',
    'Thank you',
    'Help',
    'Water',
    'Food',
    'Where',
    'Yes',
    'No',
    'Hospital',
    'One',
    'Two',
    'Left',
    'Right',
    'Doctor',
  ];

  @override
  Stream<SignRecognitionCandidate> streamPredictions() {
    return _controller.stream;
  }

  @override
  Future<void> startRecognition() async {
    if (_isRunning) return;
    _isRunning = true;
    
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      
      _simulatePrediction();
    });
  }

  @override
  Future<void> stopRecognition() async {
    _isRunning = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void _simulatePrediction() {
    // Simulate hand stability and recognition confidence
    final stability = _random.nextDouble();
    
    if (stability < 0.2) {
      // Low confidence - hand not steady
      _controller.add(SignRecognitionCandidate.lowConfidence(
        'Please hold your hand steady.',
      ));
      return;
    }
    
    if (stability < 0.35) {
      // Medium confidence - hand out of frame or unclear
      _controller.add(SignRecognitionCandidate.lowConfidence(
        'Please ensure your hand is in the frame.',
      ));
      return;
    }
    
    // Generate prediction with varying confidence
    final signIndex = _random.nextInt(_mockSigns.length);
    final signName = _mockSigns[signIndex];
    final confidence = 0.3 + (_random.nextDouble() * 0.7); // 0.3 to 1.0
    
    final isMatch = confidence >= 0.7;
    
    _controller.add(SignRecognitionCandidate(
      signName: signName,
      confidence: confidence,
      isMatch: isMatch,
      feedbackPrompt: isMatch ? null : 'Try again - confidence low',
    ));
  }

  void dispose() {
    stopRecognition();
    _controller.close();
  }
}
