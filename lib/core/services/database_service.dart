import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tomate_detection_app/features/authentication/data/models/user_model.dart';

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
      version: 2, // ✅ Versión 2
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
        user_notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        organization TEXT,
        role TEXT DEFAULT 'agricultor',
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ✅ ACTUALIZAR BASE DE DATOS EXISTENTE
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          organization TEXT,
          role TEXT DEFAULT 'agricultor',
          created_at TEXT NOT NULL
        )
      ''');
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

  // =====================================================
  // MÉTODOS PARA USUARIOS
  // =====================================================
  
  Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<bool> userExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }
}