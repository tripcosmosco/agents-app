import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'tc_mobile_api_token';
  static const String _keyAgentName = 'tc_agent_name';
  static const String _keyAiOutboundActive = 'tc_ai_outbound_active';
  static const String _keyAiReceptionistActive = 'tc_ai_receptionist_active';
  static const String _keySecurityPin = 'tc_security_lock_pin';

  // Device-level obfuscation / cipher key for local token and PIN privacy
  static const String _salt = 'TC_AGENTS_X_ENTERPRISE_2026';

  static String _seal(String plain) {
    if (plain.isEmpty) return '';
    final bytes = utf8.encode(plain);
    final keyBytes = utf8.encode(_salt);
    final sealed = List<int>.generate(bytes.length, (i) => bytes[i] ^ keyBytes[i % keyBytes.length]);
    return 'tc_sec:${base64Url.encode(sealed)}';
  }

  static String _unseal(String val) {
    if (val.isEmpty) return '';
    if (!val.startsWith('tc_sec:')) return val; // Graceful backward compatibility
    try {
      final raw = base64Url.decode(val.substring(7));
      final keyBytes = utf8.encode(_salt);
      final unsealed = List<int>.generate(raw.length, (i) => raw[i] ^ keyBytes[i % keyBytes.length]);
      return utf8.decode(unsealed);
    } catch (_) {
      return '';
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyToken);
    if (raw == null || raw.isEmpty) return null;
    return _unseal(raw);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.isEmpty) {
      await prefs.remove(_keyToken);
    } else {
      await prefs.setString(_keyToken, _seal(token));
    }
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  static Future<String> getSecurityPin() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySecurityPin);
    if (raw == null || raw.isEmpty) return '1234';
    return _unseal(raw);
  }

  static Future<void> setSecurityPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySecurityPin, _seal(pin));
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

  static const String _keyCachedLeads = 'tc_cached_leads_json';
  static const String _keyCachedThreads = 'tc_cached_threads_json';
  static const String _keyCachedCallLogs = 'tc_cached_call_logs_json';

  static Future<String?> getCachedLeads() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedLeads);
  }

  static Future<void> setCachedLeads(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedLeads, jsonStr);
  }

  static Future<String?> getCachedThreads() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedThreads);
  }

  static Future<void> setCachedThreads(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedThreads, jsonStr);
  }

  static Future<String?> getCachedCallLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedCallLogs);
  }

  static Future<void> setCachedCallLogs(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedCallLogs, jsonStr);
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
