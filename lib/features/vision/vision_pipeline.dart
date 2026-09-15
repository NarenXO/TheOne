import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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

  VisionPipeline({
    required this.ocrService,
    required this.objectService,
    required this.torchService,
  });

  Future<EvidenceBundle> processInputImage(
    InputImage image, {
    double estimatedBrightness = 0.8,
  }) async {
    final List<Evidence> collected = [];

    // Low light check & auto-flashlight trigger
    if (EvidenceThresholds.isLowLight(estimatedBrightness)) {
      await torchService.turnOn();
    }

    // 1. Run OCR
    final ocrResults = await ocrService.extractText(image);
    for (final res in ocrResults) {
      collected.add(Evidence(
        source: EvidenceSource.camera,
        type: EvidenceType.ocr,
        value: res.text,
        confidence: res.confidence,
      ));
    }

    // 2. Run Object Detection
    final detectedObjects = await objectService.detect(image);
    for (final obj in detectedObjects) {
      collected.add(Evidence(
        source: EvidenceSource.camera,
        type: obj.proximity01 >= EvidenceThresholds.obstacleProximityMedium
            ? EvidenceType.obstacle
            : EvidenceType.object,
        value: obj.label,
        confidence: obj.confidence,
        metadata: {'proximity01': obj.proximity01},
      ));
    }

    return EvidenceBundle(collected);
  }
}
