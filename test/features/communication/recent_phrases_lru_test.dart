import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/communication/models/phrase_item.dart';

void main() {
  group('Recent Phrases LRU Logic Test', () {
    test('should enforce LRU limit of 5 phrases', () {
      // Simulate LRU behavior with a simple list
      final recentPhrases = <String>[];
      const maxRecent = 5;

      // Add 6 phrases
      for (int i = 0; i < 6; i++) {
        final phraseId = 'phrase_$i';
        
        // Remove if already exists
        recentPhrases.remove(phraseId);
        
        // Add to front
        recentPhrases.insert(0, phraseId);
        
        // Enforce limit
        if (recentPhrases.length > maxRecent) {
          recentPhrases.removeLast();
        }
      }

      // Should have exactly 5 phrases
      expect(recentPhrases.length, 5);

      // First phrase should be evicted (LRU)
      expect(recentPhrases, isNot(contains('phrase_0')));

      // Last 5 phrases should be present, with most recent first
      expect(recentPhrases[0], 'phrase_5');
      expect(recentPhrases[1], 'phrase_4');
      expect(recentPhrases[2], 'phrase_3');
      expect(recentPhrases[3], 'phrase_2');
      expect(recentPhrases[4], 'phrase_1');
    });

    test('should maintain most-recent-first order', () {
      final recentPhrases = <String>[];
      const maxRecent = 5;

      // Add phrases in order
      for (int i = 0; i < 3; i++) {
        final phraseId = 'phrase_$i';
        recentPhrases.remove(phraseId);
        recentPhrases.insert(0, phraseId);
        
        if (recentPhrases.length > maxRecent) {
          recentPhrases.removeLast();
        }
      }

      // Should be in reverse order (most recent first)
      expect(recentPhrases[0], 'phrase_2');
      expect(recentPhrases[1], 'phrase_1');
      expect(recentPhrases[2], 'phrase_0');
    });

    test('should move existing phrase to front when re-accessed', () {
      final recentPhrases = <String>[];
      const maxRecent = 5;

      // Add initial phrases
      for (int i = 0; i < 3; i++) {
        final phraseId = 'phrase_$i';
        recentPhrases.remove(phraseId);
        recentPhrases.insert(0, phraseId);
        
        if (recentPhrases.length > maxRecent) {
          recentPhrases.removeLast();
        }
      }

      // Re-access phrase_0 (should move to front)
      final phraseId = 'phrase_0';
      recentPhrases.remove(phraseId);
      recentPhrases.insert(0, phraseId);

      expect(recentPhrases[0], 'phrase_0');
      expect(recentPhrases[1], 'phrase_2');
      expect(recentPhrases[2], 'phrase_1');
    });

    test('should handle empty list', () {
      final recentPhrases = <String>[];
      expect(recentPhrases, isEmpty);
    });

    test('should track usage count in PhraseItem', () {
      final phrase = PhraseItem(
        id: 'test_phrase',
        category: 'test',
        textEn: 'Test',
        textTa: 'சோதனை',
        keywords: ['test'],
      );

      expect(phrase.usageCount, 0);

      phrase.markAsUsed();
      expect(phrase.usageCount, 1);
      expect(phrase.lastUsedAt, isNotNull);

      phrase.markAsUsed();
      expect(phrase.usageCount, 2);
    });
  });
}