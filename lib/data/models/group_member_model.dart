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
    this.isActive = true,
  });

  bool get isAdmin => role == 'admin';

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: (json['joinedAt'] as Timestamp?)?.toDate(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'role': role,
      'joinedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }
}
