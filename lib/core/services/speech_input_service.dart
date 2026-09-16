abstract class SpeechInputService {
  Future<SpeechResult> listen({
    Duration listenFor = const Duration(seconds: 8),
    Duration pauseFor = const Duration(seconds: 3),
    String localeId = 'en_IN',
  });
  Future<void> stop();
}

class SpeechResult {
  final String text;
  final double confidence;
  final String languageCode;
  SpeechResult({required this.text, required this.confidence, required this.languageCode});
}
