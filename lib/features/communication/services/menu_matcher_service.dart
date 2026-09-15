import '../../../core/models/confidence_state.dart';
import '../../../core/services/ocr_service.dart';
import '../models/intent_result.dart';

class MenuMatcherService {
  static const List<String> _sizes = ['small', 'medium', 'large', 'regular', 'extra'];
  static const List<String> _drinks = ['chai', 'tea', 'coffee', 'water', 'juice', 'milk', 'soda'];
  static const List<String> _foodItems = [
    'samosa', 'sandwich', 'dosa', 'idli', 'rice', 'curry', 'roti', 'naan',
    'biryani', 'noodles', 'soup', 'salad', 'burger', 'pizza', 'pasta'
  ];

  IntentResult generatePhraseFromOcr(List<OcrResult> ocrResults) {
    if (ocrResults.isEmpty) {
      return IntentResult.insufficient("No menu items detected. Please rescan.");
    }

    final detectedTerms = _extractDetectedTerms(ocrResults);
    
    if (detectedTerms.isEmpty) {
      return IntentResult.insufficient("No recognized menu items in scan. Please rescan.");
    }

    final size = detectedTerms.where((t) => _sizes.contains(t.toLowerCase())).firstOrNull;
    final drink = detectedTerms.where((t) => _drinks.contains(t.toLowerCase())).firstOrNull;
    final food = detectedTerms.where((t) => _foodItems.contains(t.toLowerCase())).firstOrNull;

    if (size == null && drink == null && food == null) {
      return IntentResult.insufficient("No recognized menu items in scan. Please rescan.");
    }

    final generatedPhrase = _constructPhrase(size, drink, food);
    final generatedPhraseTamil = _constructPhraseTamil(size, drink, food);

    return IntentResult(
      intent: Intent.orderFood,
      target: generatedPhrase,
      confidence: 0.85,
      generatedEn: generatedPhrase,
      generatedTa: generatedPhraseTamil,
      state: ConfidenceState.verified,
    );
  }

  List<String> _extractDetectedTerms(List<OcrResult> ocrResults) {
    final detectedTerms = <String>[];
    
    for (final result in ocrResults) {
      final words = result.text.split(RegExp(r'[\s,.\-]+'));
      for (final word in words) {
        final cleanWord = word.toLowerCase().trim();
        if (cleanWord.isNotEmpty) {
          detectedTerms.add(cleanWord);
        }
      }
    }
    
    return detectedTerms;
  }

  String _constructPhrase(String? size, String? drink, String? food) {
    final parts = <String>[];
    
    if (size != null) {
      parts.add(size);
    }
    
    if (drink != null) {
      parts.add(drink);
    } else if (food != null) {
      parts.add(food);
    }
    
    if (parts.isEmpty) {
      return "I would like to order something, please.";
    }
    
    return "I would like a ${parts.join(' ')}, please.";
  }

  String _constructPhraseTamil(String? size, String? drink, String? food) {
    final parts = <String>[];
    
    if (size != null) {
      parts.add(size);
    }
    
    if (drink != null) {
      parts.add(drink);
    } else if (food != null) {
      parts.add(food);
    }
    
    if (parts.isEmpty) {
      return "எனக்கு ஏதாவது வேண்டும்.";
    }
    
    return "எனக்கு ${parts.join(' ')} வேண்டும்.";
  }
}