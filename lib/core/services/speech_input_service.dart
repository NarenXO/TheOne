abstract class SpeechInputService {
  Future<SpeechResult> listen();
  Future<void> stop();
}

class SpeechResult {
  final String text;
  final double confidence;
  final String languageCode;
  SpeechResult({required this.text, required this.confidence, required this.languageCode});
}
