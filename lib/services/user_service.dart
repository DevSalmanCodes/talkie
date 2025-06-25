import 'package:talkie/models/user_model.dart';
import 'package:talkie/services/shared_preferences_service.dart';

class UserService {
  UserModel? _user;
  UserModel? get user => _user;
  final SharedPreferencesService _preferencesService;
  UserService(this._preferencesService);

  Future<void> setUser(UserModel user) async {
    await _preferencesService.setUser(user);
    _user = user;
  }

  Future<void> clearUser() async {
    await _preferencesService.clearUser();
    _user = null;
  }

  Future<void> getUser() async {
    final user = await _preferencesService.getUser();
    _user = user;
  }
}
