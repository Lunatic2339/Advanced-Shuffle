import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/track.dart';

class LocalDatabase {
  // 1. 싱글톤 패턴 세팅 (앱 전체에서 DB 인스턴스는 이거 하나뿐!)
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  // 2. DB 객체 불러오기 (없으면 새로 만듦)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('custom_shuffle.db');
    return _database!;
  }

  // 3. 폰 내부에 파일(DB) 생성 및 경로 설정
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // 4. 테이블(Schema) 뼈대 만들기
  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE track_history (
      id TEXT PRIMARY KEY,
      app_play_count INTEGER NOT NULL DEFAULT 0,
      last_played_at TEXT,
      skip_count INTEGER NOT NULL DEFAULT 0
    )
    ''');
  }

  // ==========================================
  // [CRUD 기능 구현부] 프론트엔드 팀원이 쓸 함수들
  // ==========================================

  // (1) 기록 저장 및 업데이트 (Upsert: 없으면 넣고, 있으면 덮어쓰기)
  Future<void> upsertTrackHistory(Track track) async {
    final db = await instance.database;
    await db.insert(
      'track_history',
      track.toMap(), // 우리가 track.dart에서 만들어둔 그 함수!
      conflictAlgorithm: ConflictAlgorithm.replace, // ID가 겹치면 최신 기록으로 덮어씀
    );
  }

  // (2) 특정 곡의 기록 불러오기 (스포티파이 데이터랑 합칠 때 사용)
  Future<Map<String, dynamic>?> getTrackHistory(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'track_history',
      columns: ['id', 'app_play_count', 'last_played_at', 'skip_count'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null; // 우리 앱에서 한 번도 재생 안 한 곡이면 null 반환
    }
  }
}