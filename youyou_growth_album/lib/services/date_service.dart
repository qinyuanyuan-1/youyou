import 'package:intl/intl.dart';

/// 日期相关的工具：把日期格式化成"2026年11月23日 星期一"这种中文样子。
class DateService {
  static const _weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

  /// 例如：2026年11月23日 星期一
  static String dateLabel(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    // DateTime.weekday: 1=周一 ... 7=周日
    final week = _weekdays[date.weekday - 1];
    return '${y}年${m}月${d}日 $week';
  }

  /// 例如：2026-11-23
  static String shortDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 例如：第27个月（内部月龄 26 + 1）
  static String monthLabel(int monthIndexZeroBased) {
    return '第${monthIndexZeroBased + 1}个月';
  }
}
