import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theone/main.dart';

void main() {
  testWidgets('App smoke test - boots into welcome screen on fresh launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(TheOneApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('TheOne'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
