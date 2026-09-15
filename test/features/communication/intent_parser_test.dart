import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/communication/services/intent_parser_service.dart';
import 'package:theone/core/models/confidence_state.dart';

void main() {
  group('IntentParserService Tests', () {
    final parser = IntentParserService();

    test('should parse Tanglish location query correctly', () {
      final result = parser.parse('registration enga irukku nu kekkanum');
      expect(result.intent.toString().toUpperCase(), contains('LOCATION'));
      expect(result.generatedEn, contains('registration'));
      expect(result.generatedTa, contains('எங்குள்ளது'));
    });

    test('should parse food order with Tanglish correctly', () {
      final result = parser.parse('medium chai venum');
      expect(result.intent.toString().toUpperCase(), contains('FOOD'));
      expect(result.generatedEn, contains('chai'));
      expect(result.generatedTa, contains('வேண்டும்'));
    });

    test('should return low confidence for unknown query', () {
      final result = parser.parse('random unknown gibberish string');
      expect(result.state, isIn([ConfidenceState.uncertain, ConfidenceState.insufficient]));
    });
  });
}