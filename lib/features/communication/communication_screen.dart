import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/impl/ocr_service_impl.dart';
import '../../core/services/impl/speech_input_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';
import '../../shared/theme/app_theme.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TtsServiceImpl _ttsService = TtsServiceImpl();
  final SpeechInputServiceImpl _speechService = SpeechInputServiceImpl();
  final OcrServiceImpl _ocrService = OcrServiceImpl();

  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  final TextEditingController _customPhraseController = TextEditingController();
  final TextEditingController _intentInputController = TextEditingController();

  String _lastOtherPersonReply = "";
  bool _isListeningToReply = false;
  String _reformattedSentence = "";

  // Pre-loaded contextual phrases
  final List<Map<String, String>> _greetingsPhrases = [
    {"label": "Hello!", "text": "Hello, how are you today?"},
    {"label": "Good Morning", "text": "Good morning! Hope you have a great day."},
    {"label": "Thank You", "text": "Thank you very much for your help."},
    {"label": "Excuse Me", "text": "Excuse me, I need a moment please."},
  ];

  final List<Map<String, String>> _foodPhrases = [
    {"label": "Order Chai", "text": "I would like a medium chai, please."},
    {"label": "Order Water", "text": "Could I please get a bottle of water?"},
    {"label": "Bill Please", "text": "Could you please bring me the check or bill?"},
    {"label": "Vegetarian", "text": "Is this dish vegetarian?"},
  ];

  final List<Map<String, String>> _emergencyPhrases = [
    {"label": "Need Help", "text": "I need assistance immediately."},
    {"label": "Lost / Location", "text": "I am looking for the registration desk."},
    {"label": "Medical", "text": "I am feeling unwell, please contact first aid."},
  ];

  final List<String> _customPhrases = [];
  List<Map<String, String>> _cameraSuggestedPhrases = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) {
      setState(() => _isCameraInitialized = false);
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() => _isCameraInitialized = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cameraController?.dispose();
    _ocrService.dispose();
    _customPhraseController.dispose();
    _intentInputController.dispose();
    super.dispose();
  }

  void _speakPhrase(String text) async {
    await _ttsService.speak(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.volume_up, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text("Speaking: '$text'")),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Situational Camera Assist: Photo of menu/board -> Extract OCR -> Generate phrase suggestions
  Future<void> _analyzePhotoForPhrases() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final file = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final ocrResults = await _ocrService.extractText(inputImage);

      final suggestions = <Map<String, String>>[];
      final fullText = ocrResults.map((e) => e.text.toLowerCase()).join(" ");

      if (fullText.contains("chai") || fullText.contains("tea") || fullText.contains("coffee") || fullText.contains("menu")) {
        suggestions.add({"label": "Order Hot Chai", "text": "I would like to order one hot chai, please."});
        suggestions.add({"label": "Ask Price", "text": "How much is this item?"});
      }
      if (fullText.contains("room") || fullText.contains("registration") || fullText.contains("entry") || fullText.contains("204")) {
        suggestions.add({"label": "Ask Registration", "text": "Excuse me, is this the registration counter?"});
        suggestions.add({"label": "Where is Room 204", "text": "Could you please guide me to Room 204?"});
      }

      if (suggestions.isEmpty) {
        suggestions.add({"label": "Read Board", "text": "Could you please explain what is written on this notice?"});
      }

      setState(() => _cameraSuggestedPhrases = suggestions);
    } catch (_) {}
  }

  // Code-Mixed Intent-to-Speech Transformer
  void _reformatIntentToSpeech() {
    final input = _intentInputController.text.trim();
    final lower = input.toLowerCase();
    if (input.isEmpty) return;

    String out;
    if (lower.contains('registration') || lower.contains('rega') || lower.contains('pativu') || lower.contains('enga irukku') || lower.contains('kekkanum')) {
      out = 'Excuse me, could you please tell me where the registration desk is?';
    } else if (lower.contains('toilet') || lower.contains('restroom') || lower.contains('washroom') || lower.contains('kuzhi') || lower.contains('kazi')) {
      out = 'Excuse me, could you please tell me where the restroom is?';
    } else if (lower.contains('water') || lower.contains('thanni') || lower.contains('tanni')) {
      out = 'Could I please get a bottle of water?';
    } else if (lower.contains('chai') || lower.contains('tea') || lower.contains('coffee') || lower.contains('kaapi')) {
      out = 'I would like a medium chai, please.';
    } else if (lower.contains('bill') || lower.contains('check') || lower.contains('hisab')) {
      out = 'Could you please bring the bill?';
    } else if (lower.contains('help') || lower.contains('udavi') || lower.contains('emergency')) {
      out = 'I need help, please. It is urgent.';
    } else if (lower.contains('name') || lower.contains('per')) {
      out = 'Hello, could you please tell me your name?';
    } else if (lower.contains('price') || lower.contains('cost') || lower.contains('evlo') || lower.contains('how much')) {
      out = 'Excuse me, how much does this cost?';
    } else if (lower.contains('room') && RegExp(r'\d{2,4}').hasMatch(lower)) {
      final n = RegExp(r'\d{2,4}').firstMatch(lower)!.group(0);
      out = 'Excuse me, could you please guide me to room $n?';
    } else if (lower.contains('exit') || lower.contains('veliyil') || lower.contains('way out')) {
      out = 'Excuse me, could you please show me the exit?';
    } else if (lower.contains('hello') || lower.contains('hi ') || lower == 'hi') {
      out = 'Hello, how are you?';
    } else if (lower.contains('thanks') || lower.contains('thank you') || lower.contains('nandri')) {
      out = 'Thank you so much for your help.';
    } else {
      // Clean generic fallback: polish fragment, don't dump raw only
      out = 'Excuse me, $input.';
      if (!out.trim().endsWith('.') && !out.trim().endsWith('?')) out = '$out.';
    }

    setState(() => _reformattedSentence = out);
  }

  // Capture other person's spoken response
  Future<void> _listenToReply() async {
    setState(() {
      _isListeningToReply = true;
      _lastOtherPersonReply = 'Listening... please ask them to speak clearly';
    });
    try {
      final result = await _speechService.listen();
      final text = result.text.trim();
      setState(() {
        _lastOtherPersonReply = text.isEmpty
            ? 'No speech detected. Tap again and ask them to speak louder.'
            : text;
        _isListeningToReply = false;
      });
      if (text.isNotEmpty) {
        await _ttsService.speak('They said: $text');
      }
    } catch (e) {
      setState(() {
        _lastOtherPersonReply = 'Mic error: $e';
        _isListeningToReply = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("COMMUNICATION ASSIST"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.forum), text: "Phrases"),
            Tab(icon: Icon(Icons.camera_alt), text: "Photo"),
            Tab(icon: Icon(Icons.auto_fix_high), text: "Intent"),
            Tab(icon: Icon(Icons.hearing), text: "Reply"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuickPhrasesTab(),
          _buildPhotoAssistTab(),
          _buildIntentTab(),
          _buildCaptureReplyTab(),
        ],
      ),
    );
  }

  Widget _buildQuickPhrasesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              const Text(
                "TAP TO SPEAK",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customPhraseController,
                      decoration: const InputDecoration(
                        hintText: "Add custom quick phrase...",
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_customPhraseController.text.trim().isNotEmpty) {
                        setState(() {
                          _customPhrases.add(_customPhraseController.text.trim());
                          _customPhraseController.clear();
                        });
                      }
                    },
                    child: const Text("Add"),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildCategorySection("Greetings", _greetingsPhrases),
              _buildCategorySection("Café & Food", _foodPhrases),
              _buildCategorySection("Emergency & Navigation", _emergencyPhrases),
              if (_customPhrases.isNotEmpty) ...[
                const Text("Custom Phrases", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _customPhrases
                      .map((p) => ActionChip(
                            avatar: const Icon(Icons.volume_up, size: 16),
                            label: Text(p),
                            backgroundColor: const Color(0xFFE8EEF7),
                            onPressed: () => _speakPhrase(p),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String title, List<Map<String, String>> phrases) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: phrases.map((p) {
            return ActionChip(
              avatar: const Icon(Icons.volume_up, size: 16, color: AppColors.primary),
              label: Text(p['label']!),
              backgroundColor: const Color(0xFFE8EEF7),
              onPressed: () => _speakPhrase(p['text']!),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPhotoAssistTab() {
    return Column(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryDark, width: 3),
          ),
          child: _isCameraInitialized && _cameraController != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CameraPreview(_cameraController!),
                )
              : const Center(child: Text("Camera Preview", style: TextStyle(color: Colors.white))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ElevatedButton.icon(
            onPressed: _analyzePhotoForPhrases,
            icon: const Icon(Icons.camera_enhance),
            label: const Text("SCAN MENU / SIGN"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _cameraSuggestedPhrases.isEmpty
              ? const Center(child: Text("Point camera at a menu or sign and tap analyze.", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _cameraSuggestedPhrases.length,
                  itemBuilder: (context, index) {
                    final p = _cameraSuggestedPhrases[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: AppColors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['label']!, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text(p['text']!, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: AppColors.primary),
                            onPressed: () => _speakPhrase(p['text']!),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIntentTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "INTENT → SPEECH",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            "Type rough Tamil/English. App makes a clear sentence.",
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _intentInputController,
            decoration: const InputDecoration(
              hintText: "Type rough text here...",
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _reformatIntentToSpeech,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text("TRANSFORM"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 20),
          if (_reformattedSentence.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Result:", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(_reformattedSentence, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _speakPhrase(_reformattedSentence),
                    icon: const Icon(Icons.volume_up),
                    label: const Text("SPEAK"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCaptureReplyTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hearing, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            "LISTEN TO THEIR REPLY",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            "Hold phone towards person speaking to transcribe their reply.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListeningToReply ? AppColors.danger : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: _isListeningToReply ? null : _listenToReply,
            icon: Icon(_isListeningToReply ? Icons.mic : Icons.mic_none, color: Colors.white),
            label: Text(
              _isListeningToReply ? "LISTENING..." : "LISTEN",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 24),
          if (_lastOtherPersonReply.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Column(
                children: [
                  const Text("Reply:", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Text(
                    '"$_lastOtherPersonReply"',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

}
