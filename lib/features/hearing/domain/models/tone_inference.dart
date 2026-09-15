enum ToneType {
  calm,
  excited,
  tense,
  neutral,
}

class ToneInference {
  final ToneType type;
  final double confidence;
  final String explanationText;

  ToneInference({
    required this.type,
    required this.confidence,
    required this.explanationText,
  });

  ToneInference copyWith({
    ToneType? type,
    double? confidence,
    String? explanationText,
  }) {
    return ToneInference(
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      explanationText: explanationText ?? this.explanationText,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'confidence': confidence,
        'explanationText': explanationText,
      };

  String get emoji {
    switch (type) {
      case ToneType.calm:
        return '😌';
      case ToneType.excited:
        return '⚡';
      case ToneType.tense:
        return '⚠';
      case ToneType.neutral:
        return '💬';
    }
  }

  String get displayName {
    switch (type) {
      case ToneType.calm:
        return 'Calm';
      case ToneType.excited:
        return 'Excited';
      case ToneType.tense:
        return 'Tense';
      case ToneType.neutral:
        return 'Neutral';
    }
  }
}
