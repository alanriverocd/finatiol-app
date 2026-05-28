import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static final _currency = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  static String currency(double amount) => _currency.format(amount);

  static String date(DateTime date) =>
      DateFormat('dd/MM/yyyy', 'es').format(date);

  static String dateTime(DateTime date) =>
      DateFormat('dd/MM/yyyy HH:mm', 'es').format(date);
}
