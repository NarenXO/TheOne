import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/evidence/evidence.dart';
import '../../core/evidence/evidence_bundle.dart';
import '../../core/evidence/relevance_engine.dart';
import '../../core/evidence/zero_assumption_engine.dart';
import '../../core/evidence/verification_result.dart';
import '../../core/models/confidence_state.dart';
import '../../core/models/evidence_source.dart';
import '../../core/models/evidence_type.dart';
import '../../core/services/impl/haptic_service_impl.dart';
import '../../core/services/impl/object_detection_service_impl.dart';
import '../../core/services/impl/ocr_service_impl.dart';
import '../../core/services/impl/speech_input_service_impl.dart';
import '../../core/services/impl/torch_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';
import '../../core/storage/session_storage.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/evidence_card.dart';
import 'vision_pipeline.dart';

class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isTorchOn = false;
  String _cameraErrorMsg = "";

  final _ocrService = OcrServiceImpl();
  final _ttsService = TtsServiceImpl();
  final _hapticService = HapticServiceImpl();
  final _torchService = TorchServiceImpl();
  final _speechService = SpeechInputServiceImpl();
  final _zeroAssumptionEngine = ZeroAssumptionEngine();
  final _relevanceEngine = RelevanceEngine();
  final _sessionStorage = SessionStorage();
  final _objectService = ObjectDetectionServiceImpl();
  late final VisionPipeline _visionPipeline;

  VerificationResult? _lastResult;
  List<Evidence> _activeEvidence = [];
  final TextEditingController _queryController = TextEditingController(text: "Room 204 enga irukku?");
  bool _isListening = false;
  String _statusLine = 'Ready';

  @override
  void initState() {
    super.initState();
    _visionPipeline = VisionPipeline(
      ocrService: _ocrService,
      objectService: _objectService,
      torchService: _torchService,
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _cameraErrorMsg = "Requesting permissions...";
    });

    final camStatus = await Permission.camera.request();
    await Permission.microphone.request();

    if (!camStatus.isGranted) {
      setState(() {
        _isCameraInitialized = false;
        _cameraErrorMsg = "Camera permission denied. Please grant in phone settings.";
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _cameraErrorMsg = "";
          });
        }
      } else {
        setState(() {
          _isCameraInitialized = false;
          _cameraErrorMsg = "No camera hardware detected on device.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraErrorMsg = "Camera init error: $e";
        });
      }
    }
  }

  Future<void> _toggleTorch() async {
    final nextState = !_isTorchOn;
    try {
      if (_isCameraInitialized && _cameraController != null) {
        await _cameraController!.setFlashMode(
          nextState ? FlashMode.torch : FlashMode.off,
        );
      } else {
        if (nextState) {
          await _torchService.turnOn();
        } else {
          await _torchService.turnOff();
        }
      }
      setState(() => _isTorchOn = nextState);
    } catch (e) {
      // Fallback handling if flash unavailable
    }
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

  Future<void> _startVoiceInput() async {
    setState(() => _isListening = true);
    final result = await _speechService.listen();
    setState(() => _isListening = false);

    if (result.text.isNotEmpty) {
      _queryController.text = result.text;
    }
  }

  Future<void> _scanLiveCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() => _statusLine = 'Camera not ready');
      return;
    }
    try {
      setState(() => _statusLine = 'Scanning...');
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      final brightness = _visionPipeline.estimateBrightnessFromBytes(bytes);

      await _visionPipeline.applyAutoTorch(
        brightness: brightness,
        cameraController: _cameraController,
      );

      final inputImage = InputImage.fromFilePath(file.path);
      final bundle = await _visionPipeline.processInputImage(
        inputImage,
        estimatedBrightness: brightness,
        cameraController: _cameraController,
      );

      // Obstacle haptic for closest obstacle
      for (final e in bundle.items) {
        if (e.type == EvidenceType.obstacle) {
          final p = (e.metadata['proximity01'] as num?)?.toDouble() ?? 0;
          if (p >= 0.4) await _hapticService.obstacleProximity(p);
        }
      }

      final query = _queryController.text.trim().isEmpty
          ? 'What is in front of me?'
          : _queryController.text.trim();

      await _processVerification(bundle, query);

      setState(() {
        _statusLine = _visionPipeline.isTorchAutoOn
            ? 'Low light detected — torch ON automatically'
            : 'Scan complete (brightness ${(brightness * 100).toStringAsFixed(0)}%)';
      });
    } catch (e) {
      setState(() => _statusLine = 'Scan failed: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    _objectService.dispose();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VISION ASSIST"),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
          // Feature Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.primary,
            child: const Text(
              "Camera • OCR • Objects • Evidence Engine",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Camera Preview Box
          Container(
            height: 210,
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
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt, color: AppColors.textSecondary, size: 40),
                          const SizedBox(height: 8),
                          const Text(
                            "CAMERA NOT READY",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _cameraErrorMsg.isEmpty ? "Camera initializing..." : _cameraErrorMsg,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_cameraErrorMsg.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _initCamera,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                              ),
                              child: const Text("RETRY CAMERA"),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
          // Status Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLine,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          // Query Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                labelText: "Ask a question (Tamil / English)",
                prefixIcon: Icon(Icons.question_answer),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Button Row 1
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanLiveCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("SCAN LIVE"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isListening ? null : _startVoiceInput,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    label: Text(_isListening ? "LISTENING..." : "VOICE"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Button Row 2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runVerifiedDemo,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("DEMO VERIFY 204"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runConflictDemo,
                    icon: const Icon(Icons.warning_amber_outlined),
                    label: const Text("DEMO CONFLICT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Helper Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Text(
              "Live scan uses real camera. Demo buttons show engine states for judges.",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          // Result Banner
          if (_lastResult != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _lastResult!.state == ConfidenceState.verified
                    ? AppColors.success
                    : _lastResult!.state == ConfidenceState.conflict
                        ? AppColors.danger
                        : AppColors.warning,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _lastResult!.message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          // Evidence Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "EVIDENCE",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Evidence Cards Feed
          SizedBox(
            height: 300,
            child: _activeEvidence.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "No evidence scanned yet. Run a query or demo.",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
          const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }
}
