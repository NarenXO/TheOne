import 'package:flutter/material.dart';
import 'features/vision/vision_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const VisionScreen(),
    );
  }
}
