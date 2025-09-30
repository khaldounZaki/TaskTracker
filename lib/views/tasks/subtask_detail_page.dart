import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/task_model.dart';
import '../../../data/models/subtask_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../utils/theme.dart';
import '../../data/services/notification_service.dart';

class SubtaskDetailPage extends StatefulWidget {
  final String taskId;
  final SubtaskModel subtask;
  final VoidCallback? onComplete;

  const SubtaskDetailPage({
    super.key,
    required this.taskId,
    required this.subtask,
    required this.onComplete,
  });

  @override
  State<SubtaskDetailPage> createState() => _SubtaskDetailPageState();
}

class _SubtaskDetailPageState extends State<SubtaskDetailPage> {
  final TextEditingController _resultController = TextEditingController();

  Stream<AppUser?> _streamUser(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
  }

  Stream<TaskModel?> _streamTask(String taskId) {
    return FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .snapshots()
        .map((doc) => doc.exists ? TaskModel.fromDoc(doc) : null);
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return "N/A";
    if (ts is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate());
    }
    if (ts is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm').format(ts);
    }
    return "Invalid date";
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'pending':
        return AppTheme.button;
      case 'in-progress':
        return Colors.orange;
      default:
        return AppTheme.subtitle;
    }
  }

  Future<void> _markAsDone() async {
    try {
      final taskRef = FirebaseFirestore.instance
          .collection("tasks")
          .doc(widget.taskId);

      await taskRef.collection("subtasks").doc(widget.subtask.id).update({
        "status": "done",
        "result": _resultController.text.trim(),
        "completedAt": Timestamp.now(),
      });

      final subsSnap = await taskRef.collection("subtasks").get();
      final allDone = subsSnap.docs.every((doc) => doc["status"] == "done");

      await taskRef.update({
        "status": allDone ? "done" : "in-progress",
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });
      final auth = Provider.of<AuthService>(context, listen: false);
      final currentUid = auth.currentUser?.uid;

      await NotificationService().sendNotification(
        toUser: widget.subtask.fromUser,
        title: "Subtask Completed",
        body: "User ${widget.subtask.toUser} finished a subtask.",
        taskId: widget.taskId,
        subtaskId: widget.subtask.id,
        fromUser: currentUid ?? '',
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error updating subtask: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update subtask")));
    }
  }

  @override
  void initState() {
    super.initState();
    _resultController.text = widget.subtask.result;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUid = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Subtask Details"),
        backgroundColor: AppTheme.button,
        foregroundColor: AppTheme.buttonText,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MAIN TASK INFO ---
            _buildSectionTitle("Main Task"),
            StreamBuilder<TaskModel?>(
              stream: _streamTask(widget.taskId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final task = snapshot.data!;
                return _buildInfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.title,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.subtitle,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // --- SUBTASK INFO ---
            _buildSectionTitle("Subtask"),
            _buildInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    widget.subtask.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.subtitle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    backgroundColor: _statusColor(widget.subtask.status),
                    label: Text(
                      widget.subtask.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- ASSIGNMENT INFO ---
            _buildSectionTitle("Assignment"),
            _buildInfoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<AppUser?>(
                    stream: _streamUser(widget.subtask.fromUser),
                    builder: (context, snapshot) {
                      final fromName = snapshot.hasData
                          ? snapshot.data!.name
                          : "Unknown";
                      return Text("From: $fromName");
                    },
                  ),
                  StreamBuilder<AppUser?>(
                    stream: _streamUser(widget.subtask.toUser),
                    builder: (context, snapshot) {
                      final toName = snapshot.hasData
                          ? snapshot.data!.name
                          : "Unknown";
                      return Text("To: $toName");
                    },
                  ),
                ],
              ),
            ),

            // --- TIMELINE ---
            _buildSectionTitle("Timeline"),
            _buildInfoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Created: ${_formatDate(widget.subtask.createdAt)}"),
                  Text(
                    widget.subtask.completedAt != null
                        ? "Completed: ${_formatDate(widget.subtask.completedAt)}"
                        : "Not completed",
                  ),
                ],
              ),
            ),

            // --- RESULT ---
            _buildSectionTitle("Result"),
            _buildInfoCard(
              child:
                  widget.subtask.status == 'pending' &&
                      widget.subtask.toUser == currentUid
                  ? TextField(
                      controller: _resultController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Enter result here...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    )
                  : Text(
                      widget.subtask.result.isEmpty
                          ? "No result yet."
                          : widget.subtask.result,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.subtitle,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // --- ACTION BUTTON ---
            if (widget.subtask.status == 'pending' &&
                widget.subtask.toUser == currentUid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.button,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _markAsDone,
                  child: const Text(
                    "Mark as Done",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppTheme.title,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
