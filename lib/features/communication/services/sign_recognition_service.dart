import 'dart:async';
import '../models/sign_recognition_candidate.dart';

abstract class SignRecognitionService {
  Stream<SignRecognitionCandidate> streamPredictions();
  Future<void> startRecognition();
  Future<void> stopRecognition();
}

class SignRecognitionResult {
  final String signName;
  final double confidence;
  final bool isMatch;
  final String? feedbackPrompt;

  SignRecognitionResult({
    required this.signName,
    required this.confidence,
    required this.isMatch,
    this.feedbackPrompt,
  });
}