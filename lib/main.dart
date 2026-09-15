import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/storage/preferences_service.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'shared/widgets/app_shell.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request CAMERA, MICROPHONE, and LOCATION permissions at app startup
  await [
    Permission.camera,
    Permission.microphone,
    Permission.location,
  ].request();
  
  runApp(const TheOneApp());
}

class TheOneApp extends StatelessWidget {
  const TheOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TheOne Accessibility Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: FutureBuilder<bool>(
        future: PreferencesService.isFirstLaunch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: Color(0xFFD5E3F8),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data! ? const OnboardingScreen() : const AppShell();
        },
      ),
    );
  }
}
