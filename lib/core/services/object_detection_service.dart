abstract class ObjectDetectionService {
  Future<List<DetectedObject>> detect(dynamic imageInput);
}

class DetectedObject {
  final String label;
  final double confidence;
  final double proximity01;
  DetectedObject({required this.label, required this.confidence, this.proximity01 = 0.0});
}
