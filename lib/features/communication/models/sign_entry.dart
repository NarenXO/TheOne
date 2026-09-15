class SignEntry {
  final String id;
  final String nameEn;
  final String nameTa;
  final String category;
  final List<String> keywords;
  final String videoAsset;
  final String description;

  SignEntry({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.category,
    required this.keywords,
    required this.videoAsset,
    required this.description,
  });

  factory SignEntry.fromJson(Map<String, dynamic> json) {
    return SignEntry(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameTa: json['name_ta'] as String,
      category: json['category'] as String,
      keywords: (json['keywords'] as List<dynamic>).map((e) => e as String).toList(),
      videoAsset: json['video_asset'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_ta': nameTa,
      'category': category,
      'keywords': keywords,
      'video_asset': videoAsset,
      'description': description,
    };
  }

  bool matchesQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return nameEn.toLowerCase().contains(lowerQuery) ||
           nameTa.toLowerCase().contains(lowerQuery) ||
           keywords.any((kw) => kw.toLowerCase().contains(lowerQuery));
  }
}