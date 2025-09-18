import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/constants.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _onMessageController = StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onMessage => _onMessageController.stream;

  Future<void> init() async {
    // Request permission for iOS
    await _messaging.requestPermission();

    // Get the token and (optionally) save it to Firestore for the current user.
    final token = await _messaging.getToken();
    debugPrint('FCM token: \$token');

    // Listen to messages while app is foregrounded
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _onMessageController.add(message);
    });

    // Handle background messages is configured in native code / top-level handler
  }

  void dispose() {
    _onMessageController.close();
  }

  // Save token for a specific user in the users collection so you can call
  // server-side code (Cloud Functions) to send notifications to that token.
  Future<void> saveTokenForCurrentUser(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection(COL_USERS).doc(uid).update({
      'fcmToken': token,
    });
  }
}
