import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/evidence/evidence.dart';
import '../../core/evidence/zero_assumption_engine.dart';
import '../../core/evidence/verification_result.dart';
import '../../core/models/confidence_state.dart';
import '../../core/services/impl/haptic_service_impl.dart';
import '../../core/services/impl/image_labeling_service.dart';
import '../../core/services/impl/object_detection_service_impl.dart';
import '../../core/services/impl/ocr_service_impl.dart';
import '../../core/services/impl/speech_input_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';
import '../../core/safety/sos_service.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_settings_drawer.dart';
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
  final _sessionStorage = SessionStorage();
  final _objectService = ObjectDetectionServiceImpl();
  final _labelService = ImageLabelingService();
  late final VisionPipeline _visionPipeline;

  final _speechService = SpeechInputServiceImpl();

  VerificationResult? _lastResult;
  List<Evidence> _activeEvidence = [];
  String _lastHeardQuery = "";
  String _statusLine = 'Always listening for "Hey Rook"...';
  bool _isWakeWordLooping = false;

  @override
  void initState() {
    super.initState();
    _visionPipeline = VisionPipeline(
      ocrService: _ocrService,
      objectService: _objectService,
      labelService: _labelService,
    );
    _initCamera();
    _startWakeWordLoop();
  }

  void _startWakeWordLoop() async {
    _isWakeWordLooping = true;
    while (_isWakeWordLooping && mounted) {
      if (!_speechService.isListening) {
        await _speechService.startContinuousStream((text, isFinal) async {
          final lower = text.toLowerCase();
          if (lower.contains("hello rook") || lower.contains("hey rook") || lower.contains("rook")) {
            await _speechService.stop();
            if (mounted) setState(() => _statusLine = "Wake word detected! Scanning...");
            _lastHeardQuery = text;

            if (lower.contains("help") || lower.contains("emergency") || lower.contains("sos")) {
              await _ttsService.speak("Triggering emergency SOS.");
              await SosService().sendSosSms();
            } else {
              await _ttsService.speak("Scanning");
              await _scanLiveCamera();
            }
          }
        });
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() => _isCameraInitialized = true);
  }

  Future<void> _scanLiveCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final bundle = await _visionPipeline.processInputImage(inputImage);
      if (!mounted) return;

      final evidence = bundle.items;
      setState(() {
        _activeEvidence = evidence;
      });

      final labelNames = evidence.map((e) => e.value).where((c) => c.isNotEmpty).toList();
      String speechText = "I could not detect any distinct objects.";
      if (labelNames.isNotEmpty) {
        if (labelNames.length == 1) {
          speechText = "I see ${labelNames.first} in front of you.";
        } else if (labelNames.length == 2) {
          speechText = "I see ${labelNames[0]} and ${labelNames[1]} in front of you.";
        } else {
          final joined = labelNames.sublist(0, labelNames.length - 1).join(", ");
          speechText = "I see $joined, and ${labelNames.last} in front of you.";
        }
      }

      final verResult = _zeroAssumptionEngine.verify(
        query: _lastHeardQuery.isEmpty ? "What is in front of me?" : _lastHeardQuery,
        bundle: bundle,
      );
      if (mounted) {
        setState(() {
          _lastResult = verResult;
          _statusLine = speechText;
        });
      }
      await _ttsService.speak(speechText);
      await _hapticService.verified();
    } catch (e) {
      AppLogger.e('VISION', 'Error scanning live camera: $e');
    }
  }

  Future<void> _handleVoiceCommandOnce() async {
    setState(() => _statusLine = "Listening...");
    final result = await _speechService.listen();
    if (result.text.isNotEmpty) {
      _lastHeardQuery = result.text;
      await _scanLiveCamera();
    } else {
      setState(() => _statusLine = "No speech detected.");
    }
  }

  @override
  void dispose() {
    _isWakeWordLooping = false;
    _speechService.stop();
    _cameraController?.dispose();
    _cameraController = null;
    _ocrService.dispose();
    _objectService.dispose();
    _labelService.dispose();
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
            icon: const Icon(Icons.settings),
            onPressed: () => AppSettingsDrawer.show(context),
            tooltip: "Settings",
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
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleVoiceCommandOnce,
                icon: const Icon(Icons.mic, color: Colors.white, size: 28),
                label: const Text(
                  "HOLD TO TALK / ASK ROOK",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
