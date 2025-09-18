import 'package:cloud_firestore/cloud_firestore.dart';

class SubtaskModel {
  final String id;
  final String fromUser;
  final String toUser;
  final String description;
  final String result;
  final String status; // pending / done
  final Timestamp createdAt;
  final Timestamp? completedAt;
  // taskId is not stored inside the subtask doc; it's the parent document id.

  SubtaskModel({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.description,
    required this.result,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory SubtaskModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SubtaskModel(
      id: doc.id,
      fromUser: data['fromUser'] ?? '',
      toUser: data['toUser'] ?? '',
      description: data['description'] ?? '',
      result: data['result'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      completedAt: data['completedAt'],
    );
  }

  Map<String, dynamic> toMap() => {
    'fromUser': fromUser,
    'toUser': toUser,
    'description': description,
    'result': result,
    'status': status,
    'createdAt': createdAt,
    'completedAt': completedAt,
  };

  SubtaskModel copyWith({
    String? result,
    String? status,
    Timestamp? completedAt,
  }) {
    return SubtaskModel(
      id: id,
      fromUser: fromUser,
      toUser: toUser,
      description: description,
      result: result ?? this.result,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
