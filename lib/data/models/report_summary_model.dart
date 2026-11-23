class ReportSummaryModel {
  final int totalExpensePaise;
  final int totalPurchases;
  final int totalConfirmedSettlementPaise;

  final Map<String, int> paidByMember;
  final Map<String, int> sharesByMember;
  final Map<String, String> memberNames;
  final Map<String, int> dailyExpenses;

  const ReportSummaryModel({
    required this.totalExpensePaise,
    required this.totalPurchases,
    required this.totalConfirmedSettlementPaise,
    required this.paidByMember,
    required this.sharesByMember,
    required this.memberNames,
    required this.dailyExpenses,
  });

  factory ReportSummaryModel.empty() {
    return const ReportSummaryModel(
      totalExpensePaise: 0,
      totalPurchases: 0,
      totalConfirmedSettlementPaise: 0,
      paidByMember: {},
      sharesByMember: {},
      memberNames: {},
      dailyExpenses: {},
    );
  }

  int get totalPaidByMembersPaise {
    return paidByMember.values.fold(0, (a, b) => a + b);
  }

  int get totalMemberSharesPaise {
    return sharesByMember.values.fold(0, (a, b) => a + b);
  }

  String get highestSpenderId {
    if (paidByMember.isEmpty) return '';

    return paidByMember.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  int get highestSpenderAmountPaise {
    if (paidByMember.isEmpty) return 0;
    return paidByMember[highestSpenderId] ?? 0;
  }
}
