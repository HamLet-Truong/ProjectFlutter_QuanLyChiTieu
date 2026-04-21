import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalStorage {
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyProfileNote = 'profile_note';
  static const _keyProfileAvatarPath = 'profile_avatar_path';
  static const _keyOnboardingPrefix = 'onboarding_completed_';

  static String _buildOnboardingKey({String? userId, String? email}) {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      return '$_keyOnboardingPrefix$normalizedEmail';
    }

    final normalizedUserId = userId?.trim();
    if (normalizedUserId != null && normalizedUserId.isNotEmpty) {
      return '$_keyOnboardingPrefix$normalizedUserId';
    }

    return '${_keyOnboardingPrefix}guest';
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
  }

  static Future<String> getProfileNote() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfileNote) ?? '';
  }

  static Future<void> setProfileNote(String note) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileNote, note);
  }

  static Future<String?> getProfileAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfileAvatarPath);
  }

  static Future<void> setProfileAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileAvatarPath, path);
  }

  static Future<bool> getOnboardingCompleted({String? userId, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildOnboardingKey(userId: userId, email: email);
    return prefs.getBool(key) ?? false;
  }

  static Future<void> setOnboardingCompleted(
    bool value, {
    String? userId,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildOnboardingKey(userId: userId, email: email);
    await prefs.setBool(key, value);
  }

  static Future<void> resetOnboarding({String? userId, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildOnboardingKey(userId: userId, email: email);
    await prefs.remove(key);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotificationsEnabled);
    await prefs.remove(_keyProfileNote);
    await prefs.remove(_keyProfileAvatarPath);
  }
}
