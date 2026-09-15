abstract class OcrService {
  Future<List<OcrResult>> extractText(dynamic imageInput);
}

class OcrResult {
  final String text;
  final double confidence;
  OcrResult({required this.text, required this.confidence});
}
