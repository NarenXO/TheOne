abstract class ObjectDetectionService {
  Future<List<CustomDetectedObject>> detect(dynamic imageInput);
}

class CustomDetectedObject {
  final String label;
  final double confidence;
  final double proximity01;
  CustomDetectedObject({required this.label, required this.confidence, this.proximity01 = 0.0});
}
