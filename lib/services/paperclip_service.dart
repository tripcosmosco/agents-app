import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'http_client_helper.dart';

/// Sovereign Paperclip Multi-Agent Fleet API Service
/// Connects X-Agents directly to https://agents.vmstudio.digital
class PaperclipService {
  static const String defaultBaseUrl = 'https://agents.vmstudio.digital';
  static const String defaultBoardToken = 'pcp_board_5dde65f2d0d990fd0e186d1e8cdf997f4bb1199b978e9e6a';

  final http.Client _client = getHttpClient();
  String _baseUrl = defaultBaseUrl;
  String _boardToken = defaultBoardToken;

  PaperclipService() {
    _loadCustomConfig();
  }

  Future<void> _loadCustomConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('paperclip_base_url');
      final savedToken = prefs.getString('paperclip_board_token');
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _baseUrl = savedUrl.trim();
      }
      if (savedToken != null && savedToken.trim().isNotEmpty) {
        _boardToken = savedToken.trim();
      }
    } catch (e) {
      debugPrint('Error loading Paperclip custom config: $e');
    }
  }

  String get baseUrl => _baseUrl;
  String get boardToken => _boardToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $_boardToken',
    if (!kIsWeb) 'User-Agent': 'X-Agents-Mobile/1.0.0 (Android; Flutter)',
  };

  /// 1. Fetch Companies
  Future<List<Map<String, dynamic>>> fetchCompanies() async {
    try {
      final res = await _client.get(Uri.parse('$_baseUrl/api/companies'), headers: _headers);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.map((c) => Map<String, dynamic>.from(c as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('PaperclipService.fetchCompanies error: $e');
    }
    return [];
  }

  /// 2. Fetch Agents for a Company
  Future<List<Map<String, dynamic>>> fetchAgents(String companyId) async {
    try {
      final res = await _client.get(
        Uri.parse('$_baseUrl/api/companies/$companyId/agents'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.map((a) => Map<String, dynamic>.from(a as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('PaperclipService.fetchAgents error: $e');
    }
    return [];
  }

  /// 3. Fetch Routines for a Company
  Future<List<Map<String, dynamic>>> fetchRoutines(String companyId) async {
    try {
      final res = await _client.get(
        Uri.parse('$_baseUrl/api/companies/$companyId/routines'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.map((r) => Map<String, dynamic>.from(r as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('PaperclipService.fetchRoutines error: $e');
    }
    return [];
  }

  /// 4. Fetch Issues/Tasks for a Company
  Future<List<Map<String, dynamic>>> fetchIssues(String companyId) async {
    try {
      final res = await _client.get(
        Uri.parse('$_baseUrl/api/companies/$companyId/issues'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.map((i) => Map<String, dynamic>.from(i as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('PaperclipService.fetchIssues error: $e');
    }
    return [];
  }

  /// 5. Update Agent Details (Title, Model, Role, Reporting)
  Future<bool> updateAgent(String agentId, Map<String, dynamic> updates) async {
    try {
      final res = await _client.patch(
        Uri.parse('$_baseUrl/api/agents/$agentId'),
        headers: _headers,
        body: jsonEncode(updates),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('PaperclipService.updateAgent error: $e');
      return false;
    }
  }

  /// 6. Trigger / Run a Routine Immediately
  Future<bool> triggerRoutine(String routineId) async {
    try {
      final res = await _client.post(
        Uri.parse('$_baseUrl/api/routines/$routineId/run'),
        headers: _headers,
        body: jsonEncode({'triggerType': 'manual_board_dispatch'}),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('PaperclipService.triggerRoutine error: $e');
      return false;
    }
  }

  /// 7. Create a New Issue / Task
  Future<Map<String, dynamic>?> createIssue(String companyId, {
    required String title,
    required String description,
    String? assigneeAgentId,
    String priority = 'high',
  }) async {
    try {
      final res = await _client.post(
        Uri.parse('$_baseUrl/api/companies/$companyId/issues'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'priority': priority,
          'status': 'todo',
          if (assigneeAgentId != null && assigneeAgentId.isNotEmpty)
            'assigneeAgentId': assigneeAgentId,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      }
    } catch (e) {
      debugPrint('PaperclipService.createIssue error: $e');
    }
    return null;
  }

  /// 8. System Health
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final res = await _client.get(Uri.parse('$_baseUrl/api/health'));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      }
    } catch (e) {
      debugPrint('PaperclipService.checkHealth error: $e');
    }
    return null;
  }
}
