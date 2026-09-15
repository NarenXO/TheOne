import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Edge Processing'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: const [
            Icon(Icons.security, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Designed for Local & Private Processing',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            _PrivacyItem(
              icon: Icons.cloud_off,
              title: 'Zero Cloud Calls',
              body: 'All AI models, OCR, STT, and speech processing run strictly on-device. No visual or audio data is ever uploaded to remote servers.',
            ),
            _PrivacyItem(
              icon: Icons.videocam,
              title: 'Camera & Mic Indicators',
              body: 'Active visual indicators inform you whenever the camera or microphone is processing data. Sensors are never accessed silently.',
            ),
            _PrivacyItem(
              icon: Icons.memory,
              title: 'Temporary Session Memory',
              body: 'Session memory only keeps temporary contextual information during active usage. You can wipe it anytime using the Clear Session button.',
            ),
            _PrivacyItem(
              icon: Icons.location_on,
              title: 'On-Demand Location for SOS',
              body: 'Location is never continuously tracked. GPS coordinates are requested strictly when you trigger Emergency SOS or near critical battery threshold.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.deepPurple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
