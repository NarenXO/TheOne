import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/impl/ocr_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';
import '../../core/utils/app_logger.dart';
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
  final OcrServiceImpl _ocrService = OcrServiceImpl();

  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  final TextEditingController _customPhraseController = TextEditingController();
  final TextEditingController _intentInputController = TextEditingController();

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
    _tabController = TabController(length: 3, vsync: this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!mounted) return;

    final camStatus = await Permission.camera.request();

    if (!camStatus.isGranted) {
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
      return;
    }

    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _isCameraInitialized = false);
        }
        return;
      }

      final firstCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        firstCam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await _cameraController!.initialize();
      } catch (_) {
        // Fallback to low resolution if medium fails
        _cameraController = CameraController(
          firstCam,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _cameraController!.initialize();
      }

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        AppLogger.i('COMMUNICATION', 'Camera successfully initialized (${firstCam.name})');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCameraInitialized = false);
        AppLogger.e('COMMUNICATION', 'Camera init error: $e');
      }
    }
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
    AppLogger.i('COMMUNICATION', 'Speaking quick phrase: "$text"');
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
    if (input.isEmpty) return;

    final lower = input.toLowerCase();
    String out = "";

    if (lower.contains("registration") || lower.contains("rega") || lower.contains("pativu") || lower.contains("counter")) {
      out = "Excuse me, could you please tell me where the registration desk is located?";
    } else if (lower.contains("toilet") || lower.contains("restroom") || lower.contains("washroom") || lower.contains("kazi") || lower.contains("kuzhi") || lower.contains("bathroom")) {
      out = "Excuse me, could you please guide me to the nearest restroom?";
    } else if (lower.contains("chai") || lower.contains("tea") || lower.contains("coffee") || lower.contains("kaapi") || lower.contains("drink")) {
      out = "I would like to order a warm beverage, please.";
    } else if (lower.contains("water") || lower.contains("thanni") || lower.contains("tanni")) {
      out = "Could I please get a bottle of drinking water?";
    } else if (lower.contains("food") || lower.contains("sapadu") || lower.contains("saapadu") || lower.contains("menu") || lower.contains("hungry")) {
      out = "Excuse me, could you please show me the food menu?";
    } else if (lower.contains("bill") || lower.contains("check") || lower.contains("evlo") || lower.contains("price") || lower.contains("cost")) {
      out = "Could you please bring me the total bill for this?";
    } else if (lower.contains("help") || lower.contains("udavi") || lower.contains("emergency")) {
      out = "I need immediate assistance, please help me.";
    } else if (lower.contains("room") || RegExp(r'\d{2,4}').hasMatch(lower)) {
      final match = RegExp(r'\d{2,4}').firstMatch(lower);
      final roomNum = match != null ? "Room ${match.group(0)}" : "the room";
      out = "Excuse me, could you please guide me to $roomNum?";
    } else if (lower.contains("exit") || lower.contains("veliya") || lower.contains("way out")) {
      out = "Excuse me, could you please show me where the exit is?";
    } else if (lower.contains("name") || lower.contains("peru") || lower.contains("yaaru")) {
      out = "Hello! May I please ask what your name is?";
    } else if (lower.contains("time") || lower.contains("mani")) {
      out = "Excuse me, could you please tell me what time it is?";
    } else if (lower.contains("bus") || lower.contains("train") || lower.contains("auto") || lower.contains("cab") || lower.contains("taxi")) {
      out = "Excuse me, where can I find transportation from here?";
    } else if (lower.contains("thanks") || lower.contains("thank you") || lower.contains("nandri")) {
      out = "Thank you so much for your kind help!";
    } else if (lower.contains("hello") || lower.contains("hi ") || lower == "hi" || lower.contains("vanakkam")) {
      out = "Hello! I hope you are having a good day.";
    } else {
      // Natural transformer fallback (capitalizes first letter, adds polite request prefix)
      final capitalized = input[0].toUpperCase() + input.substring(1);
      out = "Could you please help me with this: $capitalized?";
    }

    setState(() => _reformattedSentence = out);
    AppLogger.i('COMMUNICATION', 'Intent transformed: "$input" -> "$out"');
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuickPhrasesTab(),
          _buildPhotoAssistTab(),
          _buildIntentTab(),
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

}
