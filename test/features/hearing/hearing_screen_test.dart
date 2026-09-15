import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theone/features/hearing/presentation/hearing_assist_screen.dart';

void main() {
  group('HearingAssistScreen Widget Tests', () {
    testWidgets('should render hearing assist screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HearingAssistScreen(autoInitializeServices: false),
        ),
      );

      expect(find.text('Hearing Assist'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have freeze/resume button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HearingAssistScreen(autoInitializeServices: false),
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('should have rewind button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HearingAssistScreen(autoInitializeServices: false),
        ),
      );

      expect(find.byIcon(Icons.history_toggle_off), findsOneWidget);
    });

    testWidgets('should have settings button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HearingAssistScreen(autoInitializeServices: false),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should have bottom action bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HearingAssistScreen(autoInitializeServices: false),
        ),
      );

      expect(find.text('History'), findsOneWidget);
      expect(find.text('Rename Speakers'), findsOneWidget);
    });

    testWidgets('should have mock service toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HearingAssistScreen(autoInitializeServices: false),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
