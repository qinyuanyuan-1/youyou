/// 一张被收录进相册的照片
/// 注意：这里不直接保存系统相册里的原图路径（那个路径可能会变），
/// 而是把照片复制一份到 App 自己的私有目录，路径稳定、不怕原图被删。
class PhotoEntry {
  final String id; // 唯一 ID
  final String localPath; // 复制到 App 私有目录后的文件路径
  final DateTime takenAt; // 照片拍摄时间（决定它属于第几个月）
  final int babyMonth; // 拍摄时宝宝第几个月（0 起，展示时 +1）
  final String? caption; // 可选说明
  final bool isSample; // 是否被用户标记为"识别样本"（AI 认人用）

  const PhotoEntry({
    required this.id,
    required this.localPath,
    required this.takenAt,
    required this.babyMonth,
    this.caption,
    this.isSample = false,
  });

  PhotoEntry copyWith({
    String? id,
    String? localPath,
    DateTime? takenAt,
    int? babyMonth,
    String? caption,
    bool? isSample,
  }) {
    return PhotoEntry(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      takenAt: takenAt ?? this.takenAt,
      babyMonth: babyMonth ?? this.babyMonth,
      caption: caption ?? this.caption,
      isSample: isSample ?? this.isSample,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'localPath': localPath,
        'takenAt': takenAt.toIso8601String(),
        'babyMonth': babyMonth,
        'caption': caption,
        'isSample': isSample ? 1 : 0,
      };

  factory PhotoEntry.fromMap(Map<String, dynamic> map) => PhotoEntry(
        id: map['id'] as String,
        localPath: map['localPath'] as String,
        takenAt: DateTime.parse(map['takenAt'] as String),
        babyMonth: map['babyMonth'] as int,
        caption: map['caption'] as String?,
        isSample: (map['isSample'] as int? ?? 0) == 1,
      );
}
