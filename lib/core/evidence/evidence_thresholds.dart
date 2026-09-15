class EvidenceThresholds {
  /// Evidence with confidence >= [strong] is considered high certainty.
  static const double strong = 0.85;

  /// Evidence with confidence between [uncertainLower] and [strong] is considered uncertain.
  static const double uncertainLower = 0.60;

  /// Obstacle alert proximity thresholds (0.0 = far, 1.0 = immediately in front).
  static const double obstacleProximityClose = 0.70;
  static const double obstacleProximityMedium = 0.40;

  /// Low light threshold for camera brightness (0.0 = total darkness, 1.0 = full light).
  static const double lowLightBrightness = 0.25;

  static bool isStrong(double confidence) => confidence >= strong;

  static bool isUncertain(double confidence) =>
      confidence >= uncertainLower && confidence < strong;

  static bool isInsufficient(double confidence) =>
      confidence < uncertainLower;

  static bool isObstacleClose(double proximity) =>
      proximity >= obstacleProximityClose;

  static bool isObstacleMedium(double proximity) =>
      proximity >= obstacleProximityMedium && proximity < obstacleProximityClose;

  static bool isLowLight(double brightness) =>
      brightness < lowLightBrightness;
}
