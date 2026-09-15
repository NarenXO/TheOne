import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyFirstLaunch = 'is_first_launch';
  static const _keyUserName = 'user_name';
  static const _keyUserMode = 'user_mode';

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  static Future<void> completeOnboarding(String name, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
    await prefs.setString(_keyUserName, name.trim().isEmpty ? 'User' : name.trim());
    await prefs.setString(_keyUserMode, mode);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'User';
  }

  static Future<String> getUserMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserMode) ?? 'vision';
  }
}