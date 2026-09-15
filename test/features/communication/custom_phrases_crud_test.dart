import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/communication/models/phrase_item.dart';

void main() {
  group('Custom Phrases CRUD Test', () {
    test('should create custom phrase with correct properties', () {
      final customPhrase = PhraseItem(
        id: 'custom_123',
        category: 'custom',
        textEn: 'My custom phrase',
        textTa: 'எனது தனிப்பயன் சொற்றொடர்',
        keywords: ['custom', 'my'],
        isCustom: true,
      );

      expect(customPhrase.id, 'custom_123');
      expect(customPhrase.category, 'custom');
      expect(customPhrase.textEn, 'My custom phrase');
      expect(customPhrase.textTa, 'எனது தனிப்பயன் சொற்றொடர்');
      expect(customPhrase.isCustom, true);
      expect(customPhrase.keywords, contains('custom'));
      expect(customPhrase.keywords, contains('my'));
    });

    test('should update custom phrase properties', () {
      final originalPhrase = PhraseItem(
        id: 'custom_123',
        category: 'custom',
        textEn: 'Original text',
        textTa: 'அசல் உரை',
        keywords: ['original'],
        isCustom: true,
      );

      final updatedPhrase = originalPhrase.copyWith(
        textEn: 'Updated text',
        textTa: 'புதுப்பித்த உரை',
        keywords: ['updated'],
      );

      expect(updatedPhrase.id, 'custom_123'); // ID should remain same
      expect(updatedPhrase.textEn, 'Updated text');
      expect(updatedPhrase.textTa, 'புதுப்பித்த உரை');
      expect(updatedPhrase.keywords, contains('updated'));
      expect(updatedPhrase.keywords, isNot(contains('original')));
    });

    test('should mark custom phrase as used', () {
      final customPhrase = PhraseItem(
        id: 'custom_123',
        category: 'custom',
        textEn: 'My custom phrase',
        textTa: 'எனது தனிப்பயன் சொற்றொடர்',
        keywords: ['custom'],
        isCustom: true,
        usageCount: 0,
      );

      expect(customPhrase.usageCount, 0);
      expect(customPhrase.lastUsedAt, isNull);

      customPhrase.markAsUsed();

      expect(customPhrase.usageCount, 1);
      expect(customPhrase.lastUsedAt, isNotNull);
    });

    test('should serialize and deserialize custom phrase', () {
      final customPhrase = PhraseItem(
        id: 'custom_123',
        category: 'custom',
        textEn: 'My custom phrase',
        textTa: 'எனது தனிப்பயன் சொற்றொடர்',
        keywords: ['custom'],
        isCustom: true,
        usageCount: 5,
      );

      final json = customPhrase.toJson();
      expect(json['is_custom'], true);
      expect(json['usage_count'], 5);

      final deserialized = PhraseItem.fromJson(json);
      expect(deserialized.id, customPhrase.id);
      expect(deserialized.isCustom, true);
      expect(deserialized.usageCount, 5);
    });

    test('should handle custom phrase with optional Tamil text', () {
      final customPhrase = PhraseItem(
        id: 'custom_456',
        category: 'custom',
        textEn: 'English only phrase',
        textTa: 'English only phrase', // Same as English when Tamil not provided
        keywords: ['english'],
        isCustom: true,
      );

      expect(customPhrase.textEn, 'English only phrase');
      expect(customPhrase.textTa, 'English only phrase');
    });

    test('should distinguish custom from standard phrases', () {
      final standardPhrase = PhraseItem(
        id: 'std_1',
        category: 'emergency',
        textEn: 'Standard phrase',
        textTa: 'நிலையான சொற்றொடர்',
        keywords: ['standard'],
        isCustom: false,
      );

      final customPhrase = PhraseItem(
        id: 'custom_1',
        category: 'custom',
        textEn: 'Custom phrase',
        textTa: 'தனிப்பயன் சொற்றொடர்',
        keywords: ['custom'],
        isCustom: true,
      );

      expect(standardPhrase.isCustom, false);
      expect(customPhrase.isCustom, true);
    });

    test('should handle deletion simulation through copy', () {
      final customPhrase = PhraseItem(
        id: 'custom_789',
        category: 'custom',
        textEn: 'To be deleted',
        textTa: 'நீக்கப்பட வேண்டும்',
        keywords: ['delete'],
        isCustom: true,
      );

      // Simulate deletion by creating a "deleted" state
      // In real implementation, this would be removed from database
      final deletedState = customPhrase.copyWith(
        textEn: '[DELETED]',
        textTa: '[நீக்கப்பட்டது]',
      );

      expect(deletedState.textEn, '[DELETED]');
      expect(deletedState.textTa, '[நீக்கப்பட்டது]');
    });
  });
}