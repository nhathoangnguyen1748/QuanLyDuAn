import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM');
  static final DateFormat _monthYearFormat = DateFormat('MM/yyyy');

  static String formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '--/--/---- --:--';
    return _dateTimeFormat.format(date);
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return '--/--';
    return _shortDateFormat.format(date);
  }

  static String formatMonthYear(DateTime? date) {
    if (date == null) return '--/----';
    return _monthYearFormat.format(date);
  }

  /// Trả về số ngày còn lại đến hạn sử dụng (dương: còn hạn, âm: quá hạn)
  static int daysUntilExpiry(DateTime? expiryDate) {
    if (expiryDate == null) return 999999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }
}
