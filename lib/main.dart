import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'shared/theme/app_theme.dart';
import 'shared/services/settings_service.dart';
import 'shared/services/emergency_contact_store.dart';
import 'shared/services/session_service.dart';
import 'shared/widgets/app_shell.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Request runtime permissions
  await [
    Permission.camera,
    Permission.microphone,
    Permission.location,
  ].request();

  runApp(TheOneApp(prefs: prefs));
}

class TheOneApp extends StatelessWidget {
  final SharedPreferences? prefs;

  const TheOneApp({super.key, this.prefs});

  @override
  Widget build(BuildContext context) {
    if (prefs != null) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsService(prefs!)),
          ChangeNotifierProvider(create: (_) => EmergencyContactStore(prefs!)),
          ChangeNotifierProvider(create: (_) => SessionService()),
        ],
        child: const _TheOneAppContent(),
      );
    }

    return const _TheOneAppContent();
  }
}

class _TheOneAppContent extends StatelessWidget {
  const _TheOneAppContent();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);

    return MaterialApp(
      title: 'TheOne Accessibility Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(
        textScale: settings.textScale,
        highContrast: settings.highContrast,
      ),
      darkTheme: AppTheme.dark(
        textScale: settings.textScale,
        highContrast: settings.highContrast,
      ),
      themeMode: ThemeMode.system,
      home: settings.onboardingComplete
          ? const AppShell()
          : const OnboardingWelcomeScreen(),
    );
  }
}
