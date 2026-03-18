/// UI-only formatters for dates and numbers.
class Formatters {
  static String date(DateTime? d) {
    if (d == null) return '—';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String dateTime(DateTime? d) {
    if (d == null) return '—';
    final dateStr = date(d);
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$dateStr $h:$m';
  }

  static String time(DateTime? d) {
    if (d == null) return '—';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
