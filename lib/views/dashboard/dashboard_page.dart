// lib/views/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/task_service.dart';
import '../../data/models/task_model.dart';
import 'widgets/task_card.dart';
import '../../utils/theme.dart'; // AppTheme

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  // filter state
  String _statusFilter = 'all'; // 'all', 'pending', 'in-progress', 'done'
  String _searchQuery = '';

  final List<String> _statuses = ['all', 'pending', 'in-progress', 'done'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Helper: convert Firestore values (Timestamp / DateTime / null) to DateTime?
  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  // Use task.lastActivity if available, otherwise fall back to createdAt.
  static DateTime? _taskKeyTime(TaskModel t) {
    final la = _toDateTime(
      (t as dynamic).lastActivity,
    ); // lastActivity may be Timestamp
    if (la != null) return la;
    return _toDateTime((t as dynamic).createdAt);
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
      // Body includes search + filters above the TabBarView so filters apply to both tabs
      body: Column(
        children: [
          // Search / Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search tasks (title or description)...',
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Status filter (compact popup)
                PopupMenuButton<String>(
                  tooltip: 'Filter by status',
                  initialValue: _statusFilter,
                  onSelected: (v) => setState(() => _statusFilter = v),
                  itemBuilder: (c) => [
                    const PopupMenuItem(value: 'all', child: Text('All')),
                    const PopupMenuItem(
                      value: 'pending',
                      child: Text('Pending'),
                    ),
                    const PopupMenuItem(
                      value: 'in-progress',
                      child: Text('In-Progress'),
                    ),
                    const PopupMenuItem(value: 'done', child: Text('Done')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _statusFilter == 'all'
                              ? 'All'
                              : (_statusFilter == 'in-progress'
                                    ? 'In-Progress'
                                    : _statusFilter.capitalize()),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Optional: quick chips (small) for status — shows which is active at a glance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statuses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final s = _statuses[i];
                  final label = s == 'all'
                      ? 'All'
                      : (s == 'in-progress' ? 'In-Progress' : s.capitalize());
                  final bool selected = _statusFilter == s;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _statusFilter = s),
                    selectedColor: AppTheme.button,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? AppTheme.buttonText : AppTheme.title,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MyTasksTab(
                  uid: uid,
                  searchQuery: _searchQuery,
                  statusFilter: _statusFilter,
                ),
                AssignedTasksTab(
                  uid: uid,
                  searchQuery: _searchQuery,
                  statusFilter: _statusFilter,
                ),
              ],
            ),
          ),
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

/// My Tasks Tab (now accepts search & filter)
class MyTasksTab extends StatelessWidget {
  final String uid;
  final String searchQuery;
  final String statusFilter;
  const MyTasksTab({
    super.key,
    required this.uid,
    required this.searchQuery,
    required this.statusFilter,
  });

  bool _matchesSearch(TaskModel t, String q) {
    if (q.isEmpty) return true;
    final low = q.toLowerCase();
    final title = (t.title).toLowerCase();
    final desc = (t.description).toLowerCase();
    return title.contains(low) || desc.contains(low) || t.id.contains(low);
  }

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context, listen: false);

    return StreamBuilder<List<TaskModel>>(
      stream: taskService.streamTasksCreatedBy(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return _errorState("Error: ${snap.error}");
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var tasks = snap.data!;

        // client-side filtering: status
        if (statusFilter != 'all') {
          tasks = tasks.where((t) => (t.status == statusFilter)).toList();
        }

        // search
        tasks = tasks.where((t) => _matchesSearch(t, searchQuery)).toList();

        // sort by lastActivity -> createdAt (newest first)
        tasks.sort((a, b) {
          final da = _DashboardStateHelpers.taskKeyTime(a);
          final db = _DashboardStateHelpers.taskKeyTime(b);
          return (db ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            da ?? DateTime.fromMillisecondsSinceEpoch(0),
          );
        });

        if (tasks.isEmpty) {
          return _emptyState("No tasks created yet", Icons.edit);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, i) => TaskCard(task: tasks[i]),
        );
      },
    );
  }
}

/// Assigned to Me Tab (accepts search & filter)
class AssignedTasksTab extends StatelessWidget {
  final String uid;
  final String searchQuery;
  final String statusFilter;
  const AssignedTasksTab({
    super.key,
    required this.uid,
    required this.searchQuery,
    required this.statusFilter,
  });

  bool _matchesSearch(TaskModel t, String q) {
    if (q.isEmpty) return true;
    final low = q.toLowerCase();
    final title = (t.title).toLowerCase();
    final desc = (t.description).toLowerCase();
    return title.contains(low) || desc.contains(low) || t.id.contains(low);
  }

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
        var tasks = snap.data!;

        // status filter
        if (statusFilter != 'all') {
          tasks = tasks.where((t) => (t.status == statusFilter)).toList();
        }

        // search filter
        tasks = tasks.where((t) => _matchesSearch(t, searchQuery)).toList();

        // sort
        tasks.sort((a, b) {
          final da = _DashboardStateHelpers.taskKeyTime(a);
          final db = _DashboardStateHelpers.taskKeyTime(b);
          return (db ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            da ?? DateTime.fromMillisecondsSinceEpoch(0),
          );
        });

        if (tasks.isEmpty) {
          return _emptyState("No assignments yet", Icons.assignment_ind);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, i) => TaskCard(task: tasks[i]),
        );
      },
    );
  }
}

/// Small helpers used by tabs (keeps static and accessible)
class _DashboardStateHelpers {
  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  static DateTime? taskKeyTime(TaskModel t) {
    final la = _toDateTime((t as dynamic).lastActivity);
    return la ?? _toDateTime((t as dynamic).createdAt);
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

/// tiny extension
extension _Cap on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
