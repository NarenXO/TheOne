import '../models/intent_result.dart';
import '../services/tamil_english_normalizer.dart';
import '../../../core/models/confidence_state.dart';

class IntentParserService {
  IntentResult parse(String input) {
    final normalized = TamilEnglishNormalizer.normalize(input);
    final keywords = TamilEnglishNormalizer.extractKeywords(input);

    if (keywords.isEmpty) {
      return IntentResult.insufficient("I couldn't understand. Please try again.");
    }

    // ASK_LOCATION intent
    if (TamilEnglishNormalizer.containsLocationKeywords(input)) {
      final target = _extractTarget(input, keywords);
      final confidence = target.isNotEmpty ? 0.9 : 0.7;
      
      return IntentResult(
        intent: Intent.askLocation,
        target: target.isNotEmpty ? target : null,
        confidence: confidence,
        generatedEn: _generateLocationSentence(target),
        generatedTa: _generateLocationSentenceTamil(target),
        state: confidence >= 0.85 ? ConfidenceState.verified : ConfidenceState.uncertain,
      );
    }

    // ORDER_FOOD intent
    if (TamilEnglishNormalizer.containsFoodKeywords(input)) {
      final target = _extractFoodTarget(input, keywords);
      final confidence = target.isNotEmpty ? 0.9 : 0.7;
      
      return IntentResult(
        intent: Intent.orderFood,
        target: target.isNotEmpty ? target : null,
        confidence: confidence,
        generatedEn: _generateFoodSentence(target),
        generatedTa: _generateFoodSentenceTamil(target),
        state: confidence >= 0.85 ? ConfidenceState.verified : ConfidenceState.uncertain,
      );
    }

    // PRICE intent
    if (TamilEnglishNormalizer.containsPriceKeywords(input)) {
      return IntentResult(
        intent: Intent.price,
        confidence: 0.9,
        generatedEn: "Could you please tell me how much this costs?",
        generatedTa: "இதன் விலை என்ன?",
        state: ConfidenceState.verified,
      );
    }

    // REQUEST_HELP intent
    if (TamilEnglishNormalizer.containsHelpKeywords(input)) {
      return IntentResult(
        intent: Intent.requestHelp,
        confidence: 0.95,
        generatedEn: "I need help, please.",
        generatedTa: "எனக்கு உதவி தேவை.",
        state: ConfidenceState.verified,
      );
    }

    // EMERGENCY intent
    if (keywords.contains('emergency') || keywords.contains('danger')) {
      return IntentResult(
        intent: Intent.emergency,
        confidence: 1.0,
        generatedEn: "This is an emergency! I need help immediately.",
        generatedTa: "இது அவசரம்! எனக்கு உடனே உதவி தேவை.",
        state: ConfidenceState.verified,
      );
    }

    // GREETING intent
    if (TamilEnglishNormalizer.containsGreetingKeywords(input)) {
      return IntentResult(
        intent: Intent.greeting,
        confidence: 0.9,
        generatedEn: "Hello, good to see you.",
        generatedTa: "வணக்கம், உங்களைப் பார்த்ததில் மகிழ்ச்சி.",
        state: ConfidenceState.verified,
      );
    }

    // THANKS intent
    if (TamilEnglishNormalizer.containsThanksKeywords(input)) {
      return IntentResult(
        intent: Intent.thanks,
        confidence: 0.95,
        generatedEn: "Thank you very much.",
        generatedTa: "மிக்க நன்றி.",
        state: ConfidenceState.verified,
      );
    }

    // REPEAT intent
    if (TamilEnglishNormalizer.containsRepeatKeywords(input)) {
      return IntentResult(
        intent: Intent.repeat,
        confidence: 0.9,
        generatedEn: "Could you please repeat that?",
        generatedTa: "மீண்டும் சொல்ல முடியுமா?",
        state: ConfidenceState.verified,
      );
    }

    // WAIT intent
    if (TamilEnglishNormalizer.containsWaitKeywords(input)) {
      return IntentResult(
        intent: Intent.wait,
        confidence: 0.9,
        generatedEn: "Please wait a moment.",
        generatedTa: "கொஞ்சம் பொறுங்கள்.",
        state: ConfidenceState.verified,
      );
    }

    // DIRECTION intent
    if (TamilEnglishNormalizer.containsDirectionKeywords(input)) {
      return IntentResult(
        intent: Intent.direction,
        confidence: 0.85,
        generatedEn: "Which direction should I go?",
        generatedTa: "நான் எந்த திசையில் செல்ல வேண்டும்?",
        state: ConfidenceState.verified,
      );
    }

    // Unknown intent with low confidence
    return IntentResult.uncertain(
      "I'm not sure what you mean. Could you please rephrase?",
      "நீங்கள் என்ன சொல்கிறீர்கள் என்று எனக்குத் தெரியவில்லை. தயவுசெய்து மீண்டும் சொல்லவும்.",
    );
  }

  String _extractTarget(String input, List<String> keywords) {
    // Try to extract a specific target from the input
    final locationKeywords = ['where', 'enga', 'location', 'address', 'desk', 'counter', 'irukku'];
    final words = input.split(RegExp(r'\s+'));
    
    // Look for words that aren't location keywords
    final targets = words.where((word) {
      final lower = word.toLowerCase();
      return !locationKeywords.contains(lower) && 
             !TamilEnglishNormalizer.tanglishToEnglish.containsKey(lower);
    }).toList();
    
    return targets.isNotEmpty ? targets.join(' ') : '';
  }

  String _extractFoodTarget(String input, List<String> keywords) {
    final foodKeywords = ['venum', 'kudunga', 'chai', 'coffee', 'tea', 'order', 'want', 'saapadu', 'kaapi'];
    final words = input.split(RegExp(r'\s+'));
    
    final targets = words.where((word) {
      final lower = word.toLowerCase();
      return foodKeywords.contains(lower) || 
             ['small', 'medium', 'large'].contains(lower);
    }).toList();
    
    return targets.isNotEmpty ? targets.join(' ') : '';
  }

  String _generateLocationSentence(String target) {
    if (target.isNotEmpty) {
      return "Could you please tell me where the $target is?";
    }
    return "Could you please tell me where that is?";
  }

  String _generateLocationSentenceTamil(String target) {
    if (target.isNotEmpty) {
      return "$target எங்குள்ளது என்று தயவுசெய்து சொல்ல முடியுமா?";
    }
    return "அது எங்குள்ளது என்று தயவுசெய்து சொல்ல முடியுமா?";
  }

  String _generateFoodSentence(String target) {
    if (target.isNotEmpty) {
      return "I would like $target, please.";
    }
    return "I would like to order something, please.";
  }

  String _generateFoodSentenceTamil(String target) {
    if (target.isNotEmpty) {
      return "எனக்கு $target வேண்டும்.";
    }
    return "எனக்கு ஏதாவது வேண்டும்.";
  }
}