import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'package:provider/provider.dart';

import 'data/services/auth_service.dart';
import 'data/services/user_service.dart';
import 'data/services/task_service.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => TaskService()),
        // NotificationService is not a ChangeNotifier because it exposes a stream
        // of incoming messages and handles token registration.
        //Provider(create: (_) => NotificationService()..init()),
      ],
      child: const MyApp(),
    ),
  );
}
