import '../models/transcript_segment.dart';

class CaptionHistoryService {
  final List<TranscriptSegment> _history = [];

  void addSegment(TranscriptSegment segment) {
    _history.add(segment);
  }

  List<TranscriptSegment> getAll() {
    return List.unmodifiable(_history);
  }

  void clear() {
    _history.clear();
  }

  String exportAsText() {
    if (_history.isEmpty) return '';

    final buffer = StringBuffer();
    for (final segment in _history) {
      final timestamp = _formatTimestamp(segment.timestamp);
      final confidence = (segment.confidence * 100).toStringAsFixed(1);
      buffer.writeln('[$timestamp] Speaker ${segment.speakerId} ($confidence%): ${segment.text}');
    }

    return buffer.toString();
  }

  String exportAsCsv() {
    if (_history.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('Timestamp,SpeakerID,Confidence,Text,RawText,IsPartial,IsLowConfidence');

    for (final segment in _history) {
      final timestamp = segment.timestamp.toIso8601String();
      final confidence = (segment.confidence * 100).toStringAsFixed(1);
      final text = _escapeCsvField(segment.text);
      final rawText = _escapeCsvField(segment.rawText);

      buffer.writeln('$timestamp,${segment.speakerId},$confidence,$text,$rawText,${segment.isPartial},${segment.isLowConfidence}');
    }

    return buffer.toString();
  }

  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  int get length => _history.length;

  bool get isEmpty => _history.isEmpty;

  bool get isNotEmpty => _history.isNotEmpty;
}
