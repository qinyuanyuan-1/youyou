import 'package:flutter/foundation.dart';

import '../models/baby.dart';
import '../models/growth_record.dart';
import '../models/photo_entry.dart';
import '../models/skill.dart';
import '../services/database_service.dart';
import '../services/date_service.dart';
import '../services/face_recognition_service.dart';

/// 全局状态：所有页面共享同一份数据，改动后 notifyListeners 让界面刷新。
class AppProvider with ChangeNotifier {
  final _db = DatabaseService.instance;
  final faceService = FaceRecognitionService();

  Baby? baby;
  List<PhotoEntry> photos = [];
  List<GrowthRecord> records = [];
  List<Skill> skills = [];
  bool loaded = false;

  /// App 启动时加载全部数据
  Future<void> load() async {
    baby = await _db.getBaby();
    photos = await _db.getPhotos();
    records = await _db.getRecords();
    skills = await _db.getSkills();
    await faceService.load();
    loaded = true;
    notifyListeners();
  }

  // ---------- 宝宝档案 ----------
  Future<void> saveBaby(String name, DateTime birthDate) async {
    final b = Baby(name: name, birthDate: birthDate);
    await _db.saveBaby(b);
    baby = b;
    notifyListeners();
  }

  // ---------- 照片 ----------
  Future<void> addPhoto(PhotoEntry photo) async {
    await _db.insertPhoto(photo);
    photos = await _db.getPhotos();
    notifyListeners();
  }

  Future<void> markSample(PhotoEntry photo, bool value) async {
    final updated = photo.copyWith(isSample: value);
    await _db.updatePhoto(updated);
    photos = await _db.getPhotos();
    notifyListeners();
  }

  Future<void> removePhoto(String id) async {
    await _db.deletePhoto(id);
    photos = await _db.getPhotos();
    notifyListeners();
  }

  /// 按"第几个月"分组，key 是月龄（0 起），value 是照片列表
  Map<int, List<PhotoEntry>> photosGroupedByMonth() {
    final map = <int, List<PhotoEntry>>{};
    for (final p in photos) {
      map.putIfAbsent(p.babyMonth, () => []).add(p);
    }
    return map;
  }

  // ---------- 成长记录 ----------
  Future<void> addRecord(String content, {String? photoPath}) async {
    if (baby == null) return;
    final now = DateTime.now();
    final record = GrowthRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      createdAt: now,
      photoPath: photoPath,
      dateLabel: DateService.dateLabel(now),
      dayLabel: baby!.dayAt(now),
    );
    await _db.insertRecord(record);
    records = await _db.getRecords();
    notifyListeners();
  }

  Future<void> removeRecord(String id) async {
    await _db.deleteRecord(id);
    records = await _db.getRecords();
    notifyListeners();
  }

  // ---------- 技能 ----------
  Future<void> addSkill(String name, {String? note, DateTime? learnedAt}) async {
    if (baby == null) return;
    final date = learnedAt ?? DateTime.now();
    final skill = Skill(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      note: note,
      learnedAt: date,
      dateLabel: DateService.dateLabel(date),
      dayLabel: baby!.dayAt(date),
    );
    await _db.insertSkill(skill);
    skills = await _db.getSkills();
    notifyListeners();
  }

  Future<void> removeSkill(String id) async {
    await _db.deleteSkill(id);
    skills = await _db.getSkills();
    notifyListeners();
  }
}
