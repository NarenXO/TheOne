import '../../../core/models/confidence_state.dart';

enum Intent {
  askLocation,
  orderFood,
  requestHelp,
  greeting,
  emergency,
  thanks,
  repeat,
  wait,
  price,
  direction,
  unknown,
}

class IntentResult {
  final Intent intent;
  final String? target;
  final double confidence;
  final String generatedEn;
  final String generatedTa;
  final ConfidenceState state;

  IntentResult({
    required this.intent,
    this.target,
    required this.confidence,
    required this.generatedEn,
    required this.generatedTa,
    required this.state,
  });

  factory IntentResult.insufficient(String message) {
    return IntentResult(
      intent: Intent.unknown,
      confidence: 0.0,
      generatedEn: message,
      generatedTa: message,
      state: ConfidenceState.insufficient,
    );
  }

  factory IntentResult.uncertain(String messageEn, String messageTa) {
    return IntentResult(
      intent: Intent.unknown,
      confidence: 0.5,
      generatedEn: messageEn,
      generatedTa: messageTa,
      state: ConfidenceState.uncertain,
    );
  }

  IntentResult copyWith({
    Intent? intent,
    String? target,
    double? confidence,
    String? generatedEn,
    String? generatedTa,
    ConfidenceState? state,
  }) {
    return IntentResult(
      intent: intent ?? this.intent,
      target: target ?? this.target,
      confidence: confidence ?? this.confidence,
      generatedEn: generatedEn ?? this.generatedEn,
      generatedTa: generatedTa ?? this.generatedTa,
      state: state ?? this.state,
    );
  }
}