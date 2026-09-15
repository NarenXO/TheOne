import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
      home: const AppShell(),
    );
  }
}
