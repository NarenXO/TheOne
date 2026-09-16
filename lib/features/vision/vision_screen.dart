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
import '../../core/services/impl/haptic_service_impl.dart';
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
  final _relevanceEngine = RelevanceEngine();
  final _sessionStorage = SessionStorage();
  final _objectService = ObjectDetectionServiceImpl();
  late final VisionPipeline _visionPipeline;

  final _speechService = SpeechInputServiceImpl();

  VerificationResult? _lastResult;
  List<Evidence> _activeEvidence = [];
  String _lastHeardQuery = "";
  String _statusLine = 'Tap button to ask Rook or scan...';

  @override
  void initState() {
    super.initState();
    _visionPipeline = VisionPipeline(
      ocrService: _ocrService,
      objectService: _objectService,
    );
    _initCamera();
  }

  Future<void> _handleVoiceCommandOnce() async {
    setState(() => _statusLine = 'Listening...');
    final r = await _speechService.listen();
    final text = r.text.trim();
    AppLogger.i('VISION', 'Heard: "$text"');
    if (text.isEmpty) {
      setState(() => _statusLine = 'No speech captured. Try again closer to mic.');
      await _ttsService.speak('I did not hear anything. Please try again.');
      return;
    }
    final lower = text.toLowerCase();
    if (lower.contains('help') || lower.contains('sos') || lower.contains('emergency')) {
      await _ttsService.speak('Sending emergency SOS');
      await SosService().sendSosSms();
      return;
    }
    // strip wake words if present
    final q = text
        .replaceAll(RegExp(r'hello rook|hey rook|hi rook|rook', caseSensitive: false), '')
        .trim();
    _lastHeardQuery = q.isEmpty ? 'What is in front of me?' : q;
    setState(() => _statusLine = 'Heard: $text. Scanning...');
    await _ttsService.speak('Scanning now');
    await _scanLiveCamera();
  }

  Future<void> _scanLiveCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      await _cameraController!.pausePreview();
      final file = await _cameraController!.takePicture();
      await _cameraController!.resumePreview();

      final bytes = await file.readAsBytes();
      final brightness = _visionPipeline.estimateBrightnessFromBytes(bytes);

      final inputImage = InputImage.fromFilePath(file.path);
      final bundle = await _visionPipeline.processInputImage(
        inputImage,
        estimatedBrightness: brightness,
      );

      final query = _lastHeardQuery.isNotEmpty ? _lastHeardQuery : "What is in front of me?";
      final rankedItems = _relevanceEngine.rank(query: query, evidence: bundle.items);
      final result = _zeroAssumptionEngine.verify(query: query, bundle: EvidenceBundle(rankedItems));

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
    } catch (e) {
      AppLogger.e('CAMERA', 'Safe capture error: $e');
      try { await _cameraController?.resumePreview(); } catch (_) {}
    }
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

  @override
  void dispose() {
    _speechService.stop();
    _cameraController?.dispose();
    _cameraController = null;
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
