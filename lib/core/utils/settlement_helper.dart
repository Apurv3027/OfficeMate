class SettlementHelper {
  static int remainingAmount({
    required int outstandingPaise,
    required int confirmedPaymentsPaise,
  }) {
    final remaining =
        outstandingPaise - confirmedPaymentsPaise;

    return remaining > 0 ? remaining : 0;
  }

  static bool isValidPayment({
    required int paymentPaise,
    required int outstandingPaise,
  }) {
    return paymentPaise > 0 &&
        paymentPaise <= outstandingPaise;
  }

  static String formatRupees(int amountPaise) {
    return '₹${(amountPaise / 100).toStringAsFixed(2)}';
  }
}
