import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  final String id;
  final String title;
  final String description;
  final int amountPaise;
  final String paidBy;
  final String paidByName;
  final List<String> participantIds;
  final Map<String, int> splitAmounts;
  final String splitType;
  final DateTime purchasedAt;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PurchaseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amountPaise,
    required this.paidBy,
    required this.paidByName,
    required this.participantIds,
    required this.splitAmounts,
    required this.splitType,
    required this.purchasedAt,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  double get amountInRupees => amountPaise / 100;

  factory PurchaseModel.fromJson(String id, Map<String, dynamic> json) {
    final rawSplits = Map<String, dynamic>.from(json['splitAmounts'] ?? {});

    return PurchaseModel(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
      paidBy: json['paidBy'] ?? '',
      paidByName: json['paidByName'] ?? '',
      participantIds: List<String>.from(json['participantIds'] ?? []),
      splitAmounts: rawSplits.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      splitType: json['splitType'] ?? 'equal',
      purchasedAt:
          (json['purchasedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'amountPaise': amountPaise,
      'paidBy': paidBy,
      'paidByName': paidByName,
      'participantIds': participantIds,
      'splitAmounts': splitAmounts,
      'splitType': splitType,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
