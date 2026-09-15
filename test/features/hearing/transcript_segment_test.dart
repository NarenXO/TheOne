import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/hearing/domain/models/transcript_segment.dart';
import 'package:theone/features/hearing/domain/models/tone_inference.dart';

void main() {
  group('TranscriptSegment', () {
    test('should flag low confidence segments', () {
      final lowConfidenceSegment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime.now(),
        confidence: 0.65,
        speakerId: 'speaker_1',
      );

      expect(lowConfidenceSegment.isLowConfidence, true);
    });

    test('should not flag high confidence segments', () {
      final highConfidenceSegment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime.now(),
        confidence: 0.85,
        speakerId: 'speaker_1',
      );

      expect(highConfidenceSegment.isLowConfidence, false);
    });

    test('should flag exactly threshold confidence as not low', () {
      final thresholdSegment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime.now(),
        confidence: 0.70,
        speakerId: 'speaker_1',
      );

      expect(thresholdSegment.isLowConfidence, false);
    });

    test('should add period to text without punctuation', () {
      final text = 'Hello world';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'Hello world.');
    });

    test('should add question mark to questions', () {
      final text = 'What time is it';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'What time is it?');
    });

    test('should add question mark for who questions', () {
      final text = 'Who is there';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'Who is there?');
    });

    test('should add question mark for where questions', () {
      final text = 'Where are you going';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'Where are you going?');
    });

    test('should add question mark for when questions', () {
      final text = 'When will we arrive';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'When will we arrive?');
    });

    test('should add question mark for why questions', () {
      final text = 'Why did you do that';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'Why did you do that?');
    });

    test('should add question mark for how questions', () {
      final text = 'How are you doing';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'How are you doing?');
    });

    test('should not add punctuation if already has period', () {
      final text = 'Hello world.';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'Hello world.');
    });

    test('should not add punctuation if already has question mark', () {
      final text = 'What time is it?';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'What time is it?');
    });

    test('should not add punctuation if already has exclamation', () {
      final text = 'Hello world!';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'Hello world!');
    });

    test('should handle empty text', () {
      final text = '';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, '');
    });

    test('should handle text with leading/trailing spaces', () {
      final text = '  Hello world  ';
      final result = TranscriptSegment.addAutoPunctuation(text);

      expect(result, 'Hello world.');
    });

    test('should create copy with updated values', () {
      final original = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime.now(),
        confidence: 0.9,
        speakerId: 'speaker_1',
      );

      final copy = original.copyWith(text: 'Goodbye');

      expect(copy.text, 'Goodbye');
      expect(copy.id, original.id);
      expect(copy.confidence, original.confidence);
    });

    test('should convert to map', () {
      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        confidence: 0.9,
        speakerId: 'speaker_1',
        isPartial: true,
      );

      final map = segment.toMap();

      expect(map['id'], '1');
      expect(map['text'], 'Hello');
      expect(map['confidence'], 0.9);
      expect(map['speakerId'], 'speaker_1');
      expect(map['isPartial'], true);
      expect(map['isLowConfidence'], false);
    });

    test('should include tone in map when present', () {
      final tone = ToneInference(
        type: ToneType.calm,
        confidence: 0.85,
        explanationText: 'Voice characteristics suggest a calm tone.',
      );

      final segment = TranscriptSegment(
        id: '1',
        text: 'Hello',
        rawText: 'Hello',
        timestamp: DateTime.now(),
        confidence: 0.9,
        speakerId: 'speaker_1',
        tone: tone,
      );

      final map = segment.toMap();

      expect(map['tone'], isNotNull);
      expect(map['tone']['type'], 'calm');
    });
  });
}
