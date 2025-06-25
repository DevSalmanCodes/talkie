import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talkie/models/user_model.dart';
import 'package:talkie/providers/general_providers.dart';
import 'package:talkie/repositories/auth_repository.dart';
import 'package:talkie/repositories/methods/storage_methods.dart';
import 'package:talkie/repositories/user_repository.dart';
import 'package:talkie/services/user_service.dart';
import 'package:talkie/utils/methods.dart';
import 'package:talkie/utils/routes/route_names.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(sharedPreferencesServiceProvider));
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, bool>(
  (ref) => AuthViewModel(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
    ref.watch(userServiceProvider),
  ),
);

final authStateChangesProvider = StreamProvider.autoDispose<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// ViewModel for authentication-related actions.
class AuthViewModel extends StateNotifier<bool> {
  final IAuthRepository _authRepository;
  final UserRepository _userRepository;
  final UserService _userService;

  AuthViewModel(this._authRepository, this._userRepository, this._userService)
    : super(false);

  Future<void> signUp(
    String username,
    String email,
    String password,
    File? file,
    BuildContext context,
  ) async {
    state = true;
    try {
      final res = await _authRepository.signUp(email, password);

      await res.fold(
        (l) async {
          _showError(l.message ?? 'Something went wrong');
        },
        (user) async {
          String? profilePicUrl;
          if (context.mounted && file != null) {
            profilePicUrl = await StorageMethods.uploadFileToFirebase(
              file: file,
              type: UploadType.image,
              path: 'profilePics',
              context: context,
            );
          }

          final id = user.uid;
          UserModel userModel = UserModel(
            username: username,
            email: email,
            password: password,
            uid: id,
            profilePic: profilePicUrl ?? '',
            isOnline: false,
            lastSeen: DateTime.now().millisecondsSinceEpoch.toString(),
          );

          final res2 = await _userRepository.storeUserData(userModel);

          await res2.fold(
            (l) async => _showError(l.message ?? 'Something went wrong'),
            (r) async {
              await _userService.setUser(userModel);
              if (context.mounted) {
                showToast('Please login to continue');
                Navigator.pushNamed(context, RouteNames.login);
              }
            },
          );
        },
      );
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      state = false;
    }
  }

  /// Logs in a user.
  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    state = true;
    try {
      final res = await _authRepository.login(email, password, context);

      await res.fold(
        (l) async => _showError(l.message ?? 'Something went wrong'),
        (_) async {
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.navBar,
              (_) => false,
            );
            showToast("Logged in successfully");
          }
        },
      );
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      state = false;
    }
  }

  /// Signs out the current user.
  Future<void> signOut(BuildContext context) async {
    state = true;
    try {
      await _authRepository.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.login);
      }
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      state = false;
    }
  }

  void _showError(String message) {
    showToast(message);
  }
}
