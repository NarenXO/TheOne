import '../../../core/models/confidence_state.dart';
import '../models/phrase_item.dart';

class TranslationService {
  static const Map<String, String> _wordTranslations = {
    'hello': 'வணக்கம்',
    'hi': 'வணக்கம்',
    'thank': 'நன்றி',
    'thanks': 'நன்றி',
    'please': 'தயவுசெய்து',
    'help': 'உதவி',
    'water': 'தண்ணீர்',
    'food': 'உணவு',
    'yes': 'ஆம்',
    'no': 'இல்லை',
    'wait': 'பொறு',
    'morning': 'காலை',
    'day': 'நாள்',
    'good': 'நல்ல',
    'emergency': 'அவசரம்',
    'hospital': 'மருத்துவமனை',
    'doctor': 'மருத்துவர்',
    'ambulance': 'ஆம்புலன்ஸ்',
    'coffee': 'காபி',
    'tea': 'சாய்',
    'chai': 'சாய்',
    'price': 'விலை',
    'cost': 'விலை',
    'where': 'எங்கே',
    'left': 'இடது',
    'right': 'வலது',
    'one': 'ஒன்று',
    'two': 'இரண்டு',
  };

  static const Map<String, String> _tamilToEnglish = {
    'வணக்கம்': 'hello',
    'நன்றி': 'thanks',
    'உதவி': 'help',
    'தண்ணீர்': 'water',
    'உணவு': 'food',
    'ஆம்': 'yes',
    'இல்லை': 'no',
    'மருத்துவமனை': 'hospital',
    'மருத்துவர்': 'doctor',
    'காபி': 'coffee',
    'சாய்': 'tea',
    'விலை': 'price',
    'எங்கே': 'where',
  };

  final List<PhraseItem> _phraseDatabase;

  TranslationService(this._phraseDatabase);

  TranslationResult translate(String text, {String? fromLanguage, String? toLanguage}) {
    // Default: English to Tamil
    final targetLang = toLanguage ?? 'ta';
    final sourceLang = fromLanguage ?? 'en';

    if (sourceLang == targetLang) {
      return TranslationResult(
        translatedText: text,
        confidence: 1.0,
        state: ConfidenceState.verified,
      );
    }

    // Check exact phrase match first
    final phraseMatch = _findPhraseMatch(text, sourceLang, targetLang);
    if (phraseMatch != null) {
      return TranslationResult(
        translatedText: phraseMatch,
        confidence: 1.0,
        state: ConfidenceState.verified,
      );
    }

    // Fall back to word-by-word translation
    if (sourceLang == 'en' && targetLang == 'ta') {
      return _translateEnglishToTamil(text);
    } else if (sourceLang == 'ta' && targetLang == 'en') {
      return _translateTamilToEnglish(text);
    }

    return TranslationResult(
      translatedText: text, // Return original if translation not available
      confidence: 0.0,
      state: ConfidenceState.insufficient,
      message: 'Translation not available',
    );
  }

  String? _findPhraseMatch(String text, String sourceLang, String targetLang) {
    for (final phrase in _phraseDatabase) {
      final sourceText = sourceLang == 'en' ? phrase.textEn : phrase.textTa;
      final targetText = targetLang == 'en' ? phrase.textEn : phrase.textTa;
      
      if (sourceText.toLowerCase() == text.toLowerCase()) {
        return targetText;
      }
    }
    return null;
  }

  TranslationResult _translateEnglishToTamil(String text) {
    final words = text.split(RegExp(r'\s+'));
    final translatedWords = <String>[];
    var translationCount = 0;

    for (final word in words) {
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[.,!?;:]$'), '');
      if (_wordTranslations.containsKey(cleanWord)) {
        translatedWords.add(_wordTranslations[cleanWord]!);
        translationCount++;
      } else {
        translatedWords.add(word); // Keep original if no translation
      }
    }

    final confidence = translationCount / words.length;
    final translatedText = translatedWords.join(' ');

    if (confidence >= 0.8) {
      return TranslationResult(
        translatedText: translatedText,
        confidence: confidence,
        state: ConfidenceState.verified,
      );
    } else if (confidence >= 0.5) {
      return TranslationResult(
        translatedText: translatedText,
        confidence: confidence,
        state: ConfidenceState.uncertain,
        message: 'Partial translation - some words could not be translated',
      );
    } else {
      return TranslationResult(
        translatedText: text,
        confidence: confidence,
        state: ConfidenceState.insufficient,
        message: 'Translation not available for most words',
      );
    }
  }

  TranslationResult _translateTamilToEnglish(String text) {
    final words = text.split(RegExp(r'\s+'));
    final translatedWords = <String>[];
    var translationCount = 0;

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[.,!?;:]$'), '');
      if (_tamilToEnglish.containsKey(cleanWord)) {
        translatedWords.add(_tamilToEnglish[cleanWord]!);
        translationCount++;
      } else {
        translatedWords.add(word); // Keep original if no translation
      }
    }

    final confidence = translationCount / words.length;
    final translatedText = translatedWords.join(' ');

    if (confidence >= 0.8) {
      return TranslationResult(
        translatedText: translatedText,
        confidence: confidence,
        state: ConfidenceState.verified,
      );
    } else if (confidence >= 0.5) {
      return TranslationResult(
        translatedText: translatedText,
        confidence: confidence,
        state: ConfidenceState.uncertain,
        message: 'Partial translation - some words could not be translated',
      );
    } else {
      return TranslationResult(
        translatedText: text,
        confidence: confidence,
        state: ConfidenceState.insufficient,
        message: 'Translation not available for most words',
      );
    }
  }
}

class TranslationResult {
  final String translatedText;
  final double confidence;
  final ConfidenceState state;
  final String? message;

  TranslationResult({
    required this.translatedText,
    required this.confidence,
    required this.state,
    this.message,
  });
}