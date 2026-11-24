class ExpenseSplitHelper {
  /// Calculates equal shares in integer paise.
  ///
  /// Any remaining paise are distributed one by one
  /// in the order of participantIds.
  static Map<String, int> calculateEqualSplit({
    required int amountPaise,
    required List<String> participantIds,
  }) {
    if (amountPaise <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    if (participantIds.isEmpty) {
      throw ArgumentError('Select at least one participant.');
    }

    if (participantIds.toSet().length != participantIds.length) {
      throw ArgumentError('Duplicate participants are not allowed.');
    }

    if (amountPaise < participantIds.length) {
      throw ArgumentError(
        'Amount must be at least 1 paise per participant.',
      );
    }

    final baseAmount = amountPaise ~/ participantIds.length;
    final remainder = amountPaise % participantIds.length;

    final result = <String, int>{};

    for (int i = 0; i < participantIds.length; i++) {
      result[participantIds[i]] =
          baseAmount + (i < remainder ? 1 : 0);
    }

    return result;
  }

  /// Validates custom participant shares.
  static bool validateCustomSplit({
    required int amountPaise,
    required Map<String, int> splitAmounts,
    required List<String> participantIds,
  }) {
    if (amountPaise <= 0 || participantIds.isEmpty) {
      return false;
    }

    if (participantIds.toSet().length != participantIds.length) {
      return false;
    }

    if (splitAmounts.length != participantIds.length) {
      return false;
    }

    if (!splitAmounts.keys.toSet().containsAll(participantIds)) {
      return false;
    }

    if (splitAmounts.values.any((amount) => amount < 0)) {
      return false;
    }

    final total = splitAmounts.values.fold<int>(
      0,
      (sum, amount) => sum + amount,
    );

    return total == amountPaise;
  }

  /// Converts rupees input into integer paise.
  static int rupeesToPaise(String value) {
    final rupees = double.tryParse(value);

    if (rupees == null || !rupees.isFinite || rupees <= 0) {
      throw ArgumentError('Enter a valid purchase amount.');
    }

    final paise = rupees * 100;

    if (paise != paise.roundToDouble() &&
        (paise - paise.roundToDouble()).abs() > 0.000001) {
      throw ArgumentError(
        'Maximum two decimal places are allowed.',
      );
    }

    return paise.round();
  }

  /// Converts integer paise into display format.
  static String formatPaise(int amountPaise) {
    final rupees = amountPaise ~/ 100;
    final paise = (amountPaise % 100).abs();

    return '₹$rupees.${paise.toString().padLeft(2, '0')}';
  }
}
