/// 宝宝档案模型
/// 只存最核心的信息：名字和出生日期。年龄、天数、月龄都实时算出来，
/// 不用手动维护，避免数据不一致。
class Baby {
  final String name;
  final DateTime birthDate; // 出生年月日（本地时间，时分秒为 00:00）

  const Baby({required this.name, required this.birthDate});

  /// 今天已经出生多少天（出生当天算第 1 天）
  int get daysOld {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(birthDate).inDays + 1;
  }

  /// 完整月龄：出生满 N 个月。用于"第几个月"的照片归档。
  /// 出生当天到第 29 天算"第 1 个月"，满 1 个月进入"第 2 个月"。
  int get monthsOld {
    final now = DateTime.now();
    int months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (now.day < birthDate.day) months -= 1; // 还没到这个月的"生日"
    return months < 0 ? 0 : months;
  }

  /// 精确到"X岁X个月X天"的文字
  String get ageText {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;
    if (days < 0) {
      // 借上一个月天数
      final lastMonth = DateTime(now.year, now.month, 0).day;
      days += lastMonth;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }
    if (years < 0) {
      years = 0;
      months = 0;
      days = 0;
    }
    return '$years岁$months个月$days天';
  }

  /// 给定某一天，算那天宝宝处于第几个月（照片归档用）
  int monthAt(DateTime day) {
    int months = (day.year - birthDate.year) * 12 + day.month - birthDate.month;
    if (day.day < birthDate.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  /// 给定某一天，算那天是宝宝出生后的第几天
  int dayAt(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return d.difference(birthDate).inDays + 1;
  }
}
