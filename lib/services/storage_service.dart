import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'tc_mobile_token';
  static const String _keyAgentName = 'tc_agent_name';
  static const String _keyAiOutboundActive = 'tc_ai_outbound_active';
  static const String _keyAiReceptionistActive = 'tc_ai_receptionist_active';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String> getAgentName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAgentName) ?? 'Santosh Yadav (Varanasi HQ)';
  }

  static Future<void> setAgentName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAgentName, name);
  }

  static Future<bool> getAiOutboundActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAiOutboundActive) ?? true;
  }

  static Future<void> setAiOutboundActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAiOutboundActive, active);
  }

  static const String _keyThemeMode = 'tc_theme_mode';

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'dark';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  static Future<bool> getAiReceptionistActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAiReceptionistActive) ?? true;
  }

  static Future<void> setAiReceptionistActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAiReceptionistActive, active);
  }
}
