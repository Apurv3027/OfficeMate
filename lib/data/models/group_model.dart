import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String inviteCode;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory GroupModel.fromJson(String id, Map<String, dynamic> json) {
    return GroupModel(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };
  }
}
