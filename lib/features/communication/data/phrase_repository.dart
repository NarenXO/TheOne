import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:theone/features/communication/models/phrase_item.dart';
import 'communication_database.dart';

class PhraseRepository {
  final CommunicationDatabase _database = CommunicationDatabase();
  List<PhraseItem>? _cachedPhrases;

  Future<void> initialize() async {
    await _loadSeedData();
  }

  Future<void> _loadSeedData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/phrases.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      for (final jsonItem in jsonList) {
        final phrase = PhraseItem.fromJson(jsonItem as Map<String, dynamic>);
        await _database.insertPhrase(phrase);
      }
      
      _cachedPhrases = await _database.getAllPhrases();
    } catch (e) {
      // If seed data loading fails, we'll work with empty database
      _cachedPhrases = [];
    }
  }

  Future<List<PhraseItem>> getAllPhrases() async {
    if (_cachedPhrases == null) {
      _cachedPhrases = await _database.getAllPhrases();
    }
    return _cachedPhrases!;
  }

  Future<List<PhraseItem>> getPhrasesByCategory(String category) async {
    return await _database.getPhrasesByCategory(category);
  }

  Future<List<PhraseItem>> getFavoritePhrases() async {
    return await _database.getFavoritePhrases();
  }

  Future<List<PhraseItem>> getCustomPhrases() async {
    return await _database.getCustomPhrases();
  }

  Future<List<PhraseItem>> getRecentPhrases() async {
    return await _database.getRecentPhrases();
  }

  Future<PhraseItem?> getPhrase(String id) async {
    return await _database.getPhrase(id);
  }

  Future<List<PhraseItem>> searchPhrases(String query) async {
    final allPhrases = await getAllPhrases();
    final lowerQuery = query.toLowerCase();
    
    return allPhrases.where((phrase) {
      return phrase.textEn.toLowerCase().contains(lowerQuery) ||
             phrase.textTa.contains(lowerQuery) ||
             phrase.keywords.any((kw) => kw.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  Future<void> createCustomPhrase({
    required String id,
    required String category,
    required String textEn,
    required String textTa,
    List<String>? keywords,
  }) async {
    final phrase = PhraseItem(
      id: id,
      category: category,
      textEn: textEn,
      textTa: textTa,
      keywords: keywords ?? [],
      isCustom: true,
    );
    
    await _database.insertPhrase(phrase);
    _cachedPhrases = null; // Invalidate cache
  }

  Future<void> updatePhrase(PhraseItem phrase) async {
    await _database.updatePhrase(phrase);
    _cachedPhrases = null; // Invalidate cache
  }

  Future<void> deletePhrase(String id) async {
    await _database.deletePhrase(id);
    _cachedPhrases = null; // Invalidate cache
  }

  Future<void> toggleFavorite(String id) async {
    await _database.toggleFavorite(id);
    _cachedPhrases = null; // Invalidate cache
  }

  Future<void> markAsUsed(String id) async {
    await _database.incrementUsageCount(id);
    await _database.addToRecent(id);
    _cachedPhrases = null; // Invalidate cache
  }

  Future<List<String>> getCategories() async {
    final phrases = await getAllPhrases();
    final categories = phrases.map((p) => p.category).toSet().toList();
    categories.sort();
    return categories;
  }
}
