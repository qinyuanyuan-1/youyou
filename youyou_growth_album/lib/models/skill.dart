/// 一条"新学会的技能"
/// 例如"自己穿鞋""会说10个词语"。同样记住学会那天宝宝的天数。
class Skill {
  final String id;
  final String name; // 技能名称
  final String? note; // 备注
  final DateTime learnedAt; // 学会日期
  final String dateLabel; // 日期+星期
  final int dayLabel; // 学会那天宝宝第几天

  const Skill({
    required this.id,
    required this.name,
    this.note,
    required this.learnedAt,
    required this.dateLabel,
    required this.dayLabel,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'note': note,
        'learnedAt': learnedAt.toIso8601String(),
        'dateLabel': dateLabel,
        'dayLabel': dayLabel,
      };

  factory Skill.fromMap(Map<String, dynamic> map) => Skill(
        id: map['id'] as String,
        name: map['name'] as String,
        note: map['note'] as String?,
        learnedAt: DateTime.parse(map['learnedAt'] as String),
        dateLabel: map['dateLabel'] as String,
        dayLabel: map['dayLabel'] as int,
      );
}
