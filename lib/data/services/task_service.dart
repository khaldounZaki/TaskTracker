import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/task_model.dart';
import '../models/subtask_model.dart';
import '../../utils/constants.dart';

class TaskService extends ChangeNotifier {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  // Create main task
  Future<String> createTask({
    required String title,
    required String description,
    required String createdBy,
  }) async {
    final docRef = await _fs.collection(COL_TASKS).add({
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(), // ✅ added
    });
    notifyListeners();
    return docRef.id;
  }

  // Add subtask
  Future<void> addSubtask({
    required String taskId,
    required String fromUser,
    required String toUser,
    required String description,
  }) async {
    final subcol = _fs
        .collection(COL_TASKS)
        .doc(taskId)
        .collection(COL_SUBTASKS);
    await subcol.add({
      'fromUser': fromUser,
      'toUser': toUser,
      'description': description,
      'result': '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // update parent task
    await _fs.collection(COL_TASKS).doc(taskId).update({
      'status': 'in-progress',
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(), // ✅
    });
    notifyListeners();
  }

  // Complete subtask
  Future<void> completeSubtask({
    required String taskId,
    required String subtaskId,
    required String result,
  }) async {
    final subRef = _fs
        .collection(COL_TASKS)
        .doc(taskId)
        .collection(COL_SUBTASKS)
        .doc(subtaskId);

    await subRef.update({
      'result': result,
      'status': 'done',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // After completing, check if any pending subtasks remain
    final subsSnap = await _fs
        .collection(COL_TASKS)
        .doc(taskId)
        .collection(COL_SUBTASKS)
        .get();

    final anyPending = subsSnap.docs.any(
      (d) => (d.data()['status'] ?? 'pending') != 'done',
    );

    final parentUpdate = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(), // ✅
    };

    if (!anyPending) {
      parentUpdate['status'] = 'done';
    }

    await _fs.collection(COL_TASKS).doc(taskId).update(parentUpdate);
    notifyListeners();
  }

  // Streams ordered by lastActivity
  Stream<List<TaskModel>> streamTasksCreatedBy(String uid) {
    return _fs
        .collection(COL_TASKS)
        .where('createdBy', isEqualTo: uid)
        .orderBy('lastActivity', descending: true) // ✅
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskModel.fromDoc(d)).toList());
  }

  Stream<List<TaskModel>> streamTasksAssignedTo(String uid) async* {
    final subStream = _fs
        .collectionGroup(COL_SUBTASKS)
        .where('toUser', isEqualTo: uid)
        .snapshots();

    await for (final subSnap in subStream) {
      final taskIdSet = <String>{};
      for (final doc in subSnap.docs) {
        final parentTaskRef = doc.reference.parent.parent;
        if (parentTaskRef != null) taskIdSet.add(parentTaskRef.id);
      }

      final tasks = <TaskModel>[];
      for (final taskId in taskIdSet) {
        final taskDocRef = _fs.collection(COL_TASKS).doc(taskId);
        final taskDoc = await taskDocRef.get();
        if (!taskDoc.exists) continue;

        final task = TaskModel.fromDoc(taskDoc);

        final subsSnap = await taskDocRef
            .collection(COL_SUBTASKS)
            .orderBy('createdAt', descending: false)
            .get();

        final subs = subsSnap.docs
            .map((d) => SubtaskModel.fromDoc(d))
            .where((s) => s.fromUser == uid || s.toUser == uid)
            .toList();

        if (subs.isNotEmpty) {
          tasks.add(task.copyWith(subtasks: subs));
        }
      }

      // ✅ sort by lastActivity instead of createdAt
      tasks.sort((a, b) {
        final aDate = a.lastActivity ?? a.updatedAt ?? a.createdAt;
        final bDate = b.lastActivity ?? b.updatedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });

      yield tasks;
    }
  }

  Stream<TaskModel?> streamTask(String taskId) {
    return _fs.collection('tasks').doc(taskId).snapshots().map((doc) {
      if (doc.exists) {
        return TaskModel.fromDoc(doc);
      } else {
        return null;
      }
    });
  }

  Stream<List<SubtaskModel>> streamSubtasks(String taskId) {
    return _fs
        .collection(COL_TASKS)
        .doc(taskId)
        .collection(COL_SUBTASKS)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SubtaskModel.fromDoc(d)).toList());
  }
}
