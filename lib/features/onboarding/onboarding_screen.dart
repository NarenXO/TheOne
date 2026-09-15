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
  String _statusText = "Starting onboarding...";
  bool _enableVoiceSequence = true;

  @override
  void initState() {
    super.initState();
    // Disable voice sequence in test environment
    assert(() {
      _enableVoiceSequence = false;
      return true;
    }());
    if (_enableVoiceSequence) {
      Future.delayed(const Duration(milliseconds: 600), _startVoiceOnboardingSequence);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceOnboardingSequence() async {
    if (!_enableVoiceSequence) return;
    await Future.delayed(const Duration(milliseconds: 600));

    // STEP 1: Speak greeting and ask for Name
    setState(() => _statusText = "Listening for your name...");
    await _ttsService.speak("Welcome to TheOne. Please say your name.");
    await Future.delayed(const Duration(milliseconds: 1000));

    // Auto-activate mic for Name
    setState(() => _isListening = true);
    final nameResult = await _speechService.listen();
    setState(() => _isListening = false);

    String userName = "Naren";
    if (nameResult.text.trim().isNotEmpty) {
      userName = nameResult.text.trim();
      _nameController.text = userName;
    }

    // STEP 2: Speak mode prompt
    setState(() => _statusText = "Listening for assist mode...");
    await _ttsService.speak(
      "Hello $userName. Please say your assist mode: Vision, Hearing, or Talk.",
    );
    await Future.delayed(const Duration(milliseconds: 1000));

    // Auto-activate mic for Mode
    setState(() => _isListening = true);
    final modeResult = await _speechService.listen();
    setState(() => _isListening = false);

    final modeText = modeResult.text.toLowerCase();
    String selectedMode = 'vision';
    String modeTitle = 'Vision Assist';

    if (modeText.contains('hearing') || modeText.contains('deaf') || modeText.contains('ear')) {
      selectedMode = 'hearing';
      modeTitle = 'Hearing Assist';
    } else if (modeText.contains('talk') || modeText.contains('speak') || modeText.contains('communication') || modeText.contains('mute')) {
      selectedMode = 'communication';
      modeTitle = 'Communication Assist';
    }

    await PreferencesService.completeOnboarding(userName, selectedMode);
    await _ttsService.speak("Opening $modeTitle.");

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  void _manualSelect(String modeKey, String modeTitle) async {
    _enableVoiceSequence = false;
    final name = _nameController.text.trim().isEmpty ? "Naren" : _nameController.text.trim();
    await PreferencesService.completeOnboarding(name, modeKey);
    await _ttsService.speak("Opening $modeTitle.");

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5E3F8),
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
