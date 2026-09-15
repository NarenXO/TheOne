import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'shared/widgets/app_shell.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: const AppShell(),
    );
  }
}
