import 'package:cloud_firestore/cloud_firestore.dart';
import 'subtask_model.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String status; // pending / in-progress / done
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final Timestamp? lastActivity; // ✅ new field

  final List<SubtaskModel> subtasks;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.lastActivity,
    this.subtasks = const [],
  });

  factory TaskModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      lastActivity:
          data['lastActivity'] ??
          data['updatedAt'] ??
          data['createdAt'], // ✅ fallback
      subtasks: const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'createdBy': createdBy,
    'status': status,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'lastActivity': lastActivity,
  };

  TaskModel copyWith({
    String? status,
    String? title,
    String? description,
    Timestamp? updatedAt,
    Timestamp? lastActivity,
    List<SubtaskModel>? subtasks,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivity: lastActivity ?? this.lastActivity,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
