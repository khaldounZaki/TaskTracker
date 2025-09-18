import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/task_service.dart';
import '../../data/services/auth_service.dart';
import '../../utils/helpers.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      setState(() => _loading = true);
                      final uid = auth.currentUser!.uid;
                      try {
                        final taskId = await taskService.createTask(
                          title: _titleCtrl.text.trim(),
                          description: _descCtrl.text.trim(),
                          createdBy: uid,
                        );
                        showSuccess(context, 'Task created');
                        Navigator.pop(context);
                      } catch (e) {
                        showError(context, 'Failed: $e');
                      }
                      setState(() => _loading = false);
                    },
                    child: const Text('Create Task'),
                  ),
          ],
        ),
      ),
    );
  }
}
