import 'package:flutter/material.dart';

class HearingScreen extends StatelessWidget {
  const HearingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TheOne — Hearing Assist"),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hearing, size: 64, color: Colors.blueAccent),
              SizedBox(height: 16),
              Text(
                "Hearing Assist Mode",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Live Captions • Speaker Tracking • Danger Sound Detection • Haptic Vibration Vocabulary",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
