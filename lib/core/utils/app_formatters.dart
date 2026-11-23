import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');

  static String currencyFromPaise(int amountPaise) {
    return _currencyFormatter.format(amountPaise / 100);
  }

  static String date(DateTime date) {
    return _dateFormatter.format(date);
  }
}
