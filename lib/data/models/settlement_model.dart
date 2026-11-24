import 'package:cloud_firestore/cloud_firestore.dart';

class SettlementModel {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final int amountPaise;
  final String note;
  final String status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? confirmedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;

  const SettlementModel({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amountPaise,
    required this.note,
    required this.status,
    required this.createdBy,
    this.createdAt,
    this.confirmedAt,
    this.rejectedAt,
    this.cancelledAt,
  });

  double get amountInRupees => amountPaise / 100;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  factory SettlementModel.fromJson(
    String id,
    Map<String, dynamic> json,
  ) {
    DateTime? readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return SettlementModel(
      id: id,
      fromUserId: json['fromUserId'] ?? '',
      fromUserName: json['fromUserName'] ?? '',
      toUserId: json['toUserId'] ?? '',
      toUserName: json['toUserName'] ?? '',
      amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
      note: json['note'] ?? '',
      status: json['status'] ?? 'pending',
      createdBy: json['createdBy'] ?? '',
      createdAt: readDate(json['createdAt']),
      confirmedAt: readDate(json['confirmedAt']),
      rejectedAt: readDate(json['rejectedAt']),
      cancelledAt: readDate(json['cancelledAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'amountPaise': amountPaise,
      'note': note,
      'status': status,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'confirmedAt': null,
      'rejectedAt': null,
      'cancelledAt': null,
    };
  }
}
