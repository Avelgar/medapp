import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _profileKey = 'user_profile_data';
  static const String _authKey = 'user_auth_data';
  static const String _sleepStartKey = 'current_sleep_start_time';
  static const String _themeKey = 'app_theme_mode';

  Future<void> saveProfile(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonString);
  }

  Future<String?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileKey);
  }

  Future<bool> hasProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_profileKey);
  }

  Future<void> saveAuth(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, jsonString);
  }

  Future<String?> loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authKey);
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
  }

  Future<void> saveSleepStart(DateTime startTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sleepStartKey, startTime.toIso8601String());
  }

  Future<DateTime?> getSleepStart() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_sleepStartKey);
    return str != null ? DateTime.parse(str) : null;
  }

  Future<void> clearSleepStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sleepStartKey);
  }

  Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<bool> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }
}
