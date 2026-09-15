import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/communication/services/menu_matcher_service.dart';
import 'package:theone/features/communication/models/intent_result.dart';
import 'package:theone/core/models/confidence_state.dart';
import 'package:theone/core/services/ocr_service.dart';

void main() {
  group('MenuMatcherService', () {
    late MenuMatcherService matcher;

    setUp(() {
      matcher = MenuMatcherService();
    });

    test('should generate phrase from OCR with coffee and large', () {
      final ocrResults = [
        OcrResult(text: 'HOT', confidence: 0.95),
        OcrResult(text: 'COFFEE', confidence: 0.92),
        OcrResult(text: 'LARGE', confidence: 0.88),
        OcrResult(text: 'MENU', confidence: 0.85),
      ];

      final result = matcher.generatePhraseFromOcr(ocrResults);

      expect(result.intent, Intent.orderFood);
      expect(result.state, ConfidenceState.verified);
      expect(result.generatedEn, contains('large'));
      expect(result.generatedEn, contains('coffee'));
      expect(result.confidence, greaterThanOrEqualTo(0.85));
    });

    test('should return insufficient for empty OCR results', () {
      final ocrResults = <OcrResult>[];

      final result = matcher.generatePhraseFromOcr(ocrResults);

      expect(result.state, ConfidenceState.insufficient);
      expect(result.generatedEn, contains('No menu items detected'));
    });

    test('should return insufficient when no food keywords detected', () {
      final ocrResults = [
        OcrResult(text: 'HELLO', confidence: 0.95),
        OcrResult(text: 'WORLD', confidence: 0.92),
        OcrResult(text: 'TEST', confidence: 0.88),
      ];

      final result = matcher.generatePhraseFromOcr(ocrResults);

      expect(result.state, ConfidenceState.insufficient);
      expect(result.generatedEn, contains('No recognized menu items'));
    });

    test('should generate phrase with only size and drink', () {
      final ocrResults = [
        OcrResult(text: 'MEDIUM', confidence: 0.90),
        OcrResult(text: 'TEA', confidence: 0.88),
      ];

      final result = matcher.generatePhraseFromOcr(ocrResults);

      expect(result.intent, Intent.orderFood);
      expect(result.state, ConfidenceState.verified);
      expect(result.generatedEn, contains('medium'));
      expect(result.generatedEn, contains('tea'));
    });

    test('should generate phrase with only food item', () {
      final ocrResults = [
        OcrResult(text: 'Samosa', confidence: 0.92),
      ];

      final result = matcher.generatePhraseFromOcr(ocrResults);

      expect(result.intent, Intent.orderFood);
      expect(result.state, ConfidenceState.verified);
      expect(result.generatedEn, contains('samosa'));
    });

    test('should generate phrase with only drink item', () {
      final ocrResults = [
        OcrResult(text: 'WATER', confidence: 0.95),
      ];

      final result = matcher.generatePhraseFromOcr(ocrResults);

      expect(result.intent, Intent.orderFood);
      expect(result.state, ConfidenceState.verified);
      expect(result.generatedEn, contains('water'));
    });

    test('should handle case insensitive matching', () {
      final ocrResults = [
        OcrResult(text: 'Coffee', confidence: 0.90),
        OcrResult(text: 'Large', confidence: 0.88),
      ];

      final result = matcher.generatePhraseFromOcr(ocrResults);

      expect(result.intent, Intent.orderFood);
      expect(result.state, ConfidenceState.verified);
    });

    test('should handle mixed case OCR results', () {
      final ocrResults = [
        OcrResult(text: 'CoFfEe', confidence: 0.85),
        OcrResult(text: 'SmAlL', confidence: 0.82),
      ];

      final result = matcher.generatePhraseFromOcr(ocrResults);

      expect(result.intent, Intent.orderFood);
      expect(result.state, ConfidenceState.verified);
    });

    test('should extract keywords from multi-word OCR results', () {
      final ocrResults = [
        OcrResult(text: 'LARGE COFFEE HOT', confidence: 0.90),
      ];

      final result = matcher.generatePhraseFromOcr(ocrResults);

      expect(result.intent, Intent.orderFood);
      expect(result.state, ConfidenceState.verified);
    });

    test('should never invent food items not in OCR', () {
      final ocrResults = [
        OcrResult(text: 'LARGE', confidence: 0.90),
      ];

      final result = matcher.generatePhraseFromOcr(ocrResults);

      // Should not include specific food items if only size detected
      expect(result.generatedEn, isNot(contains('coffee')));
      expect(result.generatedEn, isNot(contains('tea')));
      expect(result.generatedEn, isNot(contains('samosa')));
    });
  });
}