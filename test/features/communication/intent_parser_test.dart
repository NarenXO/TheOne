import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/communication/services/intent_parser_service.dart';
import 'package:theone/features/communication/models/intent_result.dart';
import 'package:theone/core/models/confidence_state.dart';

void main() {
  group('IntentParserService', () {
    late IntentParserService parser;

    setUp(() {
      parser = IntentParserService();
    });

    test('should parse Tanglish location query correctly', () {
      const input = 'registration enga irukku nu kekkanum';
      final result = parser.parse(input);

      expect(result.intent, Intent.askLocation);
      expect(result.state, ConfidenceState.verified);
      expect(result.confidence, greaterThanOrEqualTo(0.85));
      expect(result.generatedEn, contains('where'));
      expect(result.generatedTa, contains('எங்குள்ளது'));
    });

    test('should parse food order with Tanglish correctly', () {
      const input = 'medium chai venum';
      final result = parser.parse(input);

      expect(result.intent, Intent.orderFood);
      expect(result.state, ConfidenceState.verified);
      expect(result.confidence, greaterThanOrEqualTo(0.85));
      expect(result.generatedEn, contains('medium chai'));
      expect(result.generatedTa, contains('சாய்'));
    });

    test('should return insufficient for empty input', () {
      const input = '';
      final result = parser.parse(input);

      expect(result.intent, Intent.unknown);
      expect(result.state, ConfidenceState.insufficient);
      expect(result.confidence, 0.0);
    });

    test('should return insufficient for unknown gibberish', () {
      const input = 'xyzabc123 nonsense input';
      final result = parser.parse(input);

      expect(result.intent, Intent.unknown);
      expect(result.state, equals(ConfidenceState.insufficient)
        .or(equals(ConfidenceState.uncertain)));
    });

    test('should parse price query correctly', () {
      const input = 'evvalavu cost vilai';
      final result = parser.parse(input);

      expect(result.intent, Intent.price);
      expect(result.state, ConfidenceState.verified);
      expect(result.generatedEn, contains('cost'));
    });

    test('should parse emergency request correctly', () {
      const input = 'help emergency udhavi';
      final result = parser.parse(input);

      expect(result.intent, equals(Intent.requestHelp)
        .or(equals(Intent.emergency)));
      expect(result.state, ConfidenceState.verified);
      expect(result.confidence, greaterThan(0.8));
    });

    test('should parse greeting correctly', () {
      const input = 'hello vanakkam morning';
      final result = parser.parse(input);

      expect(result.intent, Intent.greeting);
      expect(result.state, ConfidenceState.verified);
    });

    test('should parse thanks correctly', () {
      const input = 'thank you nandri';
      final result = parser.parse(input);

      expect(result.intent, Intent.thanks);
      expect(result.state, ConfidenceState.verified);
    });

    test('should parse repeat request correctly', () {
      const input = 'repeat again marubadiyum';
      final result = parser.parse(input);

      expect(result.intent, Intent.repeat);
      expect(result.state, ConfidenceState.verified);
    });

    test('should parse wait request correctly', () {
      const input = 'wait porunga irunga';
      final result = parser.parse(input);

      expect(result.intent, Intent.wait);
      expect(result.state, ConfidenceState.verified);
    });

    test('should parse direction query correctly', () {
      const input = 'left right direction idathu';
      final result = parser.parse(input);

      expect(result.intent, Intent.direction);
      expect(result.state, ConfidenceState.verified);
    });
  });
}