import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/baby.dart';
import '../models/growth_record.dart';
import '../models/photo_entry.dart';
import '../models/skill.dart';

/// 本地数据库服务：所有数据都存在手机本地，不联网，保护隐私。
/// 用单例保证整个 App 只打开一个数据库连接。
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'youyou_growth.db'),
      version: 1,
      onCreate: (db, version) async {
        // 宝宝档案表（只存一行）
        await db.execute('''
          CREATE TABLE baby (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            birthDate TEXT NOT NULL
          )
        ''');
        // 照片表
        await db.execute('''
          CREATE TABLE photos (
            id TEXT PRIMARY KEY,
            localPath TEXT NOT NULL,
            takenAt TEXT NOT NULL,
            babyMonth INTEGER NOT NULL,
            caption TEXT,
            isSample INTEGER NOT NULL DEFAULT 0
          )
        ''');
        // 成长记录表
        await db.execute('''
          CREATE TABLE growth_records (
            id TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            photoPath TEXT,
            dateLabel TEXT NOT NULL,
            dayLabel INTEGER NOT NULL
          )
        ''');
        // 技能表
        await db.execute('''
          CREATE TABLE skills (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            note TEXT,
            learnedAt TEXT NOT NULL,
            dateLabel TEXT NOT NULL,
            dayLabel INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ---------- 宝宝档案 ----------

  Future<Baby?> getBaby() async {
    final db = await database;
    final rows = await db.query('baby', limit: 1);
    if (rows.isEmpty) return null;
    return Baby(
      name: rows.first['name'] as String,
      birthDate: DateTime.parse(rows.first['birthDate'] as String),
    );
  }

  Future<void> saveBaby(Baby baby) async {
    final db = await database;
    await db.insert(
      'baby',
      {'id': 1, 'name': baby.name, 'birthDate': baby.birthDate.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- 照片 ----------

  Future<void> insertPhoto(PhotoEntry photo) async {
    final db = await database;
    await db.insert('photos', photo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PhotoEntry>> getPhotos() async {
    final db = await database;
    final rows = await db.query('photos', orderBy: 'takenAt DESC');
    return rows.map(PhotoEntry.fromMap).toList();
  }

  Future<void> updatePhoto(PhotoEntry photo) async {
    final db = await database;
    await db.update('photos', photo.toMap(), where: 'id = ?', whereArgs: [photo.id]);
  }

  Future<void> deletePhoto(String id) async {
    final db = await database;
    await db.delete('photos', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- 成长记录 ----------

  Future<void> insertRecord(GrowthRecord record) async {
    final db = await database;
    await db.insert('growth_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<GrowthRecord>> getRecords() async {
    final db = await database;
    final rows = await db.query('growth_records', orderBy: 'createdAt DESC');
    return rows.map(GrowthRecord.fromMap).toList();
  }

  Future<void> deleteRecord(String id) async {
    final db = await database;
    await db.delete('growth_records', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- 技能 ----------

  Future<void> insertSkill(Skill skill) async {
    final db = await database;
    await db.insert('skills', skill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Skill>> getSkills() async {
    final db = await database;
    final rows = await db.query('skills', orderBy: 'learnedAt DESC');
    return rows.map(Skill.fromMap).toList();
  }

  Future<void> deleteSkill(String id) async {
    final db = await database;
    await db.delete('skills', where: 'id = ?', whereArgs: [id]);
  }
}
