import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../../core/evidence/evidence.dart';
import '../../core/evidence/evidence_bundle.dart';
import '../../core/evidence/evidence_thresholds.dart';
import '../../core/models/evidence_source.dart';
import '../../core/models/evidence_type.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/object_detection_service.dart';
import '../../core/services/torch_service.dart';

class VisionPipeline {
  final OcrService ocrService;
  final ObjectDetectionService objectService;
  final TorchService torchService;

  bool _torchAutoOn = false;

  VisionPipeline({
    required this.ocrService,
    required this.objectService,
    required this.torchService,
  });

  bool get isTorchAutoOn => _torchAutoOn;

  /// Estimate brightness 0.0..1.0 from YUV/NV21 or JPEG bytes.
  /// Simple average luminance heuristic.
  double estimateBrightnessFromBytes(Uint8List bytes) {
    if (bytes.isEmpty) return 0.8;
    // Sample every Nth byte for speed
    final step = (bytes.length / 2000).ceil().clamp(1, 50);
    var sum = 0;
    var count = 0;
    for (var i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
      count++;
    }
    if (count == 0) return 0.8;
    return (sum / count / 255.0).clamp(0.0, 1.0);
  }

  Future<bool> applyAutoTorch({
    required double brightness,
    required CameraController? cameraController,
  }) async {
    final low = EvidenceThresholds.isLowLight(brightness);
    try {
      if (cameraController != null && cameraController.value.isInitialized) {
        if (low && !_torchAutoOn) {
          await cameraController.setFlashMode(FlashMode.torch);
          _torchAutoOn = true;
          return true;
        }
        if (!low && _torchAutoOn) {
          await cameraController.setFlashMode(FlashMode.off);
          _torchAutoOn = false;
          return false;
        }
      } else {
        if (low && !_torchAutoOn) {
          await torchService.turnOn();
          _torchAutoOn = true;
          return true;
        }
        if (!low && _torchAutoOn) {
          await torchService.turnOff();
          _torchAutoOn = false;
          return false;
        }
      }
    } catch (_) {}
    return _torchAutoOn;
  }

  Future<EvidenceBundle> processInputImage(
    InputImage image, {
    double estimatedBrightness = 0.8,
    CameraController? cameraController,
  }) async {
    await applyAutoTorch(
      brightness: estimatedBrightness,
      cameraController: cameraController,
    );

    final List<Evidence> collected = [];

    final ocrResults = await ocrService.extractText(image);
    for (final res in ocrResults) {
      collected.add(Evidence(
        source: EvidenceSource.camera,
        type: EvidenceType.ocr,
        value: res.text,
        confidence: res.confidence,
      ));
    }

    final detectedObjects = await objectService.detect(image);
    for (final obj in detectedObjects) {
      final isObstacle =
          obj.proximity01 >= EvidenceThresholds.obstacleProximityMedium;
      collected.add(Evidence(
        source: EvidenceSource.objectDetection,
        type: isObstacle ? EvidenceType.obstacle : EvidenceType.object,
        value: obj.label,
        confidence: obj.confidence,
        metadata: {'proximity01': obj.proximity01},
      ));
    }

    return EvidenceBundle(collected);
  }
}
