import 'tone_inference.dart';

class TranscriptSegment {
  final String id;
  final String text;
  final String rawText;
  final DateTime timestamp;
  final double confidence;
  final String speakerId;
  final bool isPartial;
  final bool isLowConfidence;
  final ToneInference? tone;

  TranscriptSegment({
    required this.id,
    required this.text,
    required this.rawText,
    required this.timestamp,
    required this.confidence,
    required this.speakerId,
    this.isPartial = false,
    this.tone,
  }) : isLowConfidence = confidence < 0.70;

  TranscriptSegment copyWith({
    String? id,
    String? text,
    String? rawText,
    DateTime? timestamp,
    double? confidence,
    String? speakerId,
    bool? isPartial,
    ToneInference? tone,
  }) {
    return TranscriptSegment(
      id: id ?? this.id,
      text: text ?? this.text,
      rawText: rawText ?? this.rawText,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      speakerId: speakerId ?? this.speakerId,
      isPartial: isPartial ?? this.isPartial,
      tone: tone ?? this.tone,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'rawText': rawText,
        'timestamp': timestamp.toIso8601String(),
        'confidence': confidence,
        'speakerId': speakerId,
        'isPartial': isPartial,
        'isLowConfidence': isLowConfidence,
        'tone': tone?.toMap(),
      };

  static String addAutoPunctuation(String text) {
    if (text.isEmpty) return text;

    final trimmed = text.trim();
    final lastChar = trimmed.isNotEmpty ? trimmed[trimmed.length - 1] : '';

    if (['.', '?', '!'].contains(lastChar)) {
      return trimmed;
    }

    final lowerText = trimmed.toLowerCase();
    final questionWords = ['what', 'where', 'when', 'why', 'how', 'who', 'which', 'whose'];
    final isQuestion = questionWords.any((word) => lowerText.startsWith('$word '));

    if (isQuestion) {
      return '$trimmed?';
    }

    return '$trimmed.';
  }
}
