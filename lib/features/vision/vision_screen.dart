import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/evidence/evidence.dart';
import '../../core/evidence/evidence_bundle.dart';
import '../../core/evidence/relevance_engine.dart';
import '../../core/evidence/zero_assumption_engine.dart';
import '../../core/evidence/verification_result.dart';
import '../../core/models/confidence_state.dart';
import '../../core/safety/sos_service.dart';
import '../../core/services/impl/haptic_service_impl.dart';
import '../../core/services/impl/image_labeling_service.dart';
import '../../core/services/impl/ocr_service_impl.dart';
import '../../core/services/impl/object_detection_service_impl.dart';
import '../../core/services/impl/speech_input_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';
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
  final _objectService = ObjectDetectionServiceImpl();
  final _labelService = ImageLabelingService();
  final _ttsService = TtsServiceImpl();
  final _hapticService = HapticServiceImpl();
  final _speechService = SpeechInputServiceImpl();
  final _sosService = SosService();
  final _zeroAssumptionEngine = ZeroAssumptionEngine();
  final _relevanceEngine = RelevanceEngine();
  final _sessionStorage = SessionStorage();

  late final VisionPipeline _visionPipeline;

  VerificationResult? _lastResult;
  List<Evidence> _activeEvidence = [];
  String _statusLine = "Listening for 'Hey Rook' or 'Hello Rook'...";
  bool _isScanning = false;
  bool _isWakeWordLooping = false;

  @override
  void initState() {
    super.initState();
    _visionPipeline = VisionPipeline(
      ocrService: _ocrService,
      objectService: _objectService,
      labelService: _labelService,
    );
    _initCameraAndWakeWord();
  }

  Future<void> _initCameraAndWakeWord() async {
    if (!mounted) return;
    await Permission.camera.request();
    await Permission.microphone.request();

    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final backCam = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          backCam,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();
        if (mounted) setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      AppLogger.e('VISION', 'Camera init error: $e');
      if (mounted) setState(() => _isCameraInitialized = false);
    }

    _startWakeWordLoop();
  }

  void _startWakeWordLoop() async {
    if (_isWakeWordLooping) return;
    _isWakeWordLooping = true;

    while (_isWakeWordLooping && mounted) {
      if (!_isScanning) {
        await _speechService.startContinuousStream((text, isFinal) async {
          final lower = text.toLowerCase().trim();
          if (lower.contains("hello rook") || lower.contains("hey rook") || lower.contains("rook")) {
            AppLogger.i('VISION', 'WAKE WORD HEARD: "$text"');
            await _speechService.stop();

            if (lower.contains("help") || lower.contains("sos") || lower.contains("emergency")) {
              await _ttsService.speak("Triggering emergency SOS.");
              await _sosService.sendSosSms();
            } else {
              setState(() => _statusLine = "Wake word heard! Scanning camera...");
              await _ttsService.speak("Scanning camera now.");
              await _scanLiveCamera(text);
            }
          }
        });
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _scanLiveCamera([String? question]) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isScanning) {
      return;
    }

    setState(() => _isScanning = true);

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      final brightness = _visionPipeline.estimateBrightnessFromBytes(bytes);

      final inputImage = InputImage.fromFilePath(file.path);
      final bundle = await _visionPipeline.processInputImage(
        inputImage,
        estimatedBrightness: brightness,
      );

      final query = question ?? "What is in front of me?";
      final rankedItems = _relevanceEngine.rank(query: query, evidence: bundle.items);
      final result = _zeroAssumptionEngine.verify(query: query, bundle: EvidenceBundle(rankedItems));

      setState(() {
        _lastResult = result;
        _activeEvidence = rankedItems;
        _statusLine = "Listening for 'Hey Rook'...";
      });

      for (final e in rankedItems) {
        await _sessionStorage.saveEvidence(e);
      }

      // Speak verified answer out loud to blind user
      await _ttsService.speak(result.message);

      if (result.state == ConfidenceState.verified) {
        await _hapticService.verified();
      } else {
        await _hapticService.uncertain();
      }
    } catch (e) {
      AppLogger.e('VISION', 'Scan error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  void dispose() {
    _isWakeWordLooping = false;
    _speechService.stop();
    _cameraController?.dispose();
    _ocrService.dispose();
    _objectService.dispose();
    _labelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5E3F8), // Light blue
      appBar: AppBar(
        title: const Text("VISION ASSIST"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              if (mounted) AppSettingsDrawer.show(context);
            },
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
                const SnackBar(content: Text("Session memory cleared")),
              );
            },
            tooltip: "Clear Memory",
          ),
        ],
      ),
      body: Column(
        children: [
          // 3:4 Aspect Ratio Camera Box
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 260,
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: _isCameraInitialized && _cameraController != null
                        ? CameraPreview(_cameraController!)
                        : Container(
                            color: AppColors.primaryDark,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.white, size: 48),
                                  SizedBox(height: 8),
                                  Text("Camera Active", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Listening Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                const Icon(Icons.mic, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusLine,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Verification Result Banner
          if (_lastResult != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: _lastResult!.state == ConfidenceState.verified
                  ? AppColors.success.withAlpha(51)
                  : _lastResult!.state == ConfidenceState.conflict
                      ? AppColors.danger.withAlpha(51)
                      : AppColors.warning.withAlpha(51),
              child: Text(
                _lastResult!.message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          // Evidence Feed
          Expanded(
            child: _activeEvidence.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        "Say 'Hello Rook, what is in front of me?' to auto-scan camera and speak answer.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _activeEvidence.length,
                    itemBuilder: (context, index) {
                      return EvidenceCard(
                        evidence: _activeEvidence[index],
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
