import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../object_detection_service.dart';

class ImageLabelingService {
  final ImageLabeler _labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.6));

  Future<List<CustomDetectedObject>> labelImage(InputImage image) async {
    try {
      final labels = await _labeler.processImage(image);
      return labels.map((l) => CustomDetectedObject(label: l.label, confidence: l.confidence)).toList();
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    try {
      _labeler.close();
    } catch (_) {}
  }
}
