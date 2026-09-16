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

  bool _isListening = false;
  String _statusText = "Initializing onboarding...";
  Timer? _sequenceTimer;

  @override
  void initState() {
    super.initState();
    _sequenceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _startVoiceSequence();
    });
  }

  Future<void> _startVoiceSequence() async {
    if (!mounted) return;
    setState(() => _statusText = "Listening for your name...");
    await _ttsService.speak("Welcome to TheOne. Please say your name.");

    // Listen for Name
    if (!mounted) return;
    setState(() => _isListening = true);
    final nameResult = await _speechService.listen();
    if (!mounted) return;
    setState(() => _isListening = false);

    String userName = nameResult.text.trim();
    if (userName.isNotEmpty) {
      _nameController.text = userName;
    } else {
      userName = _nameController.text.isEmpty ? "Naren" : _nameController.text;
    }

    // Ask for Mode
    if (!mounted) return;
    setState(() => _statusText = "Say Vision, Hearing, or Talk");
    await _ttsService.speak("Hello $userName. Please say your assist mode: Vision, Hearing, or Talk.");

    if (!mounted) return;
    setState(() => _isListening = true);
    final modeResult = await _speechService.listen();
    if (!mounted) return;
    setState(() => _isListening = false);

    final modeText = modeResult.text.toLowerCase();
    if (modeText.contains('vision') || modeText.contains('see') || modeText.contains('eye')) {
      _manualSelect('vision', 'Vision Assist', userName);
    } else if (modeText.contains('hearing') || modeText.contains('deaf') || modeText.contains('ear')) {
      _manualSelect('hearing', 'Hearing Assist', userName);
    } else if (modeText.contains('talk') || modeText.contains('speak') || modeText.contains('communication') || modeText.contains('mute')) {
      _manualSelect('communication', 'Communication Assist', userName);
    } else {
      if (!mounted) return;
      setState(() => _statusText = "Please tap an option below or say Vision, Hearing, or Talk");
      await _ttsService.speak("I did not catch that. Please tap one of the buttons on screen.");
    }
  }

  void _manualSelect(String modeKey, String modeTitle, [String? nameOverride]) async {
    final name = nameOverride ?? (_nameController.text.trim().isEmpty ? "Naren" : _nameController.text.trim());
    await PreferencesService.completeOnboarding(name, modeKey);
    await _ttsService.speak("Opening $modeTitle.");

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _speechService.stop();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5E3F8), // Light blue
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.accessibility_new, size: 64, color: AppColors.primary),
              const SizedBox(height: 8),
              const Text(
                "TheOne",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(_isListening ? Icons.mic : Icons.volume_up, color: _isListening ? Colors.red : AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Your Name",
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(16)),
                onPressed: () => _manualSelect('vision', 'Vision Assist'),
                icon: const Icon(Icons.visibility),
                label: const Text("VISION ASSIST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, padding: const EdgeInsets.all(16)),
                onPressed: () => _manualSelect('hearing', 'Hearing Assist'),
                icon: const Icon(Icons.hearing),
                label: const Text("HEARING ASSIST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.all(16)),
                onPressed: () => _manualSelect('communication', 'Communication Assist'),
                icon: const Icon(Icons.record_voice_over),
                label: const Text("COMMUNICATION ASSIST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
