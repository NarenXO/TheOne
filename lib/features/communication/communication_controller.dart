import '../models/phrase_item.dart';
import '../models/intent_result.dart';
import '../services/communication_tts_service.dart';
import '../services/intent_parser_service.dart';
import '../services/menu_matcher_service.dart';
import '../services/translation_service.dart';
import '../data/phrase_repository.dart';
import '../data/sign_repository.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/speech_input_service.dart';

class CommunicationController {
  final PhraseRepository _phraseRepository;
  final SignRepository _signRepository;
  final CommunicationTtsService _ttsService;
  final IntentParserService _intentParser;
  final MenuMatcherService _menuMatcher;
  final TranslationService _translationService;

  CommunicationController()
      : _phraseRepository = PhraseRepository(),
        _signRepository = SignRepository(),
        _ttsService = CommunicationTtsService(),
        _intentParser = IntentParserService(),
        _menuMatcher = MenuMatcherService(),
        _translationService = TranslationService([]);

  Future<void> initialize() async {
    await _phraseRepository.initialize();
    await _signRepository.initialize();
  }

  // Phrase management
  Future<List<PhraseItem>> getAllPhrases() => _phraseRepository.getAllPhrases();
  Future<List<PhraseItem>> getPhrasesByCategory(String category) => 
      _phraseRepository.getPhrasesByCategory(category);
  Future<List<PhraseItem>> getFavoritePhrases() => _phraseRepository.getFavoritePhrases();
  Future<List<PhraseItem>> getCustomPhrases() => _phraseRepository.getCustomPhrases();
  Future<List<PhraseItem>> getRecentPhrases() => _phraseRepository.getRecentPhrases();
  Future<List<PhraseItem>> searchPhrases(String query) => _phraseRepository.searchPhrases(query);
  Future<List<String>> getCategories() => _phraseRepository.getCategories();

  Future<void> createCustomPhrase({
    required String id,
    required String category,
    required String textEn,
    required String textTa,
    List<String>? keywords,
  }) => _phraseRepository.createCustomPhrase(
    id: id,
    category: category,
    textEn: textEn,
    textTa: textTa,
    keywords: keywords,
  );

  Future<void> updatePhrase(PhraseItem phrase) => _phraseRepository.updatePhrase(phrase);
  Future<void> deletePhrase(String id) => _phraseRepository.deletePhrase(id);
  Future<void> toggleFavorite(String id) => _phraseRepository.toggleFavorite(id);

  // Sign management
  Future<List<dynamic>> getAllSigns() => _signRepository.getAllSigns();
  Future<List<dynamic>> getSignsByCategory(String category) => 
      _signRepository.getSignsByCategory(category);
  Future<List<dynamic>> searchSigns(String query) => _signRepository.searchSigns(query);
  Future<List<String>> getSignCategories() => _signRepository.getCategories();

  // TTS operations
  Future<void> speak(String text, {String? language}) => _ttsService.speak(text, languageCode: language);
  Future<void> stopSpeaking() => _ttsService.stop();
  Future<void> setSpeechRate(double rate) => _ttsService.setSpeechRate(rate);
  Future<void> setPitch(double pitch) => _ttsService.setPitch(pitch);
  Future<void> setLanguage(String language) => _ttsService.setLanguage(language);
  bool get isTamilAvailable => _ttsService.isTamilAvailable;
  Future<String> getTamilFallbackMessage() => _ttsService.getTamilFallbackMessage();

  // Intent parsing
  IntentResult parseIntent(String input) => _intentParser.parse(input);

  // Menu OCR
  IntentResult generatePhraseFromOcr(List<OcrResult> ocrResults) => 
      _menuMatcher.generatePhraseFromOcr(ocrResults);

  // Translation
  dynamic translate(String text, {String? fromLanguage, String? toLanguage}) => 
      _translationService.translate(text, fromLanguage: fromLanguage, toLanguage: toLanguage);

  // Phrase speaking with tracking
  Future<void> speakPhrase(PhraseItem phrase, {String? language}) async {
    await _phraseRepository.markAsUsed(phrase.id);
    final text = language == 'ta' ? phrase.textTa : phrase.textEn;
    await _ttsService.speak(text, languageCode: language);
  }

  // Emergency phrases
  Future<List<PhraseItem>> getEmergencyPhrases() => 
      _phraseRepository.getPhrasesByCategory('emergency');
}