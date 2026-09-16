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
  String _statusLine = "🟢 Listening for 'Hey Rook' or tap Ask Rook...";
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

  Future<void> _askRookVoice() async {
    if (_isScanning) return;

    setState(() => _statusLine = "🎙️ Listening to your question...");
    final speechResult = await _speechService.listen();
    final question = speechResult.text.trim();

    if (question.isEmpty) {
      setState(() => _statusLine = "🟢 No voice heard. Tap Ask Rook and speak clearly.");
      await _ttsService.speak("I did not hear a question. Please tap Ask Rook and speak clearly.");
      return;
    }

    setState(() => _statusLine = 'Heard: "$question" — 📷 Scanning camera...');
    await _scanLiveCamera(question);
  }

  Future<void> _scanLiveCamera([String? question]) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
      _statusLine = "📷 Scanning camera & analyzing evidence...";
    });

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

      final query = (question != null && question.isNotEmpty) ? question : "What is in front of me?";
      final rankedItems = _relevanceEngine.rank(query: query, evidence: bundle.items);
      final result = _zeroAssumptionEngine.verify(query: query, bundle: EvidenceBundle(rankedItems));

      setState(() {
        _lastResult = result;
        _activeEvidence = rankedItems;
        _statusLine = "🔊 Rook Speaking...";
      });

      for (final e in rankedItems) {
        await _sessionStorage.saveEvidence(e);
      }

      // ALWAYS Speak verified answer out loud via TTS
      await _ttsService.speak(result.message);

      if (result.state == ConfidenceState.verified) {
        await _hapticService.verified();
      } else {
        await _hapticService.uncertain();
      }
    } catch (e) {
      AppLogger.e('VISION', 'Scan error: $e');
      setState(() => _statusLine = "Scan error: $e. Tap Ask Rook to retry.");
      await _ttsService.speak("Camera scan encountered an error. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusLine = "🟢 Listening for 'Hey Rook' or tap Ask Rook...";
        });
      }
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
                  height: 240,
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

          // Primary Voice Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _askRookVoice,
              icon: const Icon(Icons.mic, color: Colors.white, size: 28),
              label: const Text(
                "ASK ROOK / TAP TO SPEAK",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Verification Result Banner
          if (_lastResult != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _lastResult!.state == ConfidenceState.verified
                    ? AppColors.success.withValues(alpha: 0.2)
                    : _lastResult!.state == ConfidenceState.conflict
                        ? AppColors.danger.withValues(alpha: 0.2)
                        : AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
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
                        "Say 'Hello Rook, what is in front of me?' or tap Ask Rook to scan camera.",
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
