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
  List<Map<String, String>> _cameraSuggestedPhrases = [];

  // Rich phrases with Material 2D icons
  final List<Map<String, dynamic>> _quickPhrases = [
    {"label": "Hello", "text": "Hello, how are you today?", "icon": Icons.waving_hand, "category": "Greetings"},
    {"label": "Thank You", "text": "Thank you very much for your help.", "icon": Icons.thumb_up, "category": "Greetings"},
    {"label": "Excuse Me", "text": "Excuse me, I need a moment please.", "icon": Icons.priority_high, "category": "Greetings"},
    {"label": "Good Morning", "text": "Good morning! Hope you have a great day.", "icon": Icons.wb_sunny, "category": "Greetings"},

    {"label": "Order Chai", "text": "I would like a medium chai, please.", "icon": Icons.emoji_food_beverage, "category": "Food"},
    {"label": "Order Water", "text": "Could I please get a bottle of drinking water?", "icon": Icons.local_drink, "category": "Food"},
    {"label": "Bill Please", "text": "Could you please bring me the bill?", "icon": Icons.payments, "category": "Food"},
    {"label": "Vegetarian?", "text": "Is this food item vegetarian?", "icon": Icons.restaurant, "category": "Food"},

    {"label": "Need Help", "text": "I need assistance immediately.", "icon": Icons.medical_services, "category": "Emergency"},
    {"label": "Where is Room 204", "text": "Could you please guide me to Room 204?", "icon": Icons.meeting_room, "category": "Emergency"},
    {"label": "Where is Exit", "text": "Excuse me, where is the exit?", "icon": Icons.door_sliding, "category": "Emergency"},
    {"label": "Bus / Transport", "text": "Where can I find bus or auto transportation?", "icon": Icons.directions_bus, "category": "Emergency"},
  ];

  final List<String> _customPhrases = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!mounted) return;
    await Permission.camera.request();

    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Try medium resolution first to avoid surface combination limit on Android
      _cameraController = CameraController(
        backCam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await _cameraController!.initialize();
      } catch (_) {
        // Fallback to low resolution
        _cameraController = CameraController(
          backCam,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _cameraController!.initialize();
      }

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        AppLogger.i('COMMUNICATION', 'Camera initialized successfully (ResolutionPreset.medium)');
      }
    } catch (e) {
      AppLogger.e('COMMUNICATION', 'Camera init error: $e');
      if (mounted) setState(() => _isCameraInitialized = false);
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
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Photo Assist: OCR -> 3 to 4 polite spoken sentence choices
  Future<void> _analyzePhotoForPhrases() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      // 1. Stop active image stream if running to free Camera2 HAL surface
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      // 2. Pause preview briefly before taking picture to prevent surface conflict
      await _cameraController!.pausePreview();
      final file = await _cameraController!.takePicture();
      await _cameraController!.resumePreview();

      final inputImage = InputImage.fromFilePath(file.path);
      final ocrResults = await _ocrService.extractText(inputImage);

      final suggestions = <Map<String, String>>[];
      final fullText = ocrResults.map((e) => e.text.toLowerCase()).join(" ");

      if (fullText.contains("chai") || fullText.contains("tea") || fullText.contains("coffee") || fullText.contains("menu") || fullText.contains("cafe")) {
        suggestions.add({"label": "Order Beverage", "text": "I would like to order one hot chai, please."});
        suggestions.add({"label": "Ask Item Price", "text": "Excuse me, how much does this cost?"});
        suggestions.add({"label": "Ask Specialties", "text": "What do you recommend from this menu?"});
      }
      if (fullText.contains("room") || fullText.contains("registration") || fullText.contains("204") || fullText.contains("counter") || fullText.contains("entry")) {
        suggestions.add({"label": "Ask Registration", "text": "Excuse me, is this the registration desk?"});
        suggestions.add({"label": "Guide to Room 204", "text": "Could you please show me the way to Room 204?"});
        suggestions.add({"label": "Check Notice", "text": "Could you please explain what is written on this notice?"});
      }

      if (suggestions.isEmpty) {
        suggestions.add({"label": "Inquire About Notice", "text": "Excuse me, could you please tell me what this sign says?"});
        suggestions.add({"label": "Ask for Direction", "text": "Excuse me, I am looking for assistance regarding this board."});
        suggestions.add({"label": "General Request", "text": "Hello! Could you please help me with this?"});
      }

      setState(() => _cameraSuggestedPhrases = suggestions);
      AppLogger.i('COMMUNICATION', 'Photo analyzed, generated ${suggestions.length} phrase choices');
    } catch (e) {
      AppLogger.e('COMMUNICATION', 'Photo analysis error: $e');
      // Resume preview if paused
      try { await _cameraController?.resumePreview(); } catch (_) {}
    }
  }

  // Rich NLU Intent Transformer
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
      final capitalized = input[0].toUpperCase() + input.substring(1);
      out = "Could you please help me with this: $capitalized?";
    }

    setState(() => _reformattedSentence = out);
    AppLogger.i('COMMUNICATION', 'Intent transformed: "$input" -> "$out"');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5E3F8), // light blue
      appBar: AppBar(
        title: const Text("COMMUNICATION ASSIST"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.forum), text: "Quick Phrases"),
            Tab(icon: Icon(Icons.camera_alt), text: "Photo Assist"),
            Tab(icon: Icon(Icons.auto_fix_high), text: "Intent Engine"),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Custom Phrase Builder Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customPhraseController,
                    decoration: const InputDecoration(
                      hintText: "Type custom quick phrase...",
                      border: OutlineInputBorder(),
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
                  child: const Text("ADD"),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text("Quick Phrase Cards (Tap to Speak)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 12),

        // Grid of 2D Icon Quick Phrases
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _quickPhrases.length,
          itemBuilder: (context, index) {
            final item = _quickPhrases[index];
            return Card(
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _speakPhrase(item['text']),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(item['icon'] as IconData, color: AppColors.primary, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['label'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        if (_customPhrases.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text("My Custom Phrases", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _customPhrases
                .map((p) => ActionChip(
                      avatar: const Icon(Icons.volume_up, size: 16, color: AppColors.primary),
                      label: Text(p, style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _speakPhrase(p),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoAssistTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 3:4 Aspect Ratio Camera Box
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: _isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized
                    ? CameraPreview(_cameraController!)
                    : Container(
                        color: AppColors.primaryDark,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.white, size: 48),
                              SizedBox(height: 8),
                              Text("Camera Preview", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            onPressed: _analyzePhotoForPhrases,
            icon: const Icon(Icons.camera_enhance),
            label: const Text("PHOTOGRAPH MENU / NOTICE FOR SUGGESTIONS"),
          ),
          const SizedBox(height: 16),
          if (_cameraSuggestedPhrases.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Suggested Spoken Sentences (Tap to Speak):", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cameraSuggestedPhrases.length,
              itemBuilder: (context, index) {
                final item = _cameraSuggestedPhrases[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb, color: Colors.amber),
                    title: Text(item['label']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['text']!),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () => _speakPhrase(item['text']!),
                      icon: const Icon(Icons.volume_up, size: 16),
                      label: const Text("SPEAK"),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntentTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Code-Mixed Intent Transformer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 6),
          const Text(
            "Type rough Tamil or English fragments (e.g., 'registration enga irukku nu kekkanum') to transform into a clean, polite spoken sentence.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _intentInputController,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: "Type rough fragment here...",
              prefixIcon: Icon(Icons.edit_note, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            onPressed: _reformatIntentToSpeech,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text("TRANSFORM TO POLITE SENTENCE"),
          ),
          const SizedBox(height: 20),
          if (_reformattedSentence.isNotEmpty)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.primary, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Generated Spoken Sentence:", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text(_reformattedSentence, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, minimumSize: const Size(double.infinity, 48)),
                      onPressed: () => _speakPhrase(_reformattedSentence),
                      icon: const Icon(Icons.volume_up),
                      label: const Text("SPEAK SENTENCE ALOUD"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
