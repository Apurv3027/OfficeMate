class MemberBalanceModel {
  final String userId;
  final String fullName;
  final String email;

  final int totalPaidPaise;
  final int totalSharePaise;
  final int totalSentPaise;
  final int totalReceivedPaise;
  final int netBalancePaise;

  const MemberBalanceModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.totalPaidPaise,
    required this.totalSharePaise,
    required this.totalSentPaise,
    required this.totalReceivedPaise,
    required this.netBalancePaise,
  });

  double get totalPaid => totalPaidPaise / 100;
  double get totalShare => totalSharePaise / 100;
  double get totalSent => totalSentPaise / 100;
  double get totalReceived => totalReceivedPaise / 100;
  double get netBalance => netBalancePaise / 100;

  bool get shouldReceive => netBalancePaise > 0;
  bool get shouldPay => netBalancePaise < 0;
  bool get isSettled => netBalancePaise == 0;

  int get absoluteBalancePaise => netBalancePaise.abs();
}
