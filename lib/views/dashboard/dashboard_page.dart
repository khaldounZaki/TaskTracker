import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/task_service.dart';
import '../../data/models/task_model.dart';
import 'widgets/task_card.dart';
import '../../utils/theme.dart'; // ✅ import AppTheme

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currentUser?.uid ?? '';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                ListTile(
                  title: const Text(
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.buttonText,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person, color: Colors.white),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/profile'),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/admin-users'),
                      ),
                    ],
                  ),
                ),

                // ✅ Modern clean TabBar
                TabBar(
                  controller: _tabController,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(width: 3, color: Colors.white),
                    insets: EdgeInsets.symmetric(horizontal: 30),
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'My Tasks'),
                    Tab(text: 'Assigned to Me'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          MyTasksTab(uid: uid),
          AssignedTasksTab(uid: uid),
        ],
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
          onPressed: () => Navigator.pushNamed(context, '/add-task'),
          child: const Icon(Icons.add, color: AppTheme.buttonText),
        ),
      ),
    );
  }
}

/// My Tasks Tab
class MyTasksTab extends StatelessWidget {
  final String uid;
  const MyTasksTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context, listen: false);

    return StreamBuilder<List<TaskModel>>(
      stream: taskService.streamTasksCreatedBy(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          print(snap.error);
          return _errorState("Error: ${snap.error}");
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snap.data!;
        if (tasks.isEmpty) {
          return _emptyState("No tasks created yet", Icons.edit);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, i) => TaskCard(task: tasks[i]),
        );
      },
    );
  }
}

/// Assigned to Me Tab
class AssignedTasksTab extends StatelessWidget {
  final String uid;
  const AssignedTasksTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context, listen: false);

    return StreamBuilder<List<TaskModel>>(
      stream: taskService.streamTasksAssignedTo(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return _errorState("Error: ${snap.error}");
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snap.data!;
        if (tasks.isEmpty) {
          return _emptyState("No assignments yet", Icons.assignment_ind);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, i) => TaskCard(task: tasks[i]),
        );
      },
    );
  }
}

/// Empty State Widget
Widget _emptyState(String message, IconData icon) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 50, color: AppTheme.subtitle),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(color: AppTheme.subtitle, fontSize: 16),
        ),
      ],
    ),
  );
}

/// Error State Widget
Widget _errorState(String message) {
  return Center(
    child: Text(
      message,
      style: const TextStyle(
        color: AppTheme.title,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
