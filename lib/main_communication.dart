import 'package:flutter/material.dart';
import 'package:theone/features/communication/ui/communication_assist_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CommunicationTestApp());
}

class CommunicationTestApp extends StatelessWidget {
  const CommunicationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TheOne - Communication Assist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const CommunicationAssistScreen(),
    );
  }
}
