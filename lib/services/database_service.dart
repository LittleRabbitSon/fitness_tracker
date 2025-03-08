import '../models/workout_record.dart';
import '../models/exercise.dart';
import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 数据库服务类
/// 
/// 负责应用程序的数据库操作，包括创建数据库、表，以及对运动记录和运动项目的增删改查
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  /// 工厂构造函数，确保单例模式
  factory DatabaseService() {
    return _instance;
  }

  /// 内部构造函数
  DatabaseService._internal();

  /// 获取数据库实例，如果不存在则初始化
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    // 获取数据库路径
    String path = join(await getDatabasesPath(), 'fitness_tracker.db');
    
    // 打开数据库，如果不存在则创建
    return await openDatabase(
      path,
      version: 2, // 将版本号从1更新到2
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase, // 添加升级回调
    );
  }

  /// 创建数据库表
  Future<void> _createDatabase(Database db, int version) async {
    // 创建运动记录表
    await db.execute('''
      CREATE TABLE workout_records(
        id TEXT PRIMARY KEY,
        exerciseTypeId TEXT NOT NULL,
        date TEXT NOT NULL,
        duration INTEGER NOT NULL,
        notes TEXT
      )
    ''');
    
    // 创建运动项目表
    await db.execute('''
      CREATE TABLE exercises(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        icon TEXT NOT NULL
      )
    ''');
    
    // 插入默认运动项目数据
    await _insertDefaultExercises(db);
  }

  /// 升级数据库
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 检查表是否存在
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables.map((t) => t['name'] as String).toList();
      
      // 如果表存在但缺少列，添加列
      if (tableNames.contains('workout_records')) {
        try {
          // 检查列是否存在
          await db.rawQuery('SELECT exerciseTypeId FROM workout_records LIMIT 1');
        } catch (e) {
          // 列不存在，添加列
          developer.log('添加缺失的exerciseTypeId列', name: 'DatabaseService');
          
          // 创建临时表
          await db.execute('''
            CREATE TABLE workout_records_temp(
              id TEXT PRIMARY KEY,
              exerciseTypeId TEXT NOT NULL,
              date TEXT NOT NULL,
              duration INTEGER NOT NULL,
              notes TEXT
            )
          ''');
          
          // 复制数据（如果有的话）
          try {
            await db.execute('''
              INSERT INTO workout_records_temp(id, exerciseTypeId, date, duration, notes)
              SELECT id, '1', date, duration, notes FROM workout_records
            ''');
          } catch (e) {
            developer.log('复制数据失败: $e', name: 'DatabaseService');
          }
          
          // 删除旧表
          await db.execute('DROP TABLE workout_records');
          
          // 重命名临时表
          await db.execute('ALTER TABLE workout_records_temp RENAME TO workout_records');
        }
      } else {
        // 表不存在，创建新表
        await _createDatabase(db, newVersion);
      }
    }
  }

  /// 插入默认运动项目数据
  Future<void> _insertDefaultExercises(Database db) async {
    final defaultExercises = [
      Exercise(id: '1', name: '跑步', category: '有氧', icon: 'directions_run'),
      Exercise(id: '2', name: '骑行', category: '有氧', icon: 'directions_bike'),
      Exercise(id: '3', name: '游泳', category: '有氧', icon: 'pool'),
      Exercise(id: '4', name: '力量训练', category: '力量', icon: 'fitness_center'),
      Exercise(id: '5', name: '篮球', category: '球类', icon: 'sports_basketball'),
      Exercise(id: '6', name: '足球', category: '球类', icon: 'sports_soccer'),
      Exercise(id: '7', name: '网球', category: '球类', icon: 'sports_tennis'),
      Exercise(id: '8', name: '排球', category: '球类', icon: 'sports_volleyball'),
      Exercise(id: '9', name: '徒步', category: '户外', icon: 'hiking'),
    ];
    
    for (var exercise in defaultExercises) {
      await db.insert('exercises', exercise.toMap());
    }
  }

  /// 添加运动记录
  Future<void> addWorkoutRecord(WorkoutRecord record) async {
    try {
      final db = await database;
      await db.insert(
        'workout_records',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('添加运动记录失败: $e', name: 'DatabaseService');
      rethrow;
    }
  }

  /// 获取所有运动记录
  Future<List<WorkoutRecord>> getAllWorkoutRecords() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'workout_records',
        orderBy: 'date DESC', // 按日期降序排序
      );
      
      return List.generate(maps.length, (i) {
        return WorkoutRecord.fromMap(maps[i]);
      });
    } catch (e) {
      developer.log('获取所有运动记录失败: $e', name: 'DatabaseService');
      rethrow;
    }
  }

  /// 根据日期获取运动记录
  Future<List<WorkoutRecord>> getWorkoutRecordsByDate(DateTime date) async {
    try {
      final db = await database;
      
      // 计算当天的开始和结束时间
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final List<Map<String, dynamic>> maps = await db.query(
        'workout_records',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'date DESC', // 按日期降序排序
      );
      
      return List.generate(maps.length, (i) {
        return WorkoutRecord.fromMap(maps[i]);
      });
    } catch (e) {
      developer.log('根据日期获取运动记录失败: $e', name: 'DatabaseService');
      rethrow;
    }
  }

  /// 根据日期范围获取运动记录
  Future<List<WorkoutRecord>> getWorkoutRecordsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    
    // 将日期转换为ISO8601字符串格式
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    // 查询在日期范围内的记录
    final List<Map<String, dynamic>> maps = await db.query(
      'workout_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'date DESC',
    );
    
    // 将查询结果转换为WorkoutRecord对象列表
    return List.generate(maps.length, (i) {
      return WorkoutRecord.fromMap(maps[i]);
    });
  }

  /// 删除运动记录
  Future<void> deleteWorkoutRecord(String id) async {
    try {
      final db = await database;
      await db.delete(
        'workout_records',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('删除运动记录失败: $e', name: 'DatabaseService');
      rethrow;
    }
  }

  /// 获取所有运动项目
  Future<List<Exercise>> getAllExercises() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('exercises');
      
      return List.generate(maps.length, (i) {
        return Exercise.fromMap(maps[i]);
      });
    } catch (e) {
      developer.log('获取所有运动项目失败: $e', name: 'DatabaseService');
      rethrow;
    }
  }

  /// 根据ID获取运动项目
  Future<Exercise?> getExerciseById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'exercises',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return Exercise.fromMap(maps.first);
    } catch (e) {
      developer.log('根据ID获取运动项目失败: $e', name: 'DatabaseService');
      rethrow;
    }
  }
}