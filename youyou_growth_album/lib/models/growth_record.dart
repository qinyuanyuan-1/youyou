/// 一条成长记录（成长日记）
/// 发布日期、星期、宝宝天数都不存死，发布时用发布时刻算好后存成文字，
/// 这样以后翻看还是当时那一刻的信息。
class GrowthRecord {
  final String id;
  final String content; // 正文
  final DateTime createdAt; // 发布时间
  final String? photoPath; // 附图（本地路径，可选）
  final String dateLabel; // 发布时算好的日期+星期，例如"2026年11月23日 星期一"
  final int dayLabel; // 发布时宝宝第几天

  const GrowthRecord({
    required this.id,
    required this.content,
    required this.createdAt,
    this.photoPath,
    required this.dateLabel,
    required this.dayLabel,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'photoPath': photoPath,
        'dateLabel': dateLabel,
        'dayLabel': dayLabel,
      };

  factory GrowthRecord.fromMap(Map<String, dynamic> map) => GrowthRecord(
        id: map['id'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        photoPath: map['photoPath'] as String?,
        dateLabel: map['dateLabel'] as String,
        dayLabel: map['dayLabel'] as int,
      );
}
