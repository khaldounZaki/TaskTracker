import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/task_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/task_model.dart';
import '../../data/models/subtask_model.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../dashboard/widgets/subtask_card.dart';

class TaskDetailPage extends StatefulWidget {
  final String? taskId;
  const TaskDetailPage({super.key, this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  @override
  Widget build(BuildContext context) {
    final taskId = widget.taskId;
    if (taskId == null) {
      return const Scaffold(body: Center(child: Text('No task ID')));
    }

    final taskService = Provider.of<TaskService>(context);
    final userService = Provider.of<UserService>(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppTheme.buttonGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Back button
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back, color: AppTheme.buttonText),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Task Details',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.buttonText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<TaskModel?>(
        stream: taskService.streamTask(taskId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Task not found'));
          }

          final task = snapshot.data!;
          final auth = Provider.of<AuthService>(context, listen: false);
          final uid = auth.currentUser!.uid;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.title,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  task.description,
                  style: const TextStyle(color: AppTheme.subtitle),
                ),
                const SizedBox(height: 12),
                Text(
                  'Status: ${task.status}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.subtitle,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const Text(
                  'Subtasks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.title,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: StreamBuilder<List<SubtaskModel>>(
                    stream: taskService.streamSubtasks(taskId),
                    builder: (context, subSnap) {
                      if (subSnap.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${subSnap.error}',
                            style: const TextStyle(color: AppTheme.title),
                          ),
                        );
                      }
                      if (!subSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final subs = task.createdBy == uid
                          ? subSnap.data!
                          : subSnap.data!
                                .where(
                                  (s) => s.fromUser == uid || s.toUser == uid,
                                )
                                .toList();

                      if (subs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No subtasks yet',
                            style: TextStyle(color: AppTheme.subtitle),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: subs.length,
                        itemBuilder: (context, i) => SubtaskCard(
                          taskId: widget.taskId!,
                          subtask: subs[i],
                          onComplete: subs[i].status == 'pending'
                              ? () async {
                                  final result = await promptForText(
                                    context,
                                    'Result',
                                    'Enter the result for this subtask',
                                  );
                                  if (result == null) return;
                                  await taskService.completeSubtask(
                                    taskId: taskId,
                                    subtaskId: subs[i].id,
                                    result: result,
                                    fromUser: subs[i].fromUser,
                                    toUser: subs[i].toUser,
                                  );
                                  showSuccess(context, 'Subtask marked done');
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: AppTheme.buttonGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.button.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () async {
            final users = await userService.fetchOtherActiveUsers();

            final selected = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (c) {
                String? toUid;
                final descCtrl = TextEditingController();

                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text('Create subtask'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            value: toUid, // ✅ keeps current value
                            items: users
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u.uid,
                                    child: Text(
                                      u.name.isEmpty ? u.email : u.name,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => toUid = v), // ✅ update
                            decoration: const InputDecoration(
                              labelText: 'Assign to',
                            ),
                          ),
                          TextField(
                            controller: descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(c, {
                            'to': toUid,
                            'desc': descCtrl.text,
                          }),
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                );
              },
            );

            if (selected == null) return;
            final toUid = selected['to'] as String?;
            final desc = selected['desc'] as String?;
            if (toUid == null || desc == null || desc.trim().isEmpty) {
              return showError(context, 'Select user and enter description');
            }

            final auth = Provider.of<AuthService>(context, listen: false);
            final fromUid = auth.currentUser!.uid;
            await taskService.addSubtask(
              taskId: taskId,
              fromUser: fromUid,
              toUser: toUid,
              description: desc.trim(),
            );
            showSuccess(context, 'Subtask created');
          },
          child: const Icon(Icons.add_task, color: AppTheme.buttonText),
        ),
      ),
    );
  }
}
