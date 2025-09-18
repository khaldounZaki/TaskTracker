import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // ✅ for date formatting

import '../../../data/models/task_model.dart';
import '../../../data/models/subtask_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../utils/theme.dart'; // ✅ Use AppTheme

class TaskCard extends StatelessWidget {
  final TaskModel task;
  const TaskCard({super.key, required this.task});

  Stream<List<SubtaskModel>> _streamSubtasks(String taskId) {
    return FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => SubtaskModel.fromDoc(doc)).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser!.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.pushNamed(
          context,
          '/task-detail',
          arguments: {'taskId': task.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Title + Status in one row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.title,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _statusChip(task.status),
                ],
              ),

              const SizedBox(height: 4),

              /// 🔹 Description (inline, small font)
              Text(
                task.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppTheme.subtitle),
              ),

              const SizedBox(height: 6),

              /// 🔹 Stats + Last activity all in one row
              StreamBuilder<List<SubtaskModel>>(
                stream: _streamSubtasks(task.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final allSubs = snapshot.data!;
                  final subs = task.createdBy == uid
                      ? allSubs
                      : allSubs
                            .where((s) => s.fromUser == uid || s.toUser == uid)
                            .toList();

                  final pendingToMe = subs
                      .where((s) => s.status == 'pending' && s.toUser == uid)
                      .length;
                  final pendingToOthers = subs
                      .where((s) => s.status == 'pending' && s.fromUser == uid)
                      .length;
                  final completed = subs
                      .where((s) => s.status == 'done')
                      .length;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statIcon(
                          Icons.list_alt,
                          "${subs.length}",
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _statIconImportant(
                          Icons.hourglass_top,
                          "Me:$pendingToMe",
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _statIcon(
                          Icons.outgoing_mail,
                          "Oth:$pendingToOthers",
                          Colors.deepOrange,
                        ),
                        const SizedBox(width: 8),
                        _statIcon(
                          Icons.check_circle,
                          "$completed",
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppTheme.subtitle,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              task.lastActivity != null
                                  ? DateFormat('dd/MM HH:mm').format(
                                      (task.lastActivity as Timestamp).toDate(),
                                    )
                                  : "—",
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Status chip with better colors
  Widget _statusChip(String status) {
    Color bg;
    IconData icon;

    switch (status) {
      case 'done':
        bg = Colors.green;
        icon = Icons.check;
        break;
      case 'pending':
        bg = Colors.orange;
        icon = Icons.hourglass_bottom;
        break;
      default:
        bg = Colors.grey;
        icon = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  /// 🔹 Subtask stats helper
  Widget _statIcon(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppTheme.subtitle),
        ),
      ],
    );
  }

  Widget _statIconImportant(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFECD3F1), // soft purple background
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.subtitle,
            ),
          ),
        ),
      ],
    );
  }
}
