import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  static Database? _database;

  factory DbHelper() => _instance;

  DbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'traveltrek_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table to store locations locally when offline
    await db.execute('''
      CREATE TABLE gps_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Table to store pending SOS triggers when offline
    await db.execute('''
      CREATE TABLE pending_alerts (
        id TEXT PRIMARY KEY,
        alert_type TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // Insert location log
  Future<int> insertGpsLog(double lat, double lng, String timestamp) async {
    final db = await database;
    return await db.insert('gps_logs', {
      'latitude': lat,
      'longitude': lng,
      'timestamp': timestamp,
      'is_synced': 0,
    });
  }

  // Get unsynced location logs
  Future<List<Map<String, dynamic>>> getUnsyncedGpsLogs() async {
    final db = await database;
    return await db.query('gps_logs', where: 'is_synced = 0');
  }

  // Mark location logs as synced
  Future<int> markGpsLogsAsSynced(List<int> ids) async {
    final db = await database;
    return await db.update(
      'gps_logs',
      {'is_synced': 1},
      where: 'id IN (${ids.join(',')})',
    );
  }
}
