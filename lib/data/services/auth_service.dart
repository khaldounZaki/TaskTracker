import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../../utils/constants.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String mobile,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // create user document with active=false by default
    final userDoc = AppUser(
      uid: cred.user!.uid,
      email: email,
      name: name,
      mobile: mobile,
      picture: '',
      active: false,
    );

    await _firestore
        .collection(COL_USERS)
        .doc(userDoc.uid)
        .set(userDoc.toMap());
    notifyListeners();
    return cred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    notifyListeners();
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
