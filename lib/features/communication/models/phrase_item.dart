class PhraseItem {
  final String id;
  final String category;
  final String textEn;
  final String textTa;
  final List<String> keywords;
  bool isFavorite;
  final bool isCustom;
  int usageCount;
  DateTime? lastUsedAt;

  PhraseItem({
    required this.id,
    required this.category,
    required this.textEn,
    required this.textTa,
    required this.keywords,
    this.isFavorite = false,
    this.isCustom = false,
    this.usageCount = 0,
    this.lastUsedAt,
  });

  factory PhraseItem.fromJson(Map<String, dynamic> json) {
    return PhraseItem(
      id: json['id'] as String,
      category: json['category'] as String,
      textEn: json['text_en'] as String,
      textTa: json['text_ta'] as String,
      keywords: (json['keywords'] as List<dynamic>).map((e) => e as String).toList(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      isCustom: json['is_custom'] as bool? ?? false,
      usageCount: json['usage_count'] as int? ?? 0,
      lastUsedAt: json['last_used_at'] != null 
          ? DateTime.parse(json['last_used_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'text_en': textEn,
      'text_ta': textTa,
      'keywords': keywords,
      'is_favorite': isFavorite,
      'is_custom': isCustom,
      'usage_count': usageCount,
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }

  PhraseItem copyWith({
    String? id,
    String? category,
    String? textEn,
    String? textTa,
    List<String>? keywords,
    bool? isFavorite,
    bool? isCustom,
    int? usageCount,
    DateTime? lastUsedAt,
  }) {
    return PhraseItem(
      id: id ?? this.id,
      category: category ?? this.category,
      textEn: textEn ?? this.textEn,
      textTa: textTa ?? this.textTa,
      keywords: keywords ?? this.keywords,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  void markAsUsed() {
    usageCount++;
    lastUsedAt = DateTime.now();
  }
}