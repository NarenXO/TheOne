import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../object_detection_service.dart';

class ObjectDetectionServiceImpl implements ObjectDetectionService {
  late final ObjectDetector _detector;

  ObjectDetectionServiceImpl() {
    _detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
  }

  @override
  Future<List<CustomDetectedObject>> detect(dynamic imageInput) async {
    if (imageInput is! InputImage) return [];

    try {
      final objects = await _detector.processImage(imageInput);
      final results = <CustomDetectedObject>[];

      for (final obj in objects) {
        final label = obj.labels.isNotEmpty
            ? obj.labels.first.text
            : 'object';
        final conf = obj.labels.isNotEmpty
            ? obj.labels.first.confidence
            : 0.5;

        // proximity01 estimate from bounding box relative size (NOT exact meters)
        final box = obj.boundingBox;
        final area = box.width * box.height;
        // larger box => closer. Clamp 0..1 using heuristic scale.
        final proximity01 = (area / 300000.0).clamp(0.0, 1.0);

        results.add(CustomDetectedObject(
          label: label,
          confidence: conf,
          proximity01: proximity01,
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<void> dispose() async {
    await _detector.close();
  }
}
