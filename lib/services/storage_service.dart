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

  static const String _keyPairedAiName = 'tc_paired_ai_name';

  static Future<String> getAgentName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAgentName) ?? 'Executive Agent';
  }

  static Future<void> setAgentName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAgentName, name);
  }

  static Future<String> getPairedAiName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPairedAiName) ?? 'Aditi AI';
  }

  static Future<void> setPairedAiName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPairedAiName, name);
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

  static Future<bool> setAiReceptionistActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_keyAiReceptionistActive, active);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }
}
