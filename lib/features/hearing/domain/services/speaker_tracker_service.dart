import '../models/hearing_speaker.dart';

class SpeakerTrackerService {
  final Map<String, HearingSpeaker> _speakers = {};
  String? _currentSpeakerId;
  DateTime? _lastActivityTime;
  static const Duration _inactivityTimeout = Duration(seconds: 5);

  HearingSpeaker getOrCreateSpeaker(String speakerId) {
    if (_speakers.containsKey(speakerId)) {
      return _speakers[speakerId]!;
    }

    final index = _speakers.length;
    final speaker = HearingSpeaker.create(
      id: speakerId,
      index: index,
    );
    _speakers[speakerId] = speaker;
    return speaker;
  }

  void setCurrentSpeaker(String speakerId) {
    _currentSpeakerId = speakerId;
    _lastActivityTime = DateTime.now();

    _updateCurrentSpeakerFlags();
  }

  void _updateCurrentSpeakerFlags() {
    for (final speakerId in _speakers.keys) {
      final speaker = _speakers[speakerId]!;
      final isCurrent = speakerId == _currentSpeakerId;
      _speakers[speakerId] = speaker.copyWith(isCurrentSpeaker: isCurrent);
    }
  }

  void checkInactivity() {
    if (_lastActivityTime == null) return;

    final now = DateTime.now();
    if (now.difference(_lastActivityTime!) > _inactivityTimeout) {
      _currentSpeakerId = null;
      _updateCurrentSpeakerFlags();
    }
  }

  void renameSpeaker(String speakerId, String customName) {
    if (_speakers.containsKey(speakerId)) {
      final speaker = _speakers[speakerId]!;
      _speakers[speakerId] = speaker.copyWith(customName: customName);
    }
  }

  HearingSpeaker? getSpeaker(String speakerId) {
    return _speakers[speakerId];
  }

  List<HearingSpeaker> getAllSpeakers() {
    return _speakers.values.toList();
  }

  HearingSpeaker? get currentSpeaker {
    if (_currentSpeakerId == null) return null;
    return _speakers[_currentSpeakerId];
  }

  int get speakerCount => _speakers.length;
}
