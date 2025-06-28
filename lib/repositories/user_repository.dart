import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:talkie/models/user_model.dart';
import 'package:talkie/repositories/failure.dart';
import 'package:talkie/type_defs.dart';

import '../providers/general_providers.dart';

abstract class IUserRepository {
  FutureEitherVoid storeUserData(UserModel userModel);
  FutureVoid changeUserStatus(bool status);
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllUsers();
  Future<Map<String, dynamic>?> getCurrentUserData();
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserById(String id);
  FutureEitherVoid updateUserProfile({
    String? username,
    String? profilePicUrl,
    String? newPassword,
  });
}

final userRepositoryProvider = Provider(
  (ref) => UserRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseAuthProvider),
  ),
);

class UserRepository implements IUserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  UserRepository(this._firestore, this._auth);
  @override
  FutureEitherVoid storeUserData(UserModel userModel) async {
    try {
      _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .set(userModel.toMap());
      return right(null);
    } on FirebaseException catch (e, stackTrace) {
      return left(Failure(e.message.toString(), stackTrace.toString()));
    }
  }

  @override
  FutureVoid changeUserStatus(bool status) async {
    final userUid = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(userUid).update({
      'isOnline': status,
      'lastSeen': DateTime.now().toIso8601String(),
    });
    return;
  }

  @override
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllUsers() {
    final res = _firestore.collection('users').snapshots();
    return res.map((users) => users.docs);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserById(String id) {
    final res = _firestore.collection('users').doc(id).snapshots();
    return res;
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getSearchUsers(
    String query,
  ) {
    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((data) {
          return data.docs;
        });
  }

  @override
  FutureEitherVoid updateUserProfile({
    String? username,
    String? profilePicUrl,
    String? newPassword,
  }) async {
    final uid = _auth.currentUser!.uid;
    try {
      Map<String, dynamic> updates = {};
      if (username != null && username.isNotEmpty) {
        updates['username'] = username;
      }
      if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
        updates['profilePic'] = profilePicUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }

      if (newPassword != null && newPassword.isNotEmpty) {
        await _auth.currentUser!.updatePassword(newPassword);
      }

      return right(null);
    } on FirebaseAuthException catch (e, st) {
      return left(Failure("Auth Error: ${e.message}", st.toString()));
    } on FirebaseException catch (e, st) {
      return left(Failure("Firestore Error: ${e.message}", st.toString()));
    } catch (e, st) {
      return left(Failure("Unexpected Error: $e", st.toString()));
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final uid = _auth.currentUser?.uid;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
