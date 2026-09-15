import 'package:flutter/material.dart';
import '../../core/safety/sos_service.dart';
import '../../core/storage/preferences_service.dart';
import '../../features/vision/vision_screen.dart';
import '../../features/hearing/hearing_screen.dart';
import '../../features/communication/communication_screen.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final SosService _sosService = SosService();

  @override
  void initState() {
    super.initState();
    _loadPreferredMode();
  }

  Future<void> _loadPreferredMode() async {
    final mode = await PreferencesService.getUserMode();
    if (mounted) {
      setState(() {
        if (mode == 'vision') {
          _currentIndex = 0;
        } else if (mode == 'hearing') {
          _currentIndex = 1;
        } else if (mode == 'communication') {
          _currentIndex = 2;
        }
      });
    }
  }

  final List<Widget> _screens = const [
    VisionScreen(),
    HearingScreen(),
    CommunicationScreen(),
  ];

  Future<void> _triggerAutoSos() async {
    final sent = await _sosService.sendSosSms();
    final msg = await _sosService.generateSosMessage();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'AUTO-SOS',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.danger),
        ),
        content: Text(
          sent
              ? 'SMS composer opened with emergency message.\n\n$msg'
              : 'Could not open SMS app.\n\n$msg',
          style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility),
            label: 'Vision',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hearing),
            label: 'Hearing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over),
            label: 'Talk',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _triggerAutoSos,
        icon: const Icon(Icons.sos),
        label: const Text('AUTO-SOS', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
