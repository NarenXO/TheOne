import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/hearing/domain/models/transcript_segment.dart';
import 'package:theone/features/hearing/domain/services/caption_history_service.dart';

void main() {
  group('CaptionHistoryService', () {
    late CaptionHistoryService historyService;

    setUp(() {
      historyService = CaptionHistoryService();
    });

    test('should start empty', () {
      expect(historyService.isEmpty, true);
      expect(historyService.length, 0);
    });

    test('should add segments to history', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      historyService.addSegment(segment);

      expect(historyService.isEmpty, false);
      expect(historyService.length, 1);
    });

    test('should return all segments', () {
      final segment1 = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      final segment2 = TranscriptSegment(
        id: '2',
        text: 'World',
        rawText: 'World',
        timestamp: DateTime(2024, 1, 1, 12, 0, 1),
        confidence: 0.85,
        speakerId: 'speaker_2',
      );

      historyService.addSegment(segment1);
      historyService.addSegment(segment2);

      final allSegments = historyService.getAll();
      expect(allSegments.length, 2);
    });

    test('should clear history', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime.now(),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      historyService.addSegment(segment);
      historyService.clear();

      expect(historyService.isEmpty, true);
      expect(historyService.length, 0);
    });

    test('should export as text with proper formatting', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello world.',
        rawText: 'Hello world',
        timestamp: DateTime(2024, 1, 1, 14, 30, 45),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      historyService.addSegment(segment);
      final textExport = historyService.exportAsText();

      expect(textExport, contains('[14:30:45]'));
      expect(textExport, contains('Speaker speaker_1'));
      expect(textExport, contains('(90.0%)'));
      expect(textExport, contains('Hello world.'));
    });

    test('should export multiple segments as text', () {
      final segment1 = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      final segment2 = TranscriptSegment(
        id: '2',
        text: 'World',
        rawText: 'World',
        timestamp: DateTime(2024, 1, 1, 12, 0, 1),
        confidence: 0.85,
        speakerId: 'speaker_2',
      );

      historyService.addSegment(segment1);
      historyService.addSegment(segment2);
      final textExport = historyService.exportAsText();

      final lines = textExport.split('\n').where((line) => line.isNotEmpty).toList();
      expect(lines.length, 2);
    });

    test('should export as CSV with proper headers', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      historyService.addSegment(segment);
      final csvExport = historyService.exportAsCsv();

      expect(csvExport, contains('Timestamp,SpeakerID,Confidence,Text,RawText,IsPartial,IsLowConfidence'));
    });

    test('should export as CSV with proper data', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello world',
        rawText: 'Hello world',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        confidence: 0.9,
        speakerId: 'speaker_1',
        isPartial: false,
      );

      historyService.addSegment(segment);
      final csvExport = historyService.exportAsCsv();

      expect(csvExport, contains('2024-01-01T12:00:00.000'));
      expect(csvExport, contains('speaker_1'));
      expect(csvExport, contains('90.0'));
      expect(csvExport, contains('Hello world'));
      expect(csvExport, contains('false'));
    });

    test('should escape CSV fields with commas', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello, world',
        rawText: 'Hello, world',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      historyService.addSegment(segment);
      final csvExport = historyService.exportAsCsv();

      expect(csvExport, contains('"Hello, world"'));
    });

    test('should escape CSV fields with quotes', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello "world"',
        rawText: 'Hello "world"',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      historyService.addSegment(segment);
      final csvExport = historyService.exportAsCsv();

      expect(csvExport, contains('"Hello ""world"""'));
    });

    test('should return empty string for text export when empty', () {
      final textExport = historyService.exportAsText();
      expect(textExport, '');
    });

    test('should return empty string for CSV export when empty', () {
      final csvExport = historyService.exportAsCsv();
      expect(csvExport, '');
    });

    test('should format timestamp correctly in text export', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Test',
        rawText: 'Test',
        timestamp: DateTime(2024, 1, 1, 9, 5, 3),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      historyService.addSegment(segment);
      final textExport = historyService.exportAsText();

      expect(textExport, contains('[09:05:03]'));
    });

    test('should handle low confidence segments in export', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        confidence: 0.65,
        speakerId: 'speaker_1',
      );

      historyService.addSegment(segment);
      final csvExport = historyService.exportAsCsv();

      expect(csvExport, contains('true'));
    });

    test('should handle partial segments in export', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        confidence: 0.9,
        speakerId: 'speaker_1',
        isPartial: true,
      );

      historyService.addSegment(segment);
      final csvExport = historyService.exportAsCsv();

      expect(csvExport, contains('true'));
    });
  });
}
