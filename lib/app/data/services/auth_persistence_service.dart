import 'package:shared_preferences/shared_preferences.dart';

class AuthPersistenceService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save login state
  Future<void> saveLoginState(String userId, String email) async {
    await _prefs.setBool(_isLoggedInKey, true);
    await _prefs.setString(_userIdKey, userId);
    await _prefs.setString(_userEmailKey, email);
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get saved user ID
  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  // Get saved user email
  String? getUserEmail() {
    return _prefs.getString(_userEmailKey);
  }

  // Clear login state on logout
  Future<void> clearLoginState() async {
    await _prefs.remove(_isLoggedInKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userEmailKey);
  }
}
