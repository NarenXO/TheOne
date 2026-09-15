import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/sign_entry.dart';

class SignRepository {
  List<SignEntry>? _cachedSigns;

  Future<void> initialize() async {
    await _loadSeedData();
  }

  Future<void> _loadSeedData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/signs.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _cachedSigns = jsonList
          .map((jsonItem) => SignEntry.fromJson(jsonItem as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _cachedSigns = [];
    }
  }

  Future<List<SignEntry>> getAllSigns() async {
    if (_cachedSigns == null) {
      await _loadSeedData();
    }
    return _cachedSigns!;
  }

  Future<List<SignEntry>> getSignsByCategory(String category) async {
    final allSigns = await getAllSigns();
    return allSigns.where((sign) => sign.category == category).toList();
  }

  Future<SignEntry?> getSign(String id) async {
    final allSigns = await getAllSigns();
    try {
      return allSigns.firstWhere((sign) => sign.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<SignEntry>> searchSigns(String query) async {
    final allSigns = await getAllSigns();
    return allSigns.where((sign) => sign.matchesQuery(query)).toList();
  }

  Future<List<String>> getCategories() async {
    final allSigns = await getAllSigns();
    final categories = allSigns.map((s) => s.category).toSet().toList();
    categories.sort();
    return categories;
  }

  Future<List<SignEntry>> getFilteredSigns({
    String? category,
    String? query,
  }) async {
    var signs = await getAllSigns();
    
    if (category != null) {
      signs = signs.where((s) => s.category == category).toList();
    }
    
    if (query != null && query.isNotEmpty) {
      signs = signs.where((s) => s.matchesQuery(query)).toList();
    }
    
    return signs;
  }
}
