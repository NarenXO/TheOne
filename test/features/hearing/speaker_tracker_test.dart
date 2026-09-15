import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/hearing/domain/services/speaker_tracker_service.dart';

void main() {
  group('SpeakerTrackerService', () {
    late SpeakerTrackerService tracker;

    setUp(() {
      tracker = SpeakerTrackerService();
    });

    test('should start with no speakers', () {
      expect(tracker.speakerCount, 0);
      expect(tracker.getAllSpeakers().isEmpty, true);
    });

    test('should create new speaker when getting non-existent speaker', () {
      final speaker = tracker.getOrCreateSpeaker('speaker_1');

      expect(speaker.id, 'speaker_1');
      expect(speaker.defaultLabel, 'Speaker 1');
      expect(tracker.speakerCount, 1);
    });

    test('should return existing speaker when getting already created speaker', () {
      final speaker1 = tracker.getOrCreateSpeaker('speaker_1');
      final speaker2 = tracker.getOrCreateSpeaker('speaker_1');

      expect(speaker1.id, speaker2.id);
      expect(tracker.speakerCount, 1);
    });

    test('should create speakers with sequential numbering', () {
      final speaker1 = tracker.getOrCreateSpeaker('speaker_1');
      final speaker2 = tracker.getOrCreateSpeaker('speaker_2');
      final speaker3 = tracker.getOrCreateSpeaker('speaker_3');

      expect(speaker1.defaultLabel, 'Speaker 1');
      expect(speaker2.defaultLabel, 'Speaker 2');
      expect(speaker3.defaultLabel, 'Speaker 3');
      expect(tracker.speakerCount, 3);
    });

    test('should assign distinct colors to speakers', () {
      final speaker1 = tracker.getOrCreateSpeaker('speaker_1');
      final speaker2 = tracker.getOrCreateSpeaker('speaker_2');

      expect(speaker1.colorValue, isNot(equals(speaker2.colorValue)));
    });

    test('should set current speaker', () {
      tracker.getOrCreateSpeaker('speaker_1');
      tracker.getOrCreateSpeaker('speaker_2');

      tracker.setCurrentSpeaker('speaker_1');

      expect(tracker.currentSpeaker?.id, 'speaker_1');
    });

    test('should update isCurrentSpeaker flag when setting current speaker', () {
      tracker.getOrCreateSpeaker('speaker_1');
      tracker.getOrCreateSpeaker('speaker_2');

      tracker.setCurrentSpeaker('speaker_1');

      final speakers = tracker.getAllSpeakers();
      final speaker1 = speakers.firstWhere((s) => s.id == 'speaker_1');
      final speaker2 = speakers.firstWhere((s) => s.id == 'speaker_2');

      expect(speaker1.isCurrentSpeaker, true);
      expect(speaker2.isCurrentSpeaker, false);
    });

    test('should rename speaker', () {
      tracker.getOrCreateSpeaker('speaker_1');

      tracker.renameSpeaker('speaker_1', 'Doctor');

      final speaker = tracker.getSpeaker('speaker_1');
      expect(speaker?.customName, 'Doctor');
      expect(speaker?.displayName, 'Doctor');
    });

    test('should return default label when custom name is empty', () {
      tracker.getOrCreateSpeaker('speaker_1');

      final speaker = tracker.getSpeaker('speaker_1');
      expect(speaker?.displayName, 'Speaker 1');
    });

    test('should handle renaming non-existent speaker gracefully', () {
      tracker.renameSpeaker('non_existent', 'New Name');

      expect(tracker.speakerCount, 0);
    });

    test('should return null for non-existent speaker', () {
      final speaker = tracker.getSpeaker('non_existent');
      expect(speaker, isNull);
    });

    test('should clear current speaker after inactivity timeout', () async {
      tracker.getOrCreateSpeaker('speaker_1');
      tracker.setCurrentSpeaker('speaker_1');

      expect(tracker.currentSpeaker, isNotNull);

      await Future.delayed(const Duration(seconds: 6));
      tracker.checkInactivity();

      expect(tracker.currentSpeaker, isNull);
    });

    test('should not clear current speaker before inactivity timeout', () {
      tracker.getOrCreateSpeaker('speaker_1');
      tracker.setCurrentSpeaker('speaker_1');

      tracker.checkInactivity();

      expect(tracker.currentSpeaker, isNotNull);
    });

    test('should return all speakers', () {
      tracker.getOrCreateSpeaker('speaker_1');
      tracker.getOrCreateSpeaker('speaker_2');
      tracker.getOrCreateSpeaker('speaker_3');

      final speakers = tracker.getAllSpeakers();
      expect(speakers.length, 3);
    });

    test('should update current speaker flag when switching speakers', () {
      tracker.getOrCreateSpeaker('speaker_1');
      tracker.getOrCreateSpeaker('speaker_2');

      tracker.setCurrentSpeaker('speaker_1');
      tracker.setCurrentSpeaker('speaker_2');

      final speakers = tracker.getAllSpeakers();
      final speaker1 = speakers.firstWhere((s) => s.id == 'speaker_1');
      final speaker2 = speakers.firstWhere((s) => s.id == 'speaker_2');

      expect(speaker1.isCurrentSpeaker, false);
      expect(speaker2.isCurrentSpeaker, true);
    });
  });
}
