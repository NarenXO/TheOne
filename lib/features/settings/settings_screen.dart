import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:vibration/vibration.dart';
import '../../shared/services/settings_service.dart';
import '../../shared/services/emergency_contact_store.dart';
import '../../shared/services/session_service.dart';
import '../safety/emergency_contact_screen.dart';
import '../safety/privacy_screen.dart';
import '../safety/sos_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Battery _battery = Battery();
  int _batteryLevel = 100;

  @override
  void initState() {
    super.initState();
    _loadBattery();
  }

  Future<void> _loadBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final contactStore = Provider.of<EmergencyContactStore>(context);
    final sessionService = Provider.of<SessionService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Section: Accessibility
          _buildSectionHeader('Accessibility & Display', Icons.accessibility),
          SwitchListTile(
            title: const Text('High Contrast Mode', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Increases border clarity and color contrast'),
            value: settings.highContrast,
            onChanged: (val) => settings.setHighContrast(val),
          ),
          ListTile(
            title: Text('Text Size Scale: ${(settings.textScale * 100).toStringAsFixed(0)}%'),
            subtitle: Slider(
              min: 0.8,
              max: 1.6,
              divisions: 8,
              value: settings.textScale,
              label: '${(settings.textScale * 100).toStringAsFixed(0)}%',
              onChanged: (val) => settings.setTextScale(val),
            ),
          ),
          const Divider(),

          // Section: Audio & Haptics
          _buildSectionHeader('Audio & Haptics', Icons.volume_up),
          ListTile(
            title: Text('Speech Rate: ${settings.speechRate.toStringAsFixed(1)}x'),
            subtitle: Slider(
              min: 0.5,
              max: 2.0,
              divisions: 6,
              value: settings.speechRate,
              label: '${settings.speechRate.toStringAsFixed(1)}x',
              onChanged: (val) => settings.setSpeechRate(val),
            ),
          ),
          SwitchListTile(
            title: const Text('Haptic Vibration Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Physical alerts for obstacles and verified answers'),
            value: settings.hapticsEnabled,
            onChanged: (val) async {
              await settings.setHapticsEnabled(val);
              if (val && await Vibration.hasVibrator()) {
                Vibration.vibrate(duration: 80);
              }
            },
          ),
          const Divider(),

          // Section: Battery & Efficiency
          _buildSectionHeader('Battery & Power', Icons.battery_charging_full),
          ListTile(
            leading: const Icon(Icons.battery_std),
            title: Text('Current Battery Level: $_batteryLevel%'),
            subtitle: Text(_batteryLevel <= 15 ? 'Battery Low' : 'Normal Power State'),
          ),
          SwitchListTile(
            title: const Text('Battery Saver Mode', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Reduces camera frame processing frequency to conserve energy'),
            value: settings.batterySaver,
            onChanged: (val) => settings.setBatterySaver(val),
          ),
          const Divider(),

          // Section: Emergency Safety
          _buildSectionHeader('Emergency Safety', Icons.emergency),
          ListTile(
            leading: const Icon(Icons.contact_phone, color: Colors.red),
            title: Text(contactStore.hasContact ? contactStore.contact!.name : 'Set Emergency Contact'),
            subtitle: Text(contactStore.hasContact ? contactStore.contact!.phoneNumber : 'Tap to configure SOS number'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmergencyContactScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: const Text('Emergency SOS Center'),
            subtitle: const Text('Trigger immediate emergency alert'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SosScreen()),
            ),
          ),
          const Divider(),

          // Section: Privacy & Session Memory
          _buildSectionHeader('Privacy & Session', Icons.shield),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy & Edge Processing Info'),
            subtitle: const Text('How your camera and mic data remain offline'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.brown),
            title: const Text('Clear Temporary Session Memory'),
            subtitle: Text('${sessionService.count} temporary session events logged'),
            trailing: OutlinedButton(
              onPressed: () {
                sessionService.clearSession();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Temporary session context cleared!')),
                );
              },
              child: const Text('Clear'),
            ),
          ),
          const Divider(),

          // Section: Developer Demo Mode
          _buildSectionHeader('Developer & Presentation', Icons.science),
          SwitchListTile(
            title: const Text('Developer Demo Mode', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Displays verified sample data for demonstration purposes'),
            value: settings.demoMode,
            onChanged: (val) => settings.setDemoMode(val),
          ),
          const Divider(),

          // Section: About
          _buildSectionHeader('About', Icons.info_outline),
          const ListTile(
            title: Text('TheOne Accessibility Assistant'),
            subtitle: Text('Version 1.0.0 (Offline Edge AI)\nSustainverse 2K26 — PS-04'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}
