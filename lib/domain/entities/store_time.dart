/// Movile uses America/Lima for the optical store (UTC-5, without DST).
abstract final class StoreTime {
  static DateTime clock(DateTime instant) => instant.toUtc().subtract(const Duration(hours: 5));
  static DateTime day(DateTime instant) {
    final value = clock(instant);
    return DateTime(value.year, value.month, value.day);
  }
  static DateTime today() => day(DateTime.now());
  static String isoDay(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime? parseBirthDate(String value, {DateTime? today}) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day || !date.isBefore(today ?? StoreTime.today())) return null;
    return date;
  }
}
