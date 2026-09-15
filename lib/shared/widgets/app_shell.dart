import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/vision/vision_screen.dart';
import '../../features/hearing/hearing_screen.dart';
import '../../features/communication/communication_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/safety/sos_screen.dart';
import '../services/settings_service.dart';
import 'sensor_indicator.dart';
import 'status_badges.dart';
import 'safety_boundary.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    SafetyBoundary.wrap(const VisionScreen(), 'Vision Assist'),
    SafetyBoundary.wrap(const HearingScreen(), 'Hearing Assist'),
    SafetyBoundary.wrap(const CommunicationScreen(), 'Communication Assist'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsService>(context, listen: false);
      if (settings.preferredMode != null) {
        if (settings.preferredMode == 'Vision Assist') {
          setState(() => _currentIndex = 0);
        } else if (settings.preferredMode == 'Hearing Assist') {
          setState(() => _currentIndex = 1);
        } else if (settings.preferredMode == 'Communication Assist') {
          setState(() => _currentIndex = 2);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TheOne', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const OfflineBadge(),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: SensorIndicator(
              isCameraActive: _currentIndex == 0,
              isMicActive: _currentIndex == 1,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
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
            label: 'Communication Assist',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red[900],
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SosScreen()),
        ),
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: const Text(
          "SOS",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
