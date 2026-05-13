import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat.currency(
    locale: 'fr_DZ',
    symbol: 'DZD',
    decimalDigits: 2,
  );

  static final _compactFormatter = NumberFormat.compact(locale: 'fr');

  static String format(num? amount) {
    if (amount == null) return '0.00 DZD';
    return _formatter.format(amount);
  }

  static String formatCompact(num? amount) {
    if (amount == null) return '0';
    return '${_compactFormatter.format(amount)} DZD';
  }

  static String formatNumber(num? amount) {
    if (amount == null) return '0';
    return NumberFormat('#,##0.##', 'fr').format(amount);
  }
}
