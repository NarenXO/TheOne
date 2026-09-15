import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/communication/ui/widgets/emergency_phrase_bar.dart';
import 'package:theone/features/communication/ui/widgets/confidence_badge.dart';
import 'package:theone/features/communication/ui/widgets/mock_banner.dart';
import 'package:theone/features/communication/models/phrase_item.dart';
import 'package:theone/core/models/confidence_state.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('EmergencyPhraseBar should render emergency phrases', (tester) async {
      final emergencyPhrases = [
        PhraseItem(
          id: 'em_1',
          category: 'emergency',
          textEn: 'I need help immediately.',
          textTa: 'எனக்கு உடனே உதவி தேவை.',
          keywords: ['help', 'emergency'],
        ),
      ];

      var tappedPhrase = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyPhraseBar(
              emergencyPhrases: emergencyPhrases,
              onPhraseTap: (phrase) => tappedPhrase = phrase.id,
            ),
          ),
        ),
      );

      expect(find.text('I need help immediately.'), findsOneWidget);
      expect(find.text('எனக்கு உடனே உதவி தேவை.'), findsOneWidget);
    });

    testWidgets('EmergencyPhraseBar should handle empty list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyPhraseBar(
              emergencyPhrases: [],
              onPhraseTap: (phrase) {},
            ),
          ),
        ),
      );

      expect(find.byType(EmergencyPhraseBar), findsOneWidget);
    });

    testWidgets('ConfidenceBadge should render verified state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfidenceBadge(
              state: ConfidenceState.verified,
              confidence: 0.9,
            ),
          ),
        ),
      );

      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('ConfidenceBadge should render uncertain state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfidenceBadge(
              state: ConfidenceState.uncertain,
              confidence: 0.6,
            ),
          ),
        ),
      );

      expect(find.text('Uncertain'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('ConfidenceBadge should render insufficient state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfidenceBadge(
              state: ConfidenceState.insufficient,
            ),
          ),
        ),
      );

      expect(find.text('Insufficient'), findsOneWidget);
    });

    testWidgets('ConfidenceBadge should render conflict state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfidenceBadge(
              state: ConfidenceState.conflict,
            ),
          ),
        ),
      );

      expect(find.text('Conflict'), findsOneWidget);
    });

    testWidgets('ConfidenceBadge should render custom message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfidenceBadge(
              state: ConfidenceState.uncertain,
              message: 'Please hold your hand steady.',
            ),
          ),
        ),
      );

      expect(find.text('Please hold your hand steady.'), findsOneWidget);
    });

    testWidgets('MockBanner should render with default message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const MockBanner(),
          ),
        ),
      );

      expect(find.text('DEMO / MOCK MODE'), findsOneWidget);
    });

    testWidgets('MockBanner should render with custom message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const MockBanner(
              message: 'CUSTOM MESSAGE',
            ),
          ),
        ),
      );

      expect(find.text('CUSTOM MESSAGE'), findsOneWidget);
    });

    testWidgets('ConfidenceBadge should show low confidence warning', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfidenceBadge(
              state: ConfidenceState.uncertain,
              confidence: 0.4,
              message: 'Please hold your hand steady.',
            ),
          ),
        ),
      );

      expect(find.text('Please hold your hand steady.'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });
  });
}
