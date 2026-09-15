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
import '../../core/models/evidence_type.dart';
import '../../core/services/impl/haptic_service_impl.dart';
import '../../core/services/impl/object_detection_service_impl.dart';
import '../../core/services/impl/ocr_service_impl.dart';
import '../../core/services/impl/speech_input_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';
import '../../core/safety/sos_service.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/app_logger.dart';
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

  final _ocrService = OcrServiceImpl();
  final _ttsService = TtsServiceImpl();
  final _hapticService = HapticServiceImpl();
  final _zeroAssumptionEngine = ZeroAssumptionEngine();
  final _relevanceEngine = RelevanceEngine();
  final _sessionStorage = SessionStorage();
  final _objectService = ObjectDetectionServiceImpl();
  late final VisionPipeline _visionPipeline;

  VerificationResult? _lastResult;
  List<Evidence> _activeEvidence = [];
  bool _isListening = false;
  String _statusLine = 'Tap mic and say "Hey Rook" to activate';

  @override
  void initState() {
    super.initState();
    _visionPipeline = VisionPipeline(
      ocrService: _ocrService,
      objectService: _objectService,
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!mounted) return;
    await Permission.camera.request();
    await Permission.microphone.request();

    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _isCameraInitialized = false);
        return;
      }

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
        AppLogger.i('CAMERA', 'Camera initialized successfully (ResolutionPreset.medium)');
      }
    } catch (e) {
      AppLogger.e('CAMERA', 'Camera init exception: $e');
      if (mounted) setState(() => _isCameraInitialized = false);
    }
  }

  Future<void> _processVerification(EvidenceBundle bundle, String query) async {
    final rankedItems = _relevanceEngine.rank(query: query, evidence: bundle.items);
    final rankedBundle = EvidenceBundle(rankedItems);
    final result = _zeroAssumptionEngine.verify(query: query, bundle: rankedBundle);

    setState(() {
      _lastResult = result;
      _activeEvidence = bundle.items;
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

  Future<void> _voiceAsk() async {
    if (!(await Permission.microphone.request()).isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission required for voice query.")),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    setState(() => _statusLine = "Listening... Say 'Hey Rook' or your question");

    final speech = SpeechInputServiceImpl();
    final result = await speech.listen();

    if (!mounted) return;

    setState(() => _isListening = false);

    if (result.text.trim().isEmpty) {
      setState(() => _statusLine = "No speech heard. Please try tapping again.");
      await _ttsService.speak("I did not catch that. Please speak again.");
      return;
    }

    final text = result.text.trim().toLowerCase();
    AppLogger.i('VISION', 'Voice query captured: "${result.text.trim()}"');

    // Wake word detection
    if (text.contains("hello rook") || text.contains("hey rook")) {
      setState(() => _statusLine = "Wake word detected. Processing request...");

      // Check for SOS keywords
      if (text.contains("help") || text.contains("sos") || text.contains("emergency")) {
        setState(() => _statusLine = "Sending SOS alert...");
        await SosService().sendSosSms();
        await _ttsService.speak("SOS alert sent to emergency contact.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🚨 SOS Alert Sent"),
              backgroundColor: AppColors.danger,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _statusLine = "SOS alert sent");
        return;
      }

      // Otherwise, capture picture and analyze
      await _scanLiveCamera();
    } else {
      // Not a wake word, treat as regular query
      await _scanLiveCamera();
    }
  }

  Future<void> _scanLiveCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() => _statusLine = 'Camera not ready');
      return;
    }
    try {
      AppLogger.i('VISION', 'Starting live camera scan...');
      setState(() => _statusLine = 'Scanning...');
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      final brightness = _visionPipeline.estimateBrightnessFromBytes(bytes);

      final inputImage = InputImage.fromFilePath(file.path);
      final bundle = await _visionPipeline.processInputImage(
        inputImage,
        estimatedBrightness: brightness,
      );

      for (final e in bundle.items) {
        if (e.type == EvidenceType.obstacle) {
          final p = (e.metadata['proximity01'] as num?)?.toDouble() ?? 0;
          if (p >= 0.4) await _hapticService.obstacleProximity(p);
        }
      }

      final query = 'What is in front of me?';

      await _processVerification(bundle, query);

      setState(() {
        _statusLine = 'Scan complete (brightness ${(brightness * 100).toStringAsFixed(0)}%)';
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
    super.dispose();
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        height: 280,
        width: double.infinity,
        color: AppColors.primaryDark,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, color: Colors.white, size: 48),
              SizedBox(height: 8),
              Text("Initializing Camera...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5E3F8),
      appBar: AppBar(
        title: const Text("VISION ASSIST"),
        actions: [
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildCameraPreview(),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isListening ? null : _voiceAsk,
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 32),
                label: Text(_isListening ? "LISTENING..." : "TAP & SAY 'HEY ROOK'"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(60),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              if (_lastResult != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
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
              const SizedBox(height: 16),
              const Text(
                "EVIDENCE",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: _activeEvidence.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "No evidence scanned yet. Run a query or scan.",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
        ),
      ),
    );
  }
}
