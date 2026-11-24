import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  purchase,
  settlement,
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final String title;
  final String description;
  final int amountPaise;
  final String status;
  final String primaryUserId;
  final String primaryUserName;
  final DateTime date;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.amountPaise,
    required this.status,
    required this.primaryUserId,
    required this.primaryUserName,
    required this.date,
  });

  double get amountInRupees => amountPaise / 100;

  bool get isPurchase => type == TransactionType.purchase;

  bool get isSettlement => type == TransactionType.settlement;

  factory TransactionModel.fromPurchase(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = data['purchasedAt'];

    return TransactionModel(
      id: id,
      type: TransactionType.purchase,
      title: data['title'] ?? 'Purchase',
      description: data['categoryName'] ?? '',
      amountPaise: (data['amountPaise'] as num?)?.toInt() ?? 0,
      status: 'completed',
      primaryUserId: data['paidBy'] ?? '',
      primaryUserName: data['paidByName'] ?? '',
      date: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory TransactionModel.fromSettlement(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = data['createdAt'];

    return TransactionModel(
      id: id,
      type: TransactionType.settlement,
      title: 'Payment',
      description:
          '${data['fromUserName'] ?? ''} → ${data['toUserName'] ?? ''}',
      amountPaise: (data['amountPaise'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'pending',
      primaryUserId: data['fromUserId'] ?? '',
      primaryUserName: data['fromUserName'] ?? '',
      date: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
