import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/communication/models/phrase_item.dart';

void main() {
  group('Favorites Test', () {
    test('should toggle favorite status', () {
      final phrase = PhraseItem(
        id: 'test_phrase',
        category: 'test',
        textEn: 'Test phrase',
        textTa: 'சோதனை சொற்றொடர்',
        keywords: ['test'],
      );

      expect(phrase.isFavorite, false);

      // Toggle to true
      final updated1 = phrase.copyWith(isFavorite: true);
      expect(updated1.isFavorite, true);

      // Toggle back to false
      final updated2 = updated1.copyWith(isFavorite: false);
      expect(updated2.isFavorite, false);
    });

    test('should maintain favorite status in copy', () {
      final phrase = PhraseItem(
        id: 'test_phrase',
        category: 'test',
        textEn: 'Test phrase',
        textTa: 'சோதனை சொற்றொடர்',
        keywords: ['test'],
        isFavorite: true,
      );

      final copy = phrase.copyWith();
      expect(copy.isFavorite, true);
    });

    test('should serialize favorite status correctly', () {
      final phrase = PhraseItem(
        id: 'test_phrase',
        category: 'test',
        textEn: 'Test phrase',
        textTa: 'சோதனை சொற்றொடர்',
        keywords: ['test'],
        isFavorite: true,
      );

      final json = phrase.toJson();
      expect(json['is_favorite'], true);

      final deserialized = PhraseItem.fromJson(json);
      expect(deserialized.isFavorite, true);
    });

    test('should handle false favorite in serialization', () {
      final phrase = PhraseItem(
        id: 'test_phrase',
        category: 'test',
        textEn: 'Test phrase',
        textTa: 'சோதனை சொற்றொடர்',
        keywords: ['test'],
        isFavorite: false,
      );

      final json = phrase.toJson();
      expect(json['is_favorite'], false);

      final deserialized = PhraseItem.fromJson(json);
      expect(deserialized.isFavorite, false);
    });

    test('should default to false when favorite not in JSON', () {
      final json = {
        'id': 'test_phrase',
        'category': 'test',
        'text_en': 'Test phrase',
        'text_ta': 'சோதனை சொற்றொடர்',
        'keywords': ['test'],
        // is_favorite missing
      };

      final phrase = PhraseItem.fromJson(json);
      expect(phrase.isFavorite, false);
    });
  });
}