import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:theone/features/communication/models/phrase_item.dart';

class CommunicationDatabase {
  static final CommunicationDatabase _instance = CommunicationDatabase._internal();
  static Database? _database;

  factory CommunicationDatabase() => _instance;

  CommunicationDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'communication.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Phrases table
    await db.execute('''
      CREATE TABLE phrases (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        text_en TEXT NOT NULL,
        text_ta TEXT NOT NULL,
        keywords TEXT NOT NULL,
        is_favorite INTEGER DEFAULT 0,
        is_custom INTEGER DEFAULT 0,
        usage_count INTEGER DEFAULT 0,
        last_used_at TEXT
      )
    ''');

    // Recent phrases table (LRU cache)
    await db.execute('''
      CREATE TABLE recent_phrases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phrase_id TEXT NOT NULL,
        accessed_at TEXT NOT NULL,
        FOREIGN KEY (phrase_id) REFERENCES phrases (id) ON DELETE CASCADE
      )
    ''');

    // Create index for faster LRU queries
    await db.execute('CREATE INDEX idx_recent_accessed ON recent_phrases(accessed_at)');
  }

  // Phrase CRUD operations
  Future<void> insertPhrase(PhraseItem phrase) async {
    final db = await database;
    await db.insert(
      'phrases',
      phrase.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PhraseItem?> getPhrase(String id) async {
    final db = await database;
    final maps = await db.query(
      'phrases',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return PhraseItem.fromJson(maps.first);
  }

  Future<List<PhraseItem>> getAllPhrases() async {
    final db = await database;
    final maps = await db.query('phrases');
    return maps.map((map) => PhraseItem.fromJson(map)).toList();
  }

  Future<List<PhraseItem>> getPhrasesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'phrases',
      where: 'category = ?',
      whereArgs: [category],
    );
    return maps.map((map) => PhraseItem.fromJson(map)).toList();
  }

  Future<List<PhraseItem>> getFavoritePhrases() async {
    final db = await database;
    final maps = await db.query(
      'phrases',
      where: 'is_favorite = ?',
      whereArgs: [1],
    );
    return maps.map((map) => PhraseItem.fromJson(map)).toList();
  }

  Future<List<PhraseItem>> getCustomPhrases() async {
    final db = await database;
    final maps = await db.query(
      'phrases',
      where: 'is_custom = ?',
      whereArgs: [1],
    );
    return maps.map((map) => PhraseItem.fromJson(map)).toList();
  }

  Future<void> updatePhrase(PhraseItem phrase) async {
    final db = await database;
    await db.update(
      'phrases',
      phrase.toJson(),
      where: 'id = ?',
      whereArgs: [phrase.id],
    );
  }

  Future<void> deletePhrase(String id) async {
    final db = await database;
    await db.delete(
      'phrases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleFavorite(String id) async {
    final phrase = await getPhrase(id);
    if (phrase != null) {
      final updated = phrase.copyWith(isFavorite: !phrase.isFavorite);
      await updatePhrase(updated);
    }
  }

  Future<void> incrementUsageCount(String id) async {
    final phrase = await getPhrase(id);
    if (phrase != null) {
      phrase.markAsUsed();
      await updatePhrase(phrase);
    }
  }

  // Recent phrases (LRU) operations
  Future<void> addToRecent(String phraseId) async {
    final db = await database;
    
    // Add new entry
    await db.insert(
      'recent_phrases',
      {
        'phrase_id': phraseId,
        'accessed_at': DateTime.now().toIso8601String(),
      },
    );

    // Enforce LRU limit of 5
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM recent_phrases')
    );
    
    if (count != null && count > 5) {
      // Remove oldest entry
      await db.rawDelete('''
        DELETE FROM recent_phrases 
        WHERE id = (
          SELECT id FROM recent_phrases 
          ORDER BY accessed_at ASC 
          LIMIT 1
        )
      ''');
    }
  }

  Future<List<PhraseItem>> getRecentPhrases() async {
    final db = await database;
    
    final maps = await db.rawQuery('''
      SELECT p.* FROM phrases p
      INNER JOIN recent_phrases r ON p.id = r.phrase_id
      ORDER BY r.accessed_at DESC
      LIMIT 5
    ''');
    
    return maps.map((map) => PhraseItem.fromJson(map)).toList();
  }

  Future<void> clearRecentPhrases() async {
    final db = await database;
    await db.delete('recent_phrases');
  }

  // Database maintenance
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('recent_phrases');
    await db.delete('phrases');
  }
}
