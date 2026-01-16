import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String fullName;
  final String farmLocation;
  final String farmArea;
  final String? photoUrl;

  UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.farmLocation,
    required this.farmArea,
    this.photoUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      farmLocation: data['farmLocation'] ?? '',
      farmArea: data['farmArea'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'farmLocation': farmLocation,
      'farmArea': farmArea,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'users';

  Future<void> saveUser(UserProfile profile) async {
    await _db.collection(_collection).doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfile?> getUser(String uid) async {
    final doc = await _db.collection(_collection).doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.data()!, uid);
    }
    return null;
  }
}
