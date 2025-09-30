import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _fs = FirebaseFirestore.instance;

  Future<void> sendNotification({
    required String toUser,
    required String title,
    required String body,
    required String taskId,
    required String subtaskId,
    required String fromUser,
  }) async {
    await _fs.collection('users').doc(toUser).collection('notifications').add({
      "title": title,
      "body": body,
      "taskId": taskId,
      "subtaskId": subtaskId,
      "isRead": false,
      "fromUser": fromUser,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamNotifications(String uid) {
    return _fs
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {"id": d.id, ...d.data()}).toList(),
        );
  }

  Future<void> markAsRead(String uid, String notificationId) async {
    await _fs
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({"isRead": true});
  }
}
