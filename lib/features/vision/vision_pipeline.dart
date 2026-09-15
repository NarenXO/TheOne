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
  /// Better heuristic with hysteresis support.
  double estimateBrightnessFromBytes(Uint8List bytes) {
    if (bytes.isEmpty) return 1.0;
    // For JPEG/PNG bytes this is approximate; sample mid-file payload heavily
    final start = (bytes.length * 0.15).toInt();
    final end = (bytes.length * 0.85).toInt();
    if (end <= start) return 1.0;
    var sum = 0;
    var count = 0;
    final step = ((end - start) / 3000).ceil().clamp(1, 100);
    for (var i = start; i < end; i += step) {
      sum += bytes[i];
      count++;
    }
    if (count == 0) return 1.0;
    final avg = sum / count / 255.0;
    // Bias darker because JPEG headers inflate averages
    return (avg * 0.85).clamp(0.0, 1.0);
  }

  Future<bool> applyAutoTorch({
    required double brightness,
    required CameraController? cameraController,
  }) async {
    // Add hysteresis to prevent flickering
    final veryLow = brightness < EvidenceThresholds.lowLightBrightness;
    final veryBright = brightness > 0.70;
    
    try {
      if (cameraController != null && cameraController.value.isInitialized) {
        if (veryLow && !_torchAutoOn) {
          await cameraController.setFlashMode(FlashMode.torch);
          _torchAutoOn = true;
          return true;
        }
        if (veryBright && _torchAutoOn) {
          await cameraController.setFlashMode(FlashMode.off);
          _torchAutoOn = false;
          return false;
        }
      } else {
        if (veryLow && !_torchAutoOn) {
          await torchService.turnOn();
          _torchAutoOn = true;
          return true;
        }
        if (veryBright && _torchAutoOn) {
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
