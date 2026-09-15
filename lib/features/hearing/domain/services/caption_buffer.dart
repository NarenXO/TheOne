import '../models/transcript_segment.dart';

class CaptionBuffer {
  final List<TranscriptSegment> _segments = [];
  static const Duration _maxDuration = Duration(seconds: 30);

  void addSegment(TranscriptSegment segment) {
    _segments.add(segment);
    _pruneOldSegments();
  }

  void _pruneOldSegments() {
    if (_segments.isEmpty) return;

    final now = DateTime.now();
    final cutoffTime = now.subtract(_maxDuration);

    _segments.removeWhere((segment) => segment.timestamp.isBefore(cutoffTime));
  }

  List<TranscriptSegment> getLiveStream() {
    _pruneOldSegments();
    return List.unmodifiable(_segments);
  }

  List<TranscriptSegment> getRewindSnapshot() {
    _pruneOldSegments();
    return List.unmodifiable(_segments);
  }

  List<TranscriptSegment> getSegmentsInDuration(Duration duration) {
    _pruneOldSegments();
    final now = DateTime.now();
    final cutoffTime = now.subtract(duration);

    return _segments.where((segment) => segment.timestamp.isAfter(cutoffTime)).toList();
  }

  void clear() {
    _segments.clear();
  }

  int get length => _segments.length;

  bool get isEmpty => _segments.isEmpty;

  bool get isNotEmpty => _segments.isNotEmpty;
}
