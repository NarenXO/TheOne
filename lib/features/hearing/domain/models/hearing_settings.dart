enum CaptionSize {
  small,
  medium,
  large,
  extraLarge,
}

enum ContrastMode {
  transparent,
  dark,
  highContrast,
}

class HearingSettings {
  final CaptionSize captionSize;
  final ContrastMode contrastMode;
  final bool soundAlertsEnabled;
  final bool toneDetectionEnabled;
  final bool speakerTrackingEnabled;
  final bool hapticAlertsEnabled;

  HearingSettings({
    this.captionSize = CaptionSize.medium,
    this.contrastMode = ContrastMode.transparent,
    this.soundAlertsEnabled = true,
    this.toneDetectionEnabled = true,
    this.speakerTrackingEnabled = true,
    this.hapticAlertsEnabled = true,
  });

  double get captionFontSize {
    switch (captionSize) {
      case CaptionSize.small:
        return 14.0;
      case CaptionSize.medium:
        return 18.0;
      case CaptionSize.large:
        return 24.0;
      case CaptionSize.extraLarge:
        return 32.0;
    }
  }

  HearingSettings copyWith({
    CaptionSize? captionSize,
    ContrastMode? contrastMode,
    bool? soundAlertsEnabled,
    bool? toneDetectionEnabled,
    bool? speakerTrackingEnabled,
    bool? hapticAlertsEnabled,
  }) {
    return HearingSettings(
      captionSize: captionSize ?? this.captionSize,
      contrastMode: contrastMode ?? this.contrastMode,
      soundAlertsEnabled: soundAlertsEnabled ?? this.soundAlertsEnabled,
      toneDetectionEnabled: toneDetectionEnabled ?? this.toneDetectionEnabled,
      speakerTrackingEnabled: speakerTrackingEnabled ?? this.speakerTrackingEnabled,
      hapticAlertsEnabled: hapticAlertsEnabled ?? this.hapticAlertsEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'captionSize': captionSize.name,
        'contrastMode': contrastMode.name,
        'soundAlertsEnabled': soundAlertsEnabled,
        'toneDetectionEnabled': toneDetectionEnabled,
        'speakerTrackingEnabled': speakerTrackingEnabled,
        'hapticAlertsEnabled': hapticAlertsEnabled,
      };

  static HearingSettings fromMap(Map<String, dynamic> map) {
    return HearingSettings(
      captionSize: CaptionSize.values.firstWhere(
        (e) => e.name == map['captionSize'],
        orElse: () => CaptionSize.medium,
      ),
      contrastMode: ContrastMode.values.firstWhere(
        (e) => e.name == map['contrastMode'],
        orElse: () => ContrastMode.transparent,
      ),
      soundAlertsEnabled: map['soundAlertsEnabled'] ?? true,
      toneDetectionEnabled: map['toneDetectionEnabled'] ?? true,
      speakerTrackingEnabled: map['speakerTrackingEnabled'] ?? true,
      hapticAlertsEnabled: map['hapticAlertsEnabled'] ?? true,
    );
  }
}
