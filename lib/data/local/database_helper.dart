import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE queue_operations (
        id TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        op TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');
  }

  // Task CRUD operations
  Future<Task> createTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    return task;
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'deleted = ?',
      whereArgs: [0],
      orderBy: 'updated_at DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'id = ? AND deleted = ?',
      whereArgs: [id, 0],
    );

    if (result.isNotEmpty) {
      return Task.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return db.update('tasks', {'deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> hardDeleteTask(String id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Queue operations
  Future<void> addQueueOperation(QueuedOperation operation) async {
    final db = await database;
    await db.insert('queue_operations', operation.toMap());
  }

  Future<List<QueuedOperation>> getPendingOperations() async {
    final db = await database;
    final result = await db.query(
      'queue_operations',
      orderBy: 'created_at ASC',
    );
    return result.map((json) => QueuedOperation.fromMap(json)).toList();
  }

  Future<void> removeQueueOperation(String id) async {
    final db = await database;
    await db.delete('queue_operations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateQueueOperation(QueuedOperation operation) async {
    final db = await database;
    await db.update(
      'queue_operations',
      operation.toMap(),
      where: 'id = ?',
      whereArgs: [operation.id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
