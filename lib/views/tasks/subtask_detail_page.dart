import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/subtask_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../utils/theme.dart';

class SubtaskDetailPage extends StatefulWidget {
  final String taskId; // ✅ parent task ID
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
      default:
        return AppTheme.subtitle;
    }
  }

  Future<void> _markAsDone() async {
    try {
      final taskRef = FirebaseFirestore.instance
          .collection("tasks")
          .doc(widget.taskId);

      // ✅ Update subtask
      await taskRef.collection("subtasks").doc(widget.subtask.id).update({
        "status": "done",
        "result": _resultController.text.trim(),
        "completedAt": Timestamp.now(),
      });

      // ✅ Check if all subtasks are done
      final subsSnap = await taskRef.collection("subtasks").get();
      final allDone = subsSnap.docs.every((doc) => doc["status"] == "done");

      if (allDone) {
        await taskRef.update({
          "status": "done",
          'updatedAt': FieldValue.serverTimestamp(),
          'lastActivity': FieldValue.serverTimestamp(),
        });
      } else {
        await taskRef.update({
          "status": "in-progress",
          'updatedAt': FieldValue.serverTimestamp(),
          'lastActivity': FieldValue.serverTimestamp(),
        }); // optional: keep synced
      }

      // ✅ Call UI callback if passed
      //widget.onComplete?.call();

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
            // --- Description ---
            Text(
              widget.subtask.description,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.title,
              ),
            ),
            const SizedBox(height: 12),

            // --- Status Chip ---
            Chip(
              backgroundColor: _statusColor(widget.subtask.status),
              label: Text(
                widget.subtask.status.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.buttonText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 30),

            // --- From → To ---
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<AppUser?>(
                    stream: _streamUser(widget.subtask.fromUser),
                    builder: (context, snapshot) {
                      String fromName = snapshot.hasData
                          ? snapshot.data!.name
                          : "Unknown";
                      return Text(
                        "From: $fromName",
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                ),
                const Icon(Icons.arrow_right_alt, color: AppTheme.subtitle),
                Expanded(
                  child: StreamBuilder<AppUser?>(
                    stream: _streamUser(widget.subtask.toUser),
                    builder: (context, snapshot) {
                      String toName = snapshot.hasData
                          ? snapshot.data!.name
                          : "Unknown";
                      return Text(
                        "To: $toName",
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Dates ---
            Text(
              "Created: ${_formatDate(widget.subtask.createdAt)}",
              style: const TextStyle(color: AppTheme.subtitle),
            ),
            const SizedBox(height: 6),
            Text(
              "Completed: ${widget.subtask.completedAt != null ? _formatDate(widget.subtask.completedAt) : "Not yet"}",
              style: const TextStyle(color: AppTheme.subtitle),
            ),
            const Divider(height: 30),

            // --- Result ---
            Text(
              "Result",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            if (widget.subtask.status == 'pending' &&
                widget.subtask.toUser == currentUid)
              TextField(
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
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  widget.subtask.result.isEmpty
                      ? "No result yet."
                      : widget.subtask.result,
                  style: const TextStyle(fontSize: 15),
                ),
              ),

            const SizedBox(height: 30),

            // --- Action Button ---
            if (widget.subtask.status == 'pending' &&
                widget.subtask.toUser == currentUid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.button,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _markAsDone,
                  child: const Text(
                    "Mark as Done",
                    style: TextStyle(
                      color: AppTheme.buttonText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
