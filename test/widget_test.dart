import 'package:flutter_test/flutter_test.dart';

import 'package:theone/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TheOneApp());

    // Verify that the app builds without errors
    expect(find.byType(TheOneApp), findsOneWidget);
  });
}
