import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:talkie/repositories/failure.dart';
import 'package:talkie/type_defs.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(FirebaseAuth.instance),
);

abstract class IAuthRepository {
  FutureEither<User> signUp(String email, String password);
  FutureEither<User> login(String email, String password, BuildContext context);
  FutureEitherVoid signOut();
}

class AuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  @override
  FutureEither<User> signUp(String email, String password) async {
    try {
      final res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return right(res.user!);
    } on FirebaseAuthException catch (e, stackTrace) {
      return left(Failure(e.message!, stackTrace.toString()));
    }
  }

  @override
  FutureEither<User> login(
      String email, String password, BuildContext context) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return right(res.user!);
    } on FirebaseAuthException catch (e, stackTrace) {
      return left(Failure(e.message!, stackTrace.toString()));
    }
  }

  @override
  FutureEitherVoid signOut() async {
    try {
      await _auth.signOut();
      return right(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return left(Failure(e.message!, stackTrace.toString()));
    }
  }
}
