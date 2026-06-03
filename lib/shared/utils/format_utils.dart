import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static final _currency = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static String currency(double amount) => _currency.format(amount);

  static String date(DateTime value) {
    return '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';
  }

  static String dateTime(DateTime value) {
    return '${date(value)} ${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
  }
}
