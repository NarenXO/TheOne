import 'package:flutter/material.dart';
import '../../core/safety/sos_service.dart';
import '../../features/vision/vision_screen.dart';
import '../../features/hearing/hearing_screen.dart';
import '../../features/communication/communication_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final SosService _sosService = SosService();

  final List<Widget> _screens = const [
    VisionScreen(),
    HearingScreen(),
    CommunicationScreen(),
  ];

  Future<void> _triggerAutoSos() async {
    final smsSent = await _sosService.sendSosSms();
    final message = await _sosService.generateSosMessage();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text("Auto-SOS Alert Triggered"),
            ],
          ),
          content: Text(smsSent
              ? "SOS SMS ready — confirm send in your Messages app"
              : message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Dismiss"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 14,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_red_eye),
            label: 'Vision Assist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hearing),
            label: 'Hearing Assist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over),
            label: 'Communication',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red[900],
        onPressed: _triggerAutoSos,
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: const Text("AUTO-SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
