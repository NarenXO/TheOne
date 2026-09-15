enum SoundCategory {
  alarm,
  siren,
  horn,
  doorbell,
  knock,
  shouting,
  announcement,
  phoneRing,
  speech,
  backgroundNoise,
}

class SoundEvent {
  final SoundCategory category;
  final String label;
  final double confidence;
  final DateTime timestamp;
  final bool isDanger;

  SoundEvent({
    required this.category,
    required this.label,
    required this.confidence,
    DateTime? timestamp,
  })  : timestamp = timestamp ?? DateTime.now(),
        isDanger = _isDangerousCategory(category);

  static bool _isDangerousCategory(SoundCategory category) {
    return [
      SoundCategory.alarm,
      SoundCategory.siren,
      SoundCategory.horn,
      SoundCategory.shouting,
    ].contains(category);
  }

  String get formattedDescription {
    return 'Possible $label detected.';
  }

  String get formattedDescriptionWithConfidence {
    final confidencePercent = (confidence * 100).toStringAsFixed(0);
    return 'Possible $label detected ($confidencePercent%).';
  }

  SoundEvent copyWith({
    SoundCategory? category,
    String? label,
    double? confidence,
    DateTime? timestamp,
  }) {
    return SoundEvent(
      category: category ?? this.category,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category.name,
        'label': label,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'isDanger': isDanger,
      };
}
