import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String mobile;
  final String picture;
  final bool active;
  final String? fcmToken;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.mobile,
    required this.picture,
    required this.active,
    this.fcmToken,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) {
    return AppUser(
      uid: uid,
      email: m['email'] ?? '',
      name: m['name'] ?? '',
      mobile: m['mobile'] ?? '',
      picture: m['picture'] ?? '',
      active: m['active'] ?? false,
      fcmToken: m['fcmToken'],
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    //print(doc.data().toString());
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser.fromMap(doc.id, map);
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'mobile': mobile,
      'picture': picture,
      'active': active,
      'fcmToken': fcmToken,
    };
  }

  AppUser copyWith({
    String? name,
    String? mobile,
    String? picture,
    bool? active,
    String? fcmToken,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      picture: picture ?? this.picture,
      active: active ?? this.active,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
