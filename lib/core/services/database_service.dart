import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

    Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/tomate_detection.db';
    return await openDatabase(
      path,
      version: 5, // v3: detections_json; v4: sin tabla users; v5: server_id
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // ✅ Agregar onUpgrade
    );
  }

  // ✅ CREAR TABLAS
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diagnostics(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diagnostic_id TEXT UNIQUE,
        image_path TEXT,
        disease TEXT,
        confidence REAL,
        latitude REAL,
        longitude REAL,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0,
        user_notes TEXT,
        detections_json TEXT,
        server_id TEXT
      )
    ''');

  }

  // ✅ ACTUALIZAR BASE DE DATOS EXISTENTE
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE diagnostics ADD COLUMN detections_json TEXT');
    }
    if (oldVersion < 4) {
      // Los usuarios viven en el backend; esta tabla guardaba contraseñas en texto plano
      await db.execute('DROP TABLE IF EXISTS users');
    }
    if (oldVersion < 5) {
      // Id del diagnostico en el servidor: evita duplicados al descargar el historial
      await db.execute('ALTER TABLE diagnostics ADD COLUMN server_id TEXT');
    }
  }

  
  // =====================================================
  // GUARDAR DIAGNÓSTICO
  // =====================================================
  Future<void> saveDiagnostic(Map<String, dynamic> diagnostic) async {
    final db = await database;
    await db.insert(
      'diagnostics',
      diagnostic,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // =====================================================
  // OBTENER TODOS LOS DIAGNÓSTICOS (CON FILTROS)
  // =====================================================
  Future<List<Map<String, dynamic>>> getDiagnostics({
    String? disease,
    String? search,
  }) async {
    final db = await database;
    
    String where = '1=1';
    List<dynamic> args = [];
    
    if (search != null && search.isNotEmpty) {
      where += ' AND (disease LIKE ? OR created_at LIKE ?)';
      final searchPattern = '%$search%';
      args.addAll([searchPattern, searchPattern]);
    }
    
    if (disease != null && disease.isNotEmpty && disease != 'Todos') {
      where += ' AND disease = ?';
      args.add(disease);
    }
    
    return await db.query(
      'diagnostics',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
  }

  // =====================================================
  // OBTENER DIAGNÓSTICO POR ID
  // =====================================================
  Future<Map<String, dynamic>?> getDiagnosticById(String diagnosticId) async {
    final db = await database;
    final result = await db.query(
      'diagnostics',
      where: 'diagnostic_id = ?',
      whereArgs: [diagnosticId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // =====================================================
  // ELIMINAR DIAGNÓSTICO
  // =====================================================
  Future<int> deleteDiagnostic(String diagnosticId) async {
    final db = await database;
    return await db.delete(
      'diagnostics',
      where: 'diagnostic_id = ?',
      whereArgs: [diagnosticId],
    );
  }

  // =====================================================
  // OBTENER DIAGNÓSTICOS PENDIENTES DE SINCRONIZAR
  // =====================================================
  Future<List<Map<String, dynamic>>> getPendingDiagnostics() async {
    final db = await database;
    return await db.query(
      'diagnostics',
      where: 'is_synced = 0',
    );
  }

  // =====================================================
  // MARCAR COMO SINCRONIZADO
  // =====================================================
  Future<void> markAsSynced(String diagnosticId) async {
    final db = await database;
    await db.update(
      'diagnostics',
      {'is_synced': 1},
      where: 'diagnostic_id = ?',
      whereArgs: [diagnosticId],
    );
  }

  Future<void> setServerId(String diagnosticId, String serverId) async {
    final db = await database;
    await db.update('diagnostics', {'server_id': serverId, 'is_synced': 1},
        where: 'diagnostic_id = ?', whereArgs: [diagnosticId]);
  }

  Future<Set<String>> getServerIds() async {
    final db = await database;
    final rows = await db.query('diagnostics', columns: ['server_id'], where: 'server_id IS NOT NULL');
    return rows.map((r) => r['server_id'] as String).toSet();
  }

  /// Al cerrar sesion: borra lo que ya esta en el servidor (se puede volver a
  /// descargar) y deja los pendientes de subir. Devuelve las imagenes borradas.
  Future<List<String>> deleteSynced() async {
    final db = await database;
    final rows = await db.query('diagnostics', columns: ['image_path'], where: 'is_synced = 1');
    await db.delete('diagnostics', where: 'is_synced = 1');
    return rows.map((r) => r['image_path'] as String?).whereType<String>().toList();
  }

  // =====================================================
  // OBTENER TODOS LOS DIAGNÓSTICOS (SIN FILTROS)
  // =====================================================
  Future<List<Map<String, dynamic>>> getAllDiagnostics() async {
    final db = await database;
    return await db.query('diagnostics', orderBy: 'created_at DESC');
  }

  // =====================================================
  // CONTADORES PARA ESTADÍSTICAS
  // =====================================================
  Future<int> getTotalDiagnostics() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM diagnostics');
    return result.first['count'] as int;
  }

  Future<int> getDiseaseCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM diagnostics WHERE disease != 'sana'"
    );
    return result.first['count'] as int;
  }

  Future<int> getHealthyCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM diagnostics WHERE disease = 'sana'"
    );
    return result.first['count'] as int;
  }

  Future<Map<String, int>> getDiseaseStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT disease, COUNT(*) as count 
      FROM diagnostics 
      GROUP BY disease 
      ORDER BY count DESC
    ''');
    
    final stats = <String, int>{};
    for (var row in result) {
      stats[row['disease'] as String] = row['count'] as int;
    }
    return stats;
  }
}
