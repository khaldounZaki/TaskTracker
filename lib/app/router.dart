import 'package:flutter/material.dart';

import '../views/auth/login_page.dart';
import '../views/auth/register_page.dart';
import '../views/auth/profile_page.dart';
import '../views/dashboard/dashboard_page.dart';
import '../views/tasks/task_detail_page.dart';
import '../views/tasks/add_task_page.dart';
import '../views/admin/user_management_page.dart';
import '../views/notification/notification_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case '/task-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => TaskDetailPage(taskId: args?['taskId']),
        );
      case '/add-task':
        return MaterialPageRoute(builder: (_) => const AddTaskPage());
      case '/admin-users':
        return MaterialPageRoute(builder: (_) => const UserManagementPage());
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsPage());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
