import 'package:intl/intl.dart';

String formatMoney(double amount, {String localeCode = 'en', String symbol = ''}) {
  final f = NumberFormat.currency(
    locale: localeCode,
    symbol: symbol,
    decimalDigits: amount % 1 == 0 ? 0 : 2,
  );
  return f.format(amount).trim();
}
