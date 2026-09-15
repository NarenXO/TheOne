import '../models/evidence_source.dart';
import '../models/evidence_type.dart';

class Evidence {
  final EvidenceSource source;
  final EvidenceType type;
  final String value;
  final double confidence;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Evidence({
    required this.source,
    required this.type,
    required this.value,
    required this.confidence,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  })  : timestamp = timestamp ?? DateTime.now(),
        metadata = metadata ?? const {};

  Map<String, dynamic> toMap() => {
        'source': source.name,
        'type': type.name,
        'value': value,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  @override
  String toString() =>
      'Evidence(source: ${source.name}, type: ${type.name}, value: "$value", confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}
