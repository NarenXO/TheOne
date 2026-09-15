import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theone/main.dart';

void main() {
  testWidgets('App smoke test - boots into main screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TheOneApp(prefs: null));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Vision'), findsOneWidget);
    expect(find.text('Hearing'), findsOneWidget);
    expect(find.text('Talk'), findsOneWidget);
  });
}
