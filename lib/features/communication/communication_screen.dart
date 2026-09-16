import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/impl/ocr_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_settings_drawer.dart';

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
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _initCamera();
      } else {
        _disposeCamera();
      }
    });
  }

  void _disposeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    }
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

  // Photo Assist: OCR -> Item-by-item actionable sentence cards
  Future<void> _analyzePhotoForPhrases() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      await _cameraController!.pausePreview();
      final file = await _cameraController!.takePicture();
      await _cameraController!.resumePreview();

      final inputImage = InputImage.fromFilePath(file.path);
      final ocrResults = await _ocrService.extractText(inputImage);

      final fullText = ocrResults.map((e) => e.text).join(" ").toLowerCase();
      final suggestions = <Map<String, String>>[];

      if (fullText.isEmpty) {
        suggestions.add({"label": "No Text", "text": "I couldn't read any text clearly."});
        await _ttsService.speak("No text detected. Please retake the photo.");
      } else {
        if (fullText.contains("menu") || fullText.contains("rs") || fullText.contains("₹") || fullText.contains("coffee") || fullText.contains("hotel")) {
          suggestions.add({"label": "Order Item", "text": "Hello, I would like to place an order from this menu."});
          suggestions.add({"label": "Ask Price", "text": "Excuse me, how much does this item cost?"});
        } else if (fullText.contains("hospital") || fullText.contains("dr.") || fullText.contains("clinic")) {
          suggestions.add({"label": "Doctor Appointment", "text": "Hello, I am here to see the doctor."});
        } else {
          suggestions.add({"label": "Read Sign", "text": "Excuse me, could you please tell me what this sign board means?"});
        }

        final seenLines = <String>{};
        for (final result in ocrResults) {
          final line = result.text.trim();
          if (line.isEmpty || seenLines.contains(line.toLowerCase())) continue;
          seenLines.add(line.toLowerCase());
          final lowerLine = line.toLowerCase();
          if (RegExp(r'chai|tea|coffee|sandwich|water|food|drink|burger|pizza|dosa|idli|juice', caseSensitive: false).hasMatch(lowerLine)) {
            suggestions.add({
              "label": "Order $line",
              "text": "I would like to order $line, please.",
            });
          }
        }

        suggestions.add({"label": "Read Raw Text", "text": "The text reads: ${fullText.substring(0, fullText.length > 50 ? 50 : fullText.length)}"});
      }

      setState(() => _cameraSuggestedPhrases = suggestions);
      AppLogger.i('COMMUNICATION', 'Photo analyzed, generated ${suggestions.length} phrase choices');
    } catch (e) {
      AppLogger.e('COMMUNICATION', 'Photo analysis error: $e');
      try { await _cameraController?.resumePreview(); } catch (_) {}
    }
  }

  // Rich NLU Intent Transformer Overhaul
  void _reformatIntentToSpeech() {
    final input = _intentInputController.text.trim();
    if (input.isEmpty) return;
    final lower = input.toLowerCase();

    // Clean out stop words
    String topic = input
        .replaceAll(RegExp(r'\b(enga|irukku|nu|kekkanum|venum|pativu|sollu|solunga|pessunga)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (topic.isEmpty) topic = input;

    String out;

    if (RegExp(r"don't be sad|feel.*sad|kavalai|crying|upset").hasMatch(lower)) {
      out = "Please don't be sad, everything will be alright.";
    } else if (RegExp(r"happy|greetings|good night|good morning|vanakkam|hi\b|hello").hasMatch(lower)) {
      if (lower.contains("night")) {
        out = "Good night! Have a peaceful rest.";
      } else if (lower.contains("morning")) {
        out = "Good morning! Wishing you a pleasant day.";
      } else {
        out = "Hello! I am happy to connect with you.";
      }
    } else if (RegExp(r'registration|pativu|rega|room|toilet|restroom|washroom|kazi|exit|veliya|counter|desk|where|enga').hasMatch(lower)) {
      out = topic.isEmpty
          ? 'Excuse me, could you please tell me where to go?'
          : 'Excuse me, could you please tell me where $topic is?';
    } else if (RegExp(r'chai|tea|coffee|kaapi|water|thanni|tanni|food|sapadu|drink|venum').hasMatch(lower)) {
      out = topic.isEmpty
          ? 'I would like to request assistance, please.'
          : 'I would like to request $topic, please.';
    } else if (RegExp(r'how|why|what|when|who|epdi|evlo|price|cost|bill|\?').hasMatch(lower)) {
      out = topic.isEmpty
          ? 'Excuse me, may I ask a question?'
          : 'Excuse me, may I ask about $topic?';
    } else {
      out = 'Excuse me, could you please help me with this: $topic?';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => AppSettingsDrawer.show(context),
            tooltip: "Settings",
          ),
        ],
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
    return SingleChildScrollView(
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
