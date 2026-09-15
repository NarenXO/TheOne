class SignRecognitionCandidate {
  final String signName;
  final double confidence;
  final bool isMatch;
  final String? feedbackPrompt;

  SignRecognitionCandidate({
    required this.signName,
    required this.confidence,
    required this.isMatch,
    this.feedbackPrompt,
  });

  factory SignRecognitionCandidate.lowConfidence(String feedbackPrompt) {
    return SignRecognitionCandidate(
      signName: '',
      confidence: 0.0,
      isMatch: false,
      feedbackPrompt: feedbackPrompt,
    );
  }

  SignRecognitionCandidate copyWith({
    String? signName,
    double? confidence,
    bool? isMatch,
    String? feedbackPrompt,
  }) {
    return SignRecognitionCandidate(
      signName: signName ?? this.signName,
      confidence: confidence ?? this.confidence,
      isMatch: isMatch ?? this.isMatch,
      feedbackPrompt: feedbackPrompt ?? this.feedbackPrompt,
    );
  }
}