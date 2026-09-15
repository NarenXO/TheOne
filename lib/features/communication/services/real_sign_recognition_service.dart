import 'dart:async';
import '../models/sign_recognition_candidate.dart';
import 'sign_recognition_service.dart';

class RealSignRecognitionService implements SignRecognitionService {
  final _controller = StreamController<SignRecognitionCandidate>.broadcast();

  @override
  Stream<SignRecognitionCandidate> streamPredictions() => _controller.stream;

  @override
  Future<void> startRecognition() async {}

  @override
  Future<void> stopRecognition() async {
    await _controller.close();
  }
}
