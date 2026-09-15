import '../object_detection_service.dart';

class ObjectDetectionServiceImpl implements ObjectDetectionService {
  @override
  Future<List<DetectedObject>> detect(dynamic imageInput) async {
    // Basic local object detection adapter interface
    // Will return empty list or structured bounding objects when raw frame/image is provided
    return [];
  }
}
