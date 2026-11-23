import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMemberModel {
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final DateTime? joinedAt;
  final bool isActive;

  const GroupMemberModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.joinedAt,
    required this.isActive,
  });

  bool get isAdmin => role == 'admin';

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    final joinedAtValue = json['joinedAt'];

    return GroupMemberModel(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      joinedAt: joinedAtValue is Timestamp ? joinedAtValue.toDate() : null,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'role': role,
      'joinedAt': joinedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(joinedAt!),
      'isActive': isActive,
    };
  }
}
