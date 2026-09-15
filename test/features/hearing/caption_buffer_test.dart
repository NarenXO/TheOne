import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/hearing/domain/models/transcript_segment.dart';
import 'package:theone/features/hearing/domain/services/caption_buffer.dart';

void main() {
  group('CaptionBuffer', () {
    late CaptionBuffer buffer;

    setUp(() {
      buffer = CaptionBuffer();
    });

    test('should start empty', () {
      expect(buffer.isEmpty, true);
      expect(buffer.length, 0);
    });

    test('should add segments', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime.now(),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      buffer.addSegment(segment);

      expect(buffer.isEmpty, false);
      expect(buffer.length, 1);
    });

    test('should prune segments older than 30 seconds', () async {
      final now = DateTime.now();
      final oldSegment = TranscriptSegment(
        id: '1',
        text: 'Old',
        rawText: 'Old',
        timestamp: now.subtract(const Duration(seconds: 31)),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      final newSegment = TranscriptSegment(
        id: '2',
        text: 'New',
        rawText: 'New',
        timestamp: now,
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      buffer.addSegment(oldSegment);
      buffer.addSegment(newSegment);

      final segments = buffer.getLiveStream();
      expect(segments.length, 1);
      expect(segments.first.text, 'New');
    });

    test('should keep segments within 30 seconds', () {
      final now = DateTime.now();
      final segment1 = TranscriptSegment(
        id: '1',
        text: 'First',
        rawText: 'First',
        timestamp: now.subtract(const Duration(seconds: 25)),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      final segment2 = TranscriptSegment(
        id: '2',
        text: 'Second',
        rawText: 'Second',
        timestamp: now,
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      buffer.addSegment(segment1);
      buffer.addSegment(segment2);

      final segments = buffer.getLiveStream();
      expect(segments.length, 2);
    });

    test('should provide rewind snapshot', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Test',
        rawText: 'Test',
        timestamp: DateTime.now(),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      buffer.addSegment(segment);
      final snapshot = buffer.getRewindSnapshot();

      expect(snapshot.length, 1);
      expect(snapshot.first.text, 'Test');
    });

    test('should clear all segments', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Test',
        rawText: 'Test',
        timestamp: DateTime.now(),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      buffer.addSegment(segment);
      buffer.clear();

      expect(buffer.isEmpty, true);
      expect(buffer.length, 0);
    });

    test('should get segments in specific duration', () {
      final now = DateTime.now();
      final segment1 = TranscriptSegment(
        id: '1',
        text: 'First',
        rawText: 'First',
        timestamp: now.subtract(const Duration(seconds: 15)),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      final segment2 = TranscriptSegment(
        id: '2',
        text: 'Second',
        rawText: 'Second',
        timestamp: now,
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      buffer.addSegment(segment1);
      buffer.addSegment(segment2);

      final segments = buffer.getSegmentsInDuration(const Duration(seconds: 10));
      expect(segments.length, 1);
      expect(segments.first.text, 'Second');
    });
  });
}
