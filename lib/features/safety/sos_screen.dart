import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../core/safety/sos_service.dart';
import '../../shared/services/emergency_contact_store.dart';
import '../../shared/widgets/big_button.dart';
import 'emergency_contact_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final SosService _sosService = SosService();
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  bool _isSending = false;
  String? _statusMessage;

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

  Future<void> _triggerSos() async {
    final contactStore = Provider.of<EmergencyContactStore>(context, listen: false);
    final phone = contactStore.contact?.phoneNumber;

    setState(() {
      _isSending = true;
      _statusMessage = null;
    });

    final success = await _sosService.sendSosSms(contact: phone);

    if (mounted) {
      setState(() {
        _isSending = false;
        _statusMessage = success
            ? 'SOS SMS COMPOSER OPENED — Please confirm send in your Messages app.'
            : 'SOS COULD NOT BE SENT. Please verify SMS capabilities.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactStore = Provider.of<EmergencyContactStore>(context);
    final hasContact = contactStore.hasContact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Safety'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.battery_alert, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Battery: $_batteryLevel%', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (_batteryLevel <= 15)
                          const Chip(
                            label: Text('LOW', style: TextStyle(color: Colors.white, fontSize: 11)),
                            backgroundColor: Colors.red,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    tileColor: Colors.grey.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.contact_phone, color: Colors.blue),
                    title: Text(
                      hasContact ? contactStore.contact!.name : 'No Contact Set',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      hasContact ? contactStore.contact!.phoneNumber : 'Tap to configure emergency contact',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmergencyContactScreen()),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
              Column(
                children: [
                  BigButton(
                    label: _isSending ? 'Sending SOS...' : 'SEND SOS NOW',
                    icon: Icons.emergency,
                    backgroundColor: Colors.red[900],
                    minHeight: 72,
                    onPressed: _isSending ? null : _triggerSos,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SOS alert includes your battery state and emergency Google Maps GPS location.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
