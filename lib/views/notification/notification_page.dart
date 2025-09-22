import 'package:flutter/material.dart';
import '../../data/services/notification_service.dart';
import '../../utils/theme.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../tasks/subtask_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/subtask_model.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: AppTheme.button,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService().streamNotifications(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifs = snapshot.data!;
          if (notifs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (context, i) {
              final n = notifs[i];
              return ListTile(
                title: Text(n['title']),
                subtitle: Text(n['body']),
                trailing: n['isRead'] == false
                    ? const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.red,
                        size: 12,
                      )
                    : null,
                onTap: () async {
                  NotificationService().markAsRead(uid, n['id']); // mark read

                  final taskRef = FirebaseFirestore.instance
                      .collection('tasks')
                      .doc(n['taskId'])
                      .collection('subtasks')
                      .doc(n['subtaskId']);

                  final subtaskDoc = await taskRef.get();
                  if (!subtaskDoc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Subtask not found")),
                    );
                    return;
                  }

                  final subtask = SubtaskModel.fromDoc(subtaskDoc);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubtaskDetailPage(
                        taskId: n['taskId'],
                        subtask: subtask, // ✅ now passing a real SubtaskModel
                        onComplete: () {},
                      ),
                    ),
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
