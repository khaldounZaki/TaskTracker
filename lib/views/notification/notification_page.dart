import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../data/services/notification_service.dart';
import '../../data/services/auth_service.dart';
import '../../utils/theme.dart';
import '../../../data/models/subtask_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/user_model.dart';
import '../tasks/subtask_detail_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Stream<AppUser?> _streamUser(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
  }

  Future<TaskModel?> _fetchTask(String taskId) async {
    final doc = await FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .get();
    if (!doc.exists) return null;
    return TaskModel.fromDoc(doc);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: AppTheme.button,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "Mark all as read",
            onPressed: () {
              //NotificationService().markAllAsRead(uid);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService().streamNotifications(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifs = snapshot.data!;
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No notifications yet",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifs.length,
            itemBuilder: (context, i) {
              final n = notifs[i];
              final isUnread = n['isRead'] == false;

              return FutureBuilder<TaskModel?>(
                future: _fetchTask(n['taskId']),
                builder: (context, taskSnap) {
                  final task = taskSnap.data;
                  print(task);

                  return StreamBuilder<AppUser?>(
                    stream: _streamUser(n['fromUser']),
                    builder: (context, userSnap) {
                      final user = userSnap.data;
                      print(user);

                      return GestureDetector(
                        onTap: () async {
                          NotificationService().markAsRead(uid, n['id']);

                          final taskRef = FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(n['taskId'])
                              .collection('subtasks')
                              .doc(n['subtaskId']);

                          final subtaskDoc = await taskRef.get();
                          if (!subtaskDoc.exists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Subtask not found"),
                              ),
                            );
                            return;
                          }

                          final subtask = SubtaskModel.fromDoc(subtaskDoc);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubtaskDetailPage(
                                taskId: n['taskId'],
                                subtask: subtask,
                                onComplete: () {},
                              ),
                            ),
                          );
                        },
                        child: Card(
                          color: isUnread ? Colors.blue.shade50 : Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- Avatar ---
                                CircleAvatar(
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: user?.picture != null
                                      ? NetworkImage(user!.picture)
                                      : null,
                                  child: user?.picture == null
                                      ? Text(
                                          (user?.name.isNotEmpty == true
                                                  ? user!.name[0]
                                                  : "?")
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),

                                // --- Notification Body ---
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Actor + Action
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: user?.name ?? "Someone",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.title,
                                              ),
                                            ),
                                            const TextSpan(text: " • "),
                                            TextSpan(
                                              text:
                                                  n['title'] ?? "Notification",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.subtitle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Message body
                                      Text(
                                        n['body'] ?? "",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      // Main task info (if available)
                                      if (task != null)
                                        Text(
                                          "Main Task: ${task.title}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: AppTheme.subtitle,
                                          ),
                                        ),

                                      const SizedBox(height: 6),

                                      // Time
                                      Text(
                                        n['createdAt'] != null
                                            ? timeago.format(
                                                (n['createdAt'] as Timestamp)
                                                    .toDate(),
                                                locale: 'en_short',
                                              )
                                            : "",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (isUnread)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8, top: 4),
                                    child: Icon(
                                      Icons.fiber_manual_record,
                                      color: Colors.red,
                                      size: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
