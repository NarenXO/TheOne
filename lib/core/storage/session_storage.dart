import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../evidence/evidence.dart';
import '../models/evidence_source.dart';
import '../models/evidence_type.dart';

class SessionStorage {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'theone_session.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE session_evidence (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source TEXT,
            type TEXT,
            value TEXT,
            confidence REAL,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveEvidence(Evidence evidence) async {
    final db = await database;
    await db.insert('session_evidence', {
      'source': evidence.source.name,
      'type': evidence.type.name,
      'value': evidence.value,
      'confidence': evidence.confidence,
      'timestamp': evidence.timestamp.toIso8601String(),
    });
  }

  Future<List<Evidence>> getRecentEvidence() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'session_evidence',
      orderBy: 'id DESC',
      limit: 20,
    );

    return List.generate(maps.length, (i) {
      return Evidence(
        source: EvidenceSource.values.firstWhere(
          (e) => e.name == maps[i]['source'],
          orElse: () => EvidenceSource.camera,
        ),
        type: EvidenceType.values.firstWhere(
          (e) => e.name == maps[i]['type'],
          orElse: () => EvidenceType.ocr,
        ),
        value: maps[i]['value'],
        confidence: maps[i]['confidence'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
      );
    });
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('session_evidence');
  }
}
