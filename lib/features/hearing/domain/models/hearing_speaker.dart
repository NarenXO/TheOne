class HearingSpeaker {
  final String id;
  final String defaultLabel;
  final String customName;
  final int colorValue;
  final bool isCurrentSpeaker;

  HearingSpeaker({
    required this.id,
    required this.defaultLabel,
    this.customName = '',
    required this.colorValue,
    this.isCurrentSpeaker = false,
  });

  String get displayName => customName.isNotEmpty ? customName : defaultLabel;

  static List<int> _generateDistinctColors() {
    return [
      0xFF4CAF50,
      0xFF2196F3,
      0xFFFF9800,
      0xFF9C27B0,
      0xFFF44336,
      0xFF00BCD4,
      0xFFCDDC39,
      0xFFE91E63,
    ];
  }

  static int _getDefaultColorForIndex(int index) {
    final colors = _generateDistinctColors();
    if (index < colors.length) {
      return colors[index];
    }
    return colors[index % colors.length];
  }

  static String _getDefaultLabelForIndex(int index) {
    return 'Speaker ${index + 1}';
  }

  static HearingSpeaker create({
    required String id,
    int index = 0,
    String customName = '',
    bool isCurrentSpeaker = false,
  }) {
    return HearingSpeaker(
      id: id,
      defaultLabel: _getDefaultLabelForIndex(index),
      customName: customName,
      colorValue: _getDefaultColorForIndex(index),
      isCurrentSpeaker: isCurrentSpeaker,
    );
  }

  HearingSpeaker copyWith({
    String? id,
    String? defaultLabel,
    String? customName,
    int? colorValue,
    bool? isCurrentSpeaker,
  }) {
    return HearingSpeaker(
      id: id ?? this.id,
      defaultLabel: defaultLabel ?? this.defaultLabel,
      customName: customName ?? this.customName,
      colorValue: colorValue ?? this.colorValue,
      isCurrentSpeaker: isCurrentSpeaker ?? this.isCurrentSpeaker,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'defaultLabel': defaultLabel,
        'customName': customName,
        'colorValue': colorValue,
        'isCurrentSpeaker': isCurrentSpeaker,
      };
}
