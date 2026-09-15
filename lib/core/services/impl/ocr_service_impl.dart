import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../utils/app_logger.dart';
import '../ocr_service.dart';

class OcrServiceImpl implements OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<List<OcrResult>> extractText(dynamic imageInput) async {
    if (imageInput is! InputImage) {
      return [];
    }

    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(imageInput);
      final List<OcrResult> results = [];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          if (line.text.trim().isNotEmpty) {
            results.add(OcrResult(
              text: line.text.trim(),
              confidence: 0.95, // ML Kit does not expose line-level confidence; high nominal confidence for recognized text
            ));
          }
        }
      }
      AppLogger.i('OCR', 'Processed image, found ${results.length} text lines');
      for (final r in results) {
        AppLogger.i('OCR', ' Line: "${r.text}" (conf: ${r.confidence})');
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
