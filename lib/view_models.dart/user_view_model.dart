import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkie/models/user_model.dart';
import 'package:talkie/repositories/methods/storage_methods.dart';
import 'package:talkie/repositories/user_repository.dart';
import 'package:talkie/utils/methods.dart';

final userViewModelProvider = StateNotifierProvider<UserViewModel, bool>(
  (ref) => UserViewModel(ref.watch(userRepositoryProvider)),
);
final getCurrentUserDataProvider = FutureProvider(
  (ref) => ref.read(userViewModelProvider.notifier).getCurrentUserData(),
);

final getAllUsersProvider = StreamProvider((ref) {
  final users = ref.watch(userViewModelProvider.notifier);
  return users.getAllUsers();
});

final userDetailsProvider = StreamProvider.family<UserModel, String>(
  (ref, String id) => ref.watch(userViewModelProvider.notifier).getUserById(id),
);

final getSearchUsersProvider = StreamProvider.family<List<UserModel>, String>((
  ref,
  String query,
) {
  if (query.isEmpty) {
    return Stream.value([]);
  }
  return ref.watch(userViewModelProvider.notifier).getSearchUsers(query);
});

class UserViewModel extends StateNotifier<bool> {
  final UserRepository _userRepository;
  UserViewModel(this._userRepository) : super(false);

  void changeUserStatus(bool status) async {
    await _userRepository.changeUserStatus(status);
  }

  Stream<List<UserModel>> getAllUsers() {
    return _userRepository.getAllUsers().map(
      (data) => data.map((e) => UserModel.fromMap(e.data())).toList(),
    );
  }

  Stream<UserModel> getUserById(String id) {
    final user = _userRepository.getUserById(id);
    return user.map((user) => UserModel.fromMap(user.data()!));
  }

  Stream<List<UserModel>> getSearchUsers(String query) {
    final users = _userRepository.getSearchUsers(query);
    return users.map(
      (data) => data.map((user) => UserModel.fromMap(user.data())).toList(),
    );
  }

  Future<void> updateUserProfile(
    String username,

    String path,
    BuildContext context, [
    String? newPassword,
  ]) async {
    state = true;
    final url = await StorageMethods.uploadFileToFirebase(
      file: File(path),
      type: UploadType.image,
      path: 'profilePics',
      context: context,
    );
    await _userRepository.updateUserProfile(
      username: username,
      profilePicUrl: url,
      newPassword: newPassword,
    );
    state = false;
    showToast('Updated');
  }

  Future<UserModel> getCurrentUserData() async {
    final res = await _userRepository.getCurrentUserData();
    return UserModel.fromMap(res!);
  }
}
