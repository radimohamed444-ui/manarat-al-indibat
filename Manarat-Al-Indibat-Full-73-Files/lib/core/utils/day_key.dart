/// Faithful port of dk(): formats a date as yyyy-MM-dd, used as the key
/// for day logs everywhere (S.log[dayKey] in the original).
String dayKey([DateTime? d]) {
  final date = d ?? DateTime.now();
  final y = date.year.toString().padLeft(4, "0");
  final m = date.month.toString().padLeft(2, "0");
  final day = date.day.toString().padLeft(2, "0");
  return "$y-$m-$day";
}

/// Faithful port of daysBetween().
int daysBetween(DateTime a, DateTime b) {
  return (b.difference(a).inMilliseconds / 86400000).round();
}

/// Arabic weekday names, index 0=Sunday matching JS Date.getDay() and
/// the original DAY_AR array.
const List<String> dayNamesAr = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"];

/// Formats an hour (0-23) as "hh:00 ص/م" — faithful port of fmtH().
String formatHour(int h) {
  final ap = h < 12 ? "ص" : "م";
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return "${h12.toString().padLeft(2, "0")}:00 $ap";
}

/// Dart's DateTime.weekday is 1=Monday..7=Sunday. JS Date.getDay() is
/// 0=Sunday..6=Saturday. This converts Dart weekday -> JS-style index,
/// used everywhere we mirror `d.getDay()` from the original.
int jsWeekday(DateTime d) => d.weekday % 7;
