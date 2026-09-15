import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theone/shared/services/settings_service.dart';
import 'package:theone/shared/services/emergency_contact_store.dart';
import 'package:theone/shared/services/session_service.dart';
import 'package:theone/shared/widgets/big_button.dart';
import 'package:theone/shared/widgets/sensor_indicator.dart';
import 'package:theone/shared/widgets/error_card.dart';
import 'package:theone/shared/widgets/status_badges.dart';
import 'package:theone/features/onboarding/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Unit Tests - Services', () {
    test('SettingsService - Default values and state updates', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);

      expect(settings.textScale, 1.0);
      expect(settings.highContrast, false);
      expect(settings.hapticsEnabled, true);
      expect(settings.batterySaver, false);
      expect(settings.onboardingComplete, false);

      await settings.setTextScale(1.4);
      expect(settings.textScale, 1.4);

      await settings.setHighContrast(true);
      expect(settings.highContrast, true);

      await settings.setPreferredMode('Vision Assist');
      expect(settings.preferredMode, 'Vision Assist');

      await settings.setOnboardingComplete(true);
      expect(settings.onboardingComplete, true);
    });

    test('EmergencyContactStore - Validation and Saving', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = EmergencyContactStore(prefs);

      expect(EmergencyContactStore.validatePhone('911'), isTrue);
      expect(EmergencyContactStore.validatePhone('+91 9876543210'), isTrue);
      expect(EmergencyContactStore.validatePhone('(123) 456-7890'), isTrue);
      expect(EmergencyContactStore.validatePhone('12'), isFalse);
      expect(EmergencyContactStore.validatePhone('invalid_phone'), isFalse);

      final saved = await store.saveContact(
        name: 'Doctor Jane',
        phoneNumber: '+19876543210',
      );
      expect(saved, isTrue);
      expect(store.hasContact, isTrue);
      expect(store.contact?.name, 'Doctor Jane');
      expect(store.contact?.phoneNumber, '+19876543210');

      await store.clearContact();
      expect(store.hasContact, isFalse);
      expect(store.contact, isNull);
    });

    test('SessionService - Event logging and memory clearing', () {
      final session = SessionService();
      expect(session.count, 0);

      session.addEvent('OCR_SCAN', 'ROOM 204');
      session.addEvent('SPEECH_COMMAND', 'Where is the exit?');
      expect(session.count, 2);

      session.clearSession();
      expect(session.count, 0);
    });
  });

  group('Widget Tests - Shared UI', () {
    testWidgets('BigButton renders label and triggers onPressed callback', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BigButton(
              label: 'Emergency Alert',
              icon: Icons.warning,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Emergency Alert'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);

      await tester.tap(find.text('Emergency Alert'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('SensorIndicator renders camera and mic states accurately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SensorIndicator(
              isCameraActive: true,
              isMicActive: false,
            ),
          ),
        ),
      );

      expect(find.text('CAMERA ACTIVE'), findsOneWidget);
      expect(find.text('MIC OFF'), findsOneWidget);
    });

    testWidgets('ErrorCard displays information and retry action', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorCard(
              title: 'Camera Sensor Inaccessible',
              whatHappened: 'Another application is using the camera hardware.',
              whatUserCanDo: 'Close background apps and retry.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Camera Sensor Inaccessible'), findsOneWidget);
      expect(find.text('Another application is using the camera hardware.'), findsOneWidget);
      expect(find.text('Close background apps and retry.'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('StatusBadges display Offline Ready', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OfflineBadge(),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Offline Ready'), findsOneWidget);
    });
  });

  group('Widget Tests - Onboarding Flow', () {
    testWidgets('OnboardingScreen renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(find.text('TheOne'), findsOneWidget);
      expect(find.text('Your Name'), findsOneWidget);
    });

    testWidgets('OnboardingScreen renders all 3 mode buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(find.text('VISION ASSIST'), findsOneWidget);
      expect(find.text('HEARING ASSIST'), findsOneWidget);
      expect(find.text('COMMUNICATION ASSIST'), findsOneWidget);
    });
  });
}
