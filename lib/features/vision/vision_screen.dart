import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/evidence/evidence.dart';
import '../../core/evidence/evidence_bundle.dart';
import '../../core/evidence/relevance_engine.dart';
import '../../core/evidence/zero_assumption_engine.dart';
import '../../core/evidence/verification_result.dart';
import '../../core/models/confidence_state.dart';
import '../../core/models/evidence_source.dart';
import '../../core/models/evidence_type.dart';
import '../../core/services/impl/haptic_service_impl.dart';
import '../../core/services/impl/ocr_service_impl.dart';
import '../../core/services/impl/torch_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';
import '../../core/storage/session_storage.dart';
import '../../shared/widgets/evidence_card.dart';

class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isTorchOn = false;

  final _ocrService = OcrServiceImpl();
  final _ttsService = TtsServiceImpl();
  final _hapticService = HapticServiceImpl();
  final _torchService = TorchServiceImpl();
  final _zeroAssumptionEngine = ZeroAssumptionEngine();
  final _relevanceEngine = RelevanceEngine();
  final _sessionStorage = SessionStorage();

  VerificationResult? _lastResult;
  List<Evidence> _activeEvidence = [];
  final TextEditingController _queryController = TextEditingController(text: "Room 204 enga irukku?");

  @override
  void initState() {
    super.initState();
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
    } catch (_) {
      // Graceful fallback for emulator or systems without camera hardware
    }
  }

  Future<void> _toggleTorch() async {
    if (_isTorchOn) {
      await _torchService.turnOff();
    } else {
      await _torchService.turnOn();
    }
    setState(() => _isTorchOn = !_isTorchOn);
  }

  Future<void> _processVerification(EvidenceBundle bundle, String query) async {
    final rankedItems = _relevanceEngine.rank(query: query, evidence: bundle.items);
    final rankedBundle = EvidenceBundle(rankedItems);
    final result = _zeroAssumptionEngine.verify(query: query, bundle: rankedBundle);

    setState(() {
      _lastResult = result;
      _activeEvidence = rankedItems;
    });

    for (final e in rankedItems) {
      await _sessionStorage.saveEvidence(e);
    }

    await _ttsService.speak(result.message);

    switch (result.state) {
      case ConfidenceState.verified:
        await _hapticService.verified();
        break;
      case ConfidenceState.uncertain:
      case ConfidenceState.insufficient:
        await _hapticService.uncertain();
        break;
      case ConfidenceState.conflict:
        await _hapticService.conflict();
        break;
    }
  }

  // --- FLAGSHIP DEMO SCENARIOS ---
  void _runVerifiedDemo() {
    final bundle = EvidenceBundle([
      Evidence(
        source: EvidenceSource.camera,
        type: EvidenceType.ocr,
        value: "ROOM 204",
        confidence: 0.98,
      ),
    ]);
    _processVerification(bundle, _queryController.text);
  }

  void _runConflictDemo() {
    final bundle = EvidenceBundle([
      Evidence(
        source: EvidenceSource.camera,
        type: EvidenceType.ocr,
        value: "ROOM 204",
        confidence: 0.98,
      ),
      Evidence(
        source: EvidenceSource.microphone,
        type: EvidenceType.speech,
        value: "ROOM 302",
        confidence: 0.92,
      ),
    ]);
    _processVerification(bundle, _queryController.text);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TheOne — Vision Assist"),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
            tooltip: "Toggle Flashlight",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _sessionStorage.clearSession();
              if (!mounted) return;
              setState(() {
                _lastResult = null;
                _activeEvidence = [];
              });
              messenger.showSnackBar(
                const SnackBar(content: Text("Session context cleared")),
              );
            },
            tooltip: "Clear Session",
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview Box
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.grey, size: 48),
                        SizedBox(height: 8),
                        Text(
                          "Camera Active / Standby Mode",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
          ),

          // Query & Demo Controls
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: "Voice Query (Tamil / English)",
                    prefixIcon: Icon(Icons.mic),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                        onPressed: _runVerifiedDemo,
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text("Demo: Verify 204", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                        onPressed: _runConflictDemo,
                        icon: const Icon(Icons.warning_amber_outlined, color: Colors.white),
                        label: const Text("Demo: Conflict 204/302", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Verification Status Banner
          if (_lastResult != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: _lastResult!.state == ConfidenceState.verified
                  ? Colors.green[100]
                  : _lastResult!.state == ConfidenceState.conflict
                      ? Colors.red[100]
                      : Colors.amber[100],
              child: Text(
                _lastResult!.message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          // Evidence Cards Feed
          Expanded(
            child: _activeEvidence.isEmpty
                ? const Center(
                    child: Text("No evidence scanned yet. Run a query or demo."),
                  )
                : ListView.builder(
                    itemCount: _activeEvidence.length,
                    itemBuilder: (context, index) {
                      final item = _activeEvidence[index];
                      return EvidenceCard(
                        evidence: item,
                        state: _lastResult?.state ?? ConfidenceState.verified,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
