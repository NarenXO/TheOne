import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/communication/models/sign_entry.dart';

void main() {
  group('Sign Search Test', () {
    late List<SignEntry> testSigns;

    setUp(() {
      testSigns = [
        SignEntry(
          id: 'sign_hello',
          nameEn: 'Hello',
          nameTa: 'வணக்கம்',
          category: 'greetings',
          keywords: ['hello', 'hi', 'greet', 'vanakkam'],
          videoAsset: 'assets/signs/hello.mp4',
          description: 'Open hand waving side to side near temple.',
        ),
        SignEntry(
          id: 'sign_help',
          nameEn: 'Help',
          nameTa: 'உதவி',
          category: 'emergency',
          keywords: ['help', 'assist', 'udhavi', 'emergency'],
          videoAsset: 'assets/signs/help.mp4',
          description: 'Closed fist with thumb up on opposite palm.',
        ),
        SignEntry(
          id: 'sign_thankyou',
          nameEn: 'Thank you',
          nameTa: 'நன்றி',
          category: 'greetings',
          keywords: ['thank', 'thanks', 'nandri'],
          videoAsset: 'assets/signs/thankyou.mp4',
          description: 'Flat palm touches chin then extends forward.',
        ),
        SignEntry(
          id: 'sign_water',
          nameEn: 'Water',
          nameTa: 'தண்ணீர்',
          category: 'food',
          keywords: ['water', 'thanni', 'drink'],
          videoAsset: 'assets/signs/water.mp4',
          description: 'W-handshape tapping lower lip.',
        ),
      ];
    });

    test('should match signs by partial English name', () {
      final query = 'hel';
      final results = testSigns.where((sign) => sign.matchesQuery(query)).toList();
      
      expect(results.length, 2); // Hello and Help
      expect(results.map((s) => s.id), contains('sign_hello'));
      expect(results.map((s) => s.id), contains('sign_help'));
    });

    test('should match signs by exact English name', () {
      final query = 'Hello';
      final results = testSigns.where((sign) => sign.matchesQuery(query)).toList();
      
      expect(results.length, 1);
      expect(results[0].id, 'sign_hello');
    });

    test('should match signs by Tamil name', () {
      final query = 'வணக்கம்';
      final results = testSigns.where((sign) => sign.matchesQuery(query)).toList();
      
      expect(results.length, 1);
      expect(results[0].id, 'sign_hello');
    });

    test('should match signs by keywords', () {
      final query = 'vanakkam';
      final results = testSigns.where((sign) => sign.matchesQuery(query)).toList();
      
      expect(results.length, 1);
      expect(results[0].id, 'sign_hello');
    });

    test('should filter by category emergency', () {
      final emergencySigns = testSigns.where((s) => s.category == 'emergency').toList();
      
      expect(emergencySigns.length, 1);
      expect(emergencySigns[0].id, 'sign_help');
    });

    test('should filter by category greetings', () {
      final greetingSigns = testSigns.where((s) => s.category == 'greetings').toList();
      
      expect(greetingSigns.length, 2);
      expect(greetingSigns.map((s) => s.id), contains('sign_hello'));
      expect(greetingSigns.map((s) => s.id), contains('sign_thankyou'));
    });

    test('should be case insensitive', () {
      final query = 'HELLO';
      final results = testSigns.where((sign) => sign.matchesQuery(query)).toList();
      
      expect(results.length, 1);
      expect(results[0].id, 'sign_hello');
    });

    test('should return empty for no matches', () {
      final query = 'xyz123';
      final results = testSigns.where((sign) => sign.matchesQuery(query)).toList();
      
      expect(results, isEmpty);
    });

    test('should match partial keyword matches', () {
      final query = 'th';
      final results = testSigns.where((sign) => sign.matchesQuery(query)).toList();
      
      expect(results.length, 2); // Thank you and Water (both contain 'th')
    });
  });
}