import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/hearing/domain/models/sound_event.dart';

void main() {
  group('SoundEvent', () {
    test('should mark alarm as danger', () {
      final event = SoundEvent(
        category: SoundCategory.alarm,
        label: 'Fire Alarm',
        confidence: 0.9,
      );

      expect(event.isDanger, true);
    });

    test('should mark siren as danger', () {
      final event = SoundEvent(
        category: SoundCategory.siren,
        label: 'Police Siren',
        confidence: 0.85,
      );

      expect(event.isDanger, true);
    });

    test('should mark horn as danger', () {
      final event = SoundEvent(
        category: SoundCategory.horn,
        label: 'Vehicle Horn',
        confidence: 0.8,
      );

      expect(event.isDanger, true);
    });

    test('should mark shouting as danger', () {
      final event = SoundEvent(
        category: SoundCategory.shouting,
        label: 'Shouting',
        confidence: 0.75,
      );

      expect(event.isDanger, true);
    });

    test('should not mark doorbell as danger', () {
      final event = SoundEvent(
        category: SoundCategory.doorbell,
        label: 'Doorbell',
        confidence: 0.9,
      );

      expect(event.isDanger, false);
    });

    test('should not mark knock as danger', () {
      final event = SoundEvent(
        category: SoundCategory.knock,
        label: 'Knock',
        confidence: 0.85,
      );

      expect(event.isDanger, false);
    });

    test('should not mark phone ring as danger', () {
      final event = SoundEvent(
        category: SoundCategory.phoneRing,
        label: 'Phone Ring',
        confidence: 0.9,
      );

      expect(event.isDanger, false);
    });

    test('should not mark speech as danger', () {
      final event = SoundEvent(
        category: SoundCategory.speech,
        label: 'Speech',
        confidence: 0.8,
      );

      expect(event.isDanger, false);
    });

    test('should not mark background noise as danger', () {
      final event = SoundEvent(
        category: SoundCategory.backgroundNoise,
        label: 'Background Noise',
        confidence: 0.7,
      );

      expect(event.isDanger, false);
    });

    test('should format honest description', () {
      final event = SoundEvent(
        category: SoundCategory.horn,
        label: 'Vehicle Horn',
        confidence: 0.91,
      );

      expect(event.formattedDescription, 'Possible Vehicle Horn detected.');
    });

    test('should format description with confidence percentage', () {
      final event = SoundEvent(
        category: SoundCategory.horn,
        label: 'Vehicle Horn',
        confidence: 0.91,
      );

      expect(event.formattedDescriptionWithConfidence, 'Possible Vehicle Horn detected (91%).');
    });

    test('should round confidence percentage correctly', () {
      final event = SoundEvent(
        category: SoundCategory.doorbell,
        label: 'Doorbell',
        confidence: 0.876,
      );

      expect(event.formattedDescriptionWithConfidence, 'Possible Doorbell detected (88%).');
    });

    test('should handle low confidence in description', () {
      final event = SoundEvent(
        category: SoundCategory.knock,
        label: 'Knock',
        confidence: 0.45,
      );

      expect(event.formattedDescriptionWithConfidence, 'Possible Knock detected (45%).');
    });

    test('should create copy with updated values', () {
      final original = SoundEvent(
        category: SoundCategory.doorbell,
        label: 'Doorbell',
        confidence: 0.9,
      );

      final copy = original.copyWith(confidence: 0.95);

      expect(copy.confidence, 0.95);
      expect(copy.category, original.category);
      expect(copy.label, original.label);
    });

    test('should convert to map', () {
      final event = SoundEvent(
        category: SoundCategory.alarm,
        label: 'Fire Alarm',
        confidence: 0.91,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final map = event.toMap();

      expect(map['category'], 'alarm');
      expect(map['label'], 'Fire Alarm');
      expect(map['confidence'], 0.91);
      expect(map['isDanger'], true);
    });

    test('should include timestamp in map', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final event = SoundEvent(
        category: SoundCategory.phoneRing,
        label: 'Phone Ring',
        confidence: 0.9,
        timestamp: timestamp,
      );

      final map = event.toMap();

      expect(map['timestamp'], timestamp.toIso8601String());
    });

    test('should use current timestamp when not provided', () {
      final event = SoundEvent(
        category: SoundCategory.knock,
        label: 'Knock',
        confidence: 0.85,
      );

      final now = DateTime.now();
      final difference = now.difference(event.timestamp).abs();

      expect(difference.inSeconds, lessThan(1));
    });

    test('should format description for announcement', () {
      final event = SoundEvent(
        category: SoundCategory.announcement,
        label: 'Announcement',
        confidence: 0.88,
      );

      expect(event.formattedDescription, 'Possible Announcement detected.');
    });
  });
}
