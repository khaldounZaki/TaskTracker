import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../../utils/constants.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //print((snap.docs.map((d) => AppUser.fromDoc(d)).toList()));
  Stream<List<AppUser>> streamAllUsers() {
    return _fs.collection(COL_USERS).snapshots().map((snap) {
      print((snap.docs.map((d) => AppUser.fromDoc(d)).toList()));
      return snap.docs.map((d) => AppUser.fromDoc(d)).toList();
    });
  }

  Future<List<AppUser>> fetchAllUsers() async {
    final snap = await _fs.collection(COL_USERS).get();
    return snap.docs.map((d) => AppUser.fromDoc(d)).toList();
  }

  Future<List<AppUser>> fetchOtherActiveUsers() async {
    final currentUid = _auth.currentUser?.uid;

    final snap = await _fs
        .collection(COL_USERS)
        .where("active", isEqualTo: true)
        .get();
    print(snap.docs);

    return snap.docs
        .map((d) => AppUser.fromDoc(d))
        .where((u) => u.uid != currentUid) // ✅ exclude self
        .toList();
  }

  // Future<List<AppUser>> futureAllUsers() async {
  //   List<AppUser> appUsers = [];
  //   await (_fs.collection(COL_USERS).snapshots().map((snap) {
  //     appUsers.add(snap.docs.map((d) => AppUser.fromDoc(d)).first);
  //   }).first);
  //   print(appUsers);
  //   return appUsers;
  // }

  Future<AppUser?> getUserById(String uid) async {
    final doc = await _fs.collection(COL_USERS).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Future<void> updateUserActive(String uid, bool active) async {
    await _fs.collection(COL_USERS).doc(uid).update({'active': active});
    notifyListeners();
  }

  Future<void> updateProfile(AppUser user) async {
    await _fs.collection(COL_USERS).doc(user.uid).update(user.toMap());
    notifyListeners();
  }

  Future<void> saveFcmToken(String uid, String token) async {
    await _fs.collection(COL_USERS).doc(uid).update({'fcmToken': token});
  }
}
