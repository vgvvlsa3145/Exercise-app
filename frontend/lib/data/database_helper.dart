import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'models/user_model.dart';
import 'models/workout_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hyperpulsex.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    print("Initializing Database at $filePath...");
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print("Database full path: $path");

    final db = await openDatabase(
      path, 
      version: 3, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    print("Database opened successfully.");
    return db;
  }
  
  // Handle migrations for users who have old DB versions
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _v2Upgrade(db);
    }
    if (oldVersion < 3) {
      print("Upgrading DB to version 3: Adding email column");
      try {
        await db.execute("ALTER TABLE users ADD COLUMN email TEXT DEFAULT 'old_user@example.com'");
      } catch (e) {
        print("Column email error: $e");
      }
    }
  }

  Future _v2Upgrade(Database db) async {
      print("Upgrading DB to version 2: Adding total_score column");
      try {
        await db.execute("ALTER TABLE users ADD COLUMN total_score INTEGER DEFAULT 0");
      } catch (e) {}
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Users Table
    await db.execute('''
CREATE TABLE users ( 
  id $idType, 
  username $textType,
  email $textType,
  password TEXT,
  age $integerType,
  gender $textType,
  height_cm $realType,
  weight_kg $realType,
  total_score INTEGER DEFAULT 0,
  target_weight_kg REAL,
  created_at $textType
)
''');

    // Questionnaire Responses (Full 35-Question Profile)
    await db.execute('''
CREATE TABLE fitness_profiles (
  id $idType,
  user_id $integerType,
  answers_json $textType,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
)
''');

    // Workout History
    await db.execute('''
CREATE TABLE workouts (
  id $idType,
  username $textType,
  exercise_name $textType,
  reps $integerType,
  accuracy $realType,
  duration_sec $integerType,
  calories_burned $realType,
  timestamp $textType
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // --- CRUD Operations ---

  // User
  Future<int> createUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toJson());
  }

  Future<User?> getUser(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> updateScore(int userId, int points) async {
    final db = await instance.database;
    final user = await getUserById(userId);
    if (user != null) {
      final newScore = user.totalScore + points;
      return await db.update('users', {'total_score': newScore}, where: 'id = ?', whereArgs: [userId]);
    }
    return 0;
  }

  // Questionnaires
  Future<void> saveFitnessProfile(int userId, Map<String, dynamic> answers) async {
    final db = await instance.database;
    final jsonStr = json.encode(answers);
    
    // Check if exists
    final existing = await db.query('fitness_profiles', where: 'user_id = ?', whereArgs: [userId]);
    if (existing.isNotEmpty) {
      await db.update('fitness_profiles', {'answers_json': jsonStr}, where: 'user_id = ?', whereArgs: [userId]);
    } else {
      await db.insert('fitness_profiles', {'user_id': userId, 'answers_json': jsonStr});
    }
  }

  Future<Map<String, dynamic>?> getFitnessProfile(int userId) async {
    final db = await instance.database;
    final maps = await db.query('fitness_profiles', where: 'user_id = ?', whereArgs: [userId]);
    if (maps.isNotEmpty) {
      return json.decode(maps.first['answers_json'] as String) as Map<String, dynamic>;
    }
    return null;
  }

  Future<int> saveWorkout(WorkoutRecord record) async {
    final db = await instance.database;
    return await db.insert('workouts', record.toJson());
  }

  Future<List<WorkoutRecord>> getWorkouts(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'workouts',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'timestamp DESC',
    );
    return result.map((json) => WorkoutRecord.fromJson(json)).toList();
  }
  // Get all usernames that have workout history
  Future<List<String>> getAllUsernames() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT DISTINCT username FROM workouts');
    return result.map((row) => row['username'] as String).toList();
  }
}
