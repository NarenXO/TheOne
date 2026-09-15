class HapticPatterns {
  static const List<int> speechDetected = [50];

  static const List<int> dangerSound = [0, 200, 100, 200, 100, 400];

  static const List<int> uncertainState = [0, 100, 50, 100];

  static const List<int> conflictState = [0, 150, 100, 150, 100, 150];

  static List<int> getPatternForType(HapticPatternType type) {
    switch (type) {
      case HapticPatternType.speechDetected:
        return speechDetected;
      case HapticPatternType.dangerSound:
        return dangerSound;
      case HapticPatternType.uncertainState:
        return uncertainState;
      case HapticPatternType.conflictState:
        return conflictState;
    }
  }
}

enum HapticPatternType {
  speechDetected,
  dangerSound,
  uncertainState,
  conflictState,
}
