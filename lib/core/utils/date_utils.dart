DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

DateTime startOfWeek(DateTime t) =>
    dateOnly(t).subtract(Duration(days: t.weekday - 1));

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime t) => '${two(t.day)}/${two(t.month)}/${t.year}';

String formatDayMonth(DateTime t) => '${two(t.day)}/${two(t.month)}';

String formatHourMinute(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
const _weekdayNames = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật'
];

String weekdayShort(DateTime t) => _weekdays[t.weekday - 1];

String weekdayName(DateTime t) => _weekdayNames[t.weekday - 1];
