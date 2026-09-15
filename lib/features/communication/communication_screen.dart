import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../../core/services/impl/ocr_service_impl.dart';
import '../../core/services/impl/speech_input_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';

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
  final TextEditingController _signSearchController = TextEditingController();

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

  // Sign Language Dictionary Items
  final List<Map<String, String>> _signDictionary = [
    {"sign": "Thank You", "category": "Basic", "description": "Flat hand touches chin, then moves forward towards person."},
    {"sign": "Hello / Wave", "category": "Basic", "description": "Open hand raised near temple, wave outwards gently."},
    {"sign": "Help", "category": "Emergency", "description": "Closed fist with thumb up placed on flat palm of other hand."},
    {"sign": "Please", "category": "Basic", "description": "Flat hand rubbed in circular motion over chest."},
    {"sign": "Water", "category": "Food", "description": "'W' hand shape tapped against chin twice."},
    {"sign": "Emergency", "category": "Emergency", "description": "Hand shaped as 'E' shaken gently side to side."},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initCamera();
  }

  Future<void> _initCamera() async {
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
    _signSearchController.dispose();
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
    final input = _intentInputController.text.trim().toLowerCase();
    if (input.isEmpty) return;

    String cleanSentence = "";
    if (input.contains("registration") || input.contains("enga") || input.contains("kekkanum")) {
      cleanSentence = "Excuse me, could you please tell me where the registration desk is located?";
    } else if (input.contains("chai") || input.contains("venum") || input.contains("tea")) {
      cleanSentence = "Excuse me, I would like to order a tea, please.";
    } else if (input.contains("toilet") || input.contains("restroom")) {
      cleanSentence = "Could you please show me where the nearest restroom is?";
    } else {
      cleanSentence = "Excuse me, $input";
    }

    setState(() => _reformattedSentence = cleanSentence);
  }

  // Capture other person's spoken response
  Future<void> _listenToReply() async {
    setState(() => _isListeningToReply = true);
    final result = await _speechService.listen();
    setState(() {
      _lastOtherPersonReply = result.text.isNotEmpty ? result.text : "No speech detected.";
      _isListeningToReply = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TheOne — Communication Assist"),
        backgroundColor: Colors.teal[900],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.tealAccent,
          tabs: const [
            Tab(icon: Icon(Icons.forum), text: "Quick Phrases"),
            Tab(icon: Icon(Icons.camera_alt), text: "Photo Assist"),
            Tab(icon: Icon(Icons.auto_fix_high), text: "Intent Engine"),
            Tab(icon: Icon(Icons.hearing), text: "Capture Reply"),
            Tab(icon: Icon(Icons.sign_language), text: "Sign Dictionary"),
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
          _buildSignDictionaryTab(),
        ],
      ),
    );
  }

  Widget _buildQuickPhrasesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customPhraseController,
                  decoration: const InputDecoration(
                    hintText: "Add custom quick phrase...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
                onPressed: () {
                  if (_customPhraseController.text.trim().isNotEmpty) {
                    setState(() {
                      _customPhrases.add(_customPhraseController.text.trim());
                      _customPhraseController.clear();
                    });
                  }
                },
                child: const Text("Add", style: TextStyle(color: Colors.white)),
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
                const Text("Custom Phrases", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _customPhrases
                      .map((p) => ActionChip(
                            avatar: const Icon(Icons.volume_up, size: 16),
                            label: Text(p),
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: phrases.map((p) {
            return ActionChip(
              avatar: const Icon(Icons.volume_up, size: 16, color: Colors.teal),
              label: Text(p['label']!),
              backgroundColor: Colors.teal[50],
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
          height: 200,
          width: double.infinity,
          color: Colors.black,
          child: _isCameraInitialized && _cameraController != null
              ? CameraPreview(_cameraController!)
              : const Center(child: Text("Camera Preview", style: TextStyle(color: Colors.white))),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
            onPressed: _analyzePhotoForPhrases,
            icon: const Icon(Icons.camera_enhance, color: Colors.white),
            label: const Text("Photograph Menu / Sign for Suggestions", style: TextStyle(color: Colors.white)),
          ),
        ),
        Expanded(
          child: _cameraSuggestedPhrases.isEmpty
              ? const Center(child: Text("Point camera at a menu or sign and tap analyze."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _cameraSuggestedPhrases.length,
                  itemBuilder: (context, index) {
                    final p = _cameraSuggestedPhrases[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.lightbulb, color: Colors.amber),
                        title: Text(p['label']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(p['text']!),
                        trailing: IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.teal),
                          onPressed: () => _speakPhrase(p['text']!),
                        ),
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
            "Code-Mixed Intent Converter",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Type rough Tamil/English input (e.g., 'registration enga irukku nu kekkanum') and transform it into a polite, full spoken sentence.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _intentInputController,
            decoration: const InputDecoration(
              hintText: "Type rough text here...",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
            onPressed: _reformatIntentToSpeech,
            icon: const Icon(Icons.auto_fix_high, color: Colors.white),
            label: const Text("Transform to Polite Sentence", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          if (_reformattedSentence.isNotEmpty)
            Card(
              color: Colors.teal[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.teal),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Clean Natural Spoken Sentence:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 8),
                    Text(_reformattedSentence, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[900]),
                      onPressed: () => _speakPhrase(_reformattedSentence),
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      label: const Text("Speak Sentence Aloud", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
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
          const Icon(Icons.hearing, size: 64, color: Colors.teal),
          const SizedBox(height: 16),
          const Text(
            "Capture Other Person's Reply",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Press the button below and hold your phone towards the vendor or person speaking to transcribe their reply on screen.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListeningToReply ? Colors.red[700] : Colors.teal[800],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: _isListeningToReply ? null : _listenToReply,
            icon: Icon(_isListeningToReply ? Icons.mic : Icons.mic_none, color: Colors.white),
            label: Text(
              _isListeningToReply ? "Listening..." : "Listen for Response",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          if (_lastOtherPersonReply.isNotEmpty)
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("Spoken Reply Transcribed:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 8),
                    Text(
                      '"$_lastOtherPersonReply"',
                      style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSignDictionaryTab() {
    final query = _signSearchController.text.toLowerCase();
    final filtered = _signDictionary.where((s) {
      return s['sign']!.toLowerCase().contains(query) || s['category']!.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _signSearchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: "Search Sign Language Dictionary...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[100],
                    child: const Icon(Icons.sign_language, color: Colors.teal),
                  ),
                  title: Text(item['sign']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${item['category']} — ${item['description']}"),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
