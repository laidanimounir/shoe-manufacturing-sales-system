import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class AppDateUtils {
  AppDateUtils._();

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _monthYear = DateFormat('MMMM yyyy', 'fr');

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeFormat.format(date);
  }

  static String formatMonthYear(int month, int year) {
    return _monthYear.format(DateTime(year, month));
  }

  static String timeAgo(DateTime? date) {
    if (date == null) return '-';
    return timeago.format(date, locale: 'fr');
  }

  static String formatDateISO(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
