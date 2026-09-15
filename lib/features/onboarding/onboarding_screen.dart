import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/impl/speech_input_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';
import '../../core/storage/preferences_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Naren");
  final TtsServiceImpl _ttsService = TtsServiceImpl();
  final SpeechInputServiceImpl _speechService = SpeechInputServiceImpl();

  bool _isListeningName = false;
  Timer? _welcomeTimer;

  @override
  void initState() {
    super.initState();
    _speakWelcome();
  }

  void _speakWelcome() async {
    _welcomeTimer = Timer(const Duration(milliseconds: 500), () async {
      await _ttsService.speak(
        "Welcome to TheOne. Please enter your name, then select Vision, Hearing, or Communication assist.",
      );
    });
  }

  Future<void> _listenName() async {
    setState(() => _isListeningName = true);
    final result = await _speechService.listen();
    if (result.text.trim().isNotEmpty && mounted) {
      setState(() {
        _nameController.text = result.text.trim();
        _isListeningName = false;
      });
      await _ttsService.speak("Name set to ${_nameController.text}");
    } else {
      if (mounted) setState(() => _isListeningName = false);
    }
  }

  Future<void> _selectModeAndProceed(String modeKey, String modeTitle) async {
    final name = _nameController.text.trim().isEmpty ? "Naren" : _nameController.text.trim();
    await PreferencesService.completeOnboarding(name, modeKey);
    await _ttsService.speak("Opening $modeTitle.");

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5E3F8), // light blue
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const SizedBox(height: 20),
              const Icon(Icons.accessibility_new, size: 64, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text(
                "TheOne",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Offline Multimodal Accessibility Assistant",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 36),

              // Name Input Card
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Name",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Used for ambient 'Name Called' vibration alerts",
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: "Enter your name...",
                                prefixIcon: Icon(Icons.person, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: _isListeningName ? Colors.red : AppColors.primary,
                            ),
                            icon: Icon(_isListeningName ? Icons.mic : Icons.mic_none, color: Colors.white),
                            onPressed: _listenName,
                            tooltip: "Speak Name",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              const Text(
                "Select Assist Mode",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Mode Option 1: Vision
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: () => _selectModeAndProceed('vision', 'Vision Assist'),
                icon: const Icon(Icons.visibility, size: 24),
                label: const Text("VISION ASSIST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),

              // Mode Option 2: Hearing
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: () => _selectModeAndProceed('hearing', 'Hearing Assist'),
                icon: const Icon(Icons.hearing, size: 24),
                label: const Text("HEARING ASSIST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),

              // Mode Option 3: Communication
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: () => _selectModeAndProceed('communication', 'Communication Assist'),
                icon: const Icon(Icons.record_voice_over, size: 24),
                label: const Text("COMMUNICATION ASSIST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}