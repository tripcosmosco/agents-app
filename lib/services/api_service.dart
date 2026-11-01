import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/call_log_model.dart';
import '../models/event_model.dart';
import '../models/lead_model.dart';
import '../models/quote_model.dart';
import 'storage_service.dart';

class ApiService {
  String _baseUrl;
  String? _apiToken;

  ApiService({String? baseUrl, String? apiToken})
      : _baseUrl = baseUrl ?? AppConstants.defaultApiBaseUrl {
    _apiToken = (apiToken != null && apiToken.trim().isNotEmpty)
        ? apiToken.trim()
        : null;
  }

  String get baseUrl {
    String url = _baseUrl.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      url = AppConstants.defaultApiBaseUrl;
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
  String? get apiToken => _apiToken;
  bool get isAuthenticated => _apiToken != null && _apiToken!.trim().isNotEmpty;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (!kIsWeb) 'User-Agent': 'X-Agents-Mobile/1.0.0 (Android; Flutter)',
    if (_apiToken != null && _apiToken!.isNotEmpty) ...{
      'X-Mobile-Token': _apiToken!,
      'Authorization': 'Bearer $_apiToken',
    },
  };

  dynamic _safeJsonDecode(String body) {
    final trimmed = body.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      return null;
    }
    try {
      return json.decode(trimmed);
    } catch (e) {
      debugPrint('JSON decode error: $e');
      return null;
    }
  }

  /// Load persistent settings from device storage
  Future<void> initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('tc_api_base_url');
      final savedToken = await StorageService.getToken();
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = savedUrl;
      }
      if (savedToken != null && savedToken.trim().isNotEmpty) {
        _apiToken = savedToken.trim();
      } else {
        _apiToken = null;
      }
    } catch (e) {
      debugPrint('Error loading API preferences: $e');
    }
  }

  /// Save API configuration to device storage
  Future<bool> saveConfig({required String newBaseUrl, required String newApiToken}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tc_api_base_url', newBaseUrl.trim());
      await StorageService.setToken(newApiToken.trim());
      _baseUrl = newBaseUrl.trim();
      _apiToken = newApiToken.trim();
      return true;
    } catch (e) {
      debugPrint('Error saving API config: $e');
      return false;
    }
  }

  /// Update active mobile API token
  Future<bool> setApiToken(String? token) async {
    try {
      final clean = (token ?? '').trim();
      if (clean.isEmpty) {
        _apiToken = null;
        await StorageService.clearToken();
      } else {
        _apiToken = clean;
        await StorageService.setToken(clean);
      }
      return true;
    } catch (e) {
      debugPrint('Error setting API token: $e');
      return false;
    }
  }

  /// Disconnect workspace by removing API token
  Future<bool> clearConfig() async {
    try {
      await StorageService.clearToken();
      _apiToken = null;
      return true;
    } catch (e) {
      debugPrint('Error clearing API config: $e');
      return false;
    }
  }

  /// Test live connection and token authentication against server
  Future<Map<String, dynamic>> testConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse('$baseUrl/mobile/events?limit=1');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 25));
      stopwatch.stop();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'message': '✓ Connected to TripCosmos API (${stopwatch.elapsedMilliseconds}ms)',
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'message': '❌ Authentication failed (HTTP ${response.statusCode}). Invalid Mobile API Token.',
        };
      } else {
        return {
          'success': false,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'message': '⚠️ Server returned HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'message': '❌ Connection error: $e',
      };
    }
  }

  /// 1. Fetch pending calls from Jio SIM queue (Website / Ad Leads requesting call)
  Future<List<Map<String, dynamic>>> fetchCallQueue() async {
    if (!isAuthenticated) return [];
    try {
      final uri = Uri.parse('$baseUrl/mobile/call-queue');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        final isSuccess = data != null && (data['ok'] == true || data['success'] == true);
        if (isSuccess && data['calls'] is List) {
          return (data['calls'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    } catch (_) {
      // Endpoint may be idle or offline
    }
    return [];
  }

  /// Fetch past logged calls from WordPress database
  Future<List<CallLogModel>> fetchCallLogs({int limit = 50, int offset = 0}) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/call-logs?limit=$limit&offset=$offset');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        final isSuccess = data != null && (data['ok'] == true || data['success'] == true);
        if (isSuccess && data['calls'] is List) {
          return (data['calls'] as List)
              .map((c) => CallLogModel.fromJson(Map<String, dynamic>.from(c)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching call logs: $e');
    }
    return [];
  }

  /// 2. Report Call Dispatch Status (Dialing, Connected, Completed, Duration)
  Future<bool> reportCallDispatch({
    required String callId,
    required String status,
    required String phone,
    int duration = 0,
    String notes = '',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/call-dispatch');
      final body = json.encode({
        'call_id': callId,
        'status': status,
        'phone': phone,
        'duration': duration,
        'notes': notes,
      });

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error reporting call dispatch: $e');
      return false;
    }
  }

  /// 3. Voice AI RAG Query (AI Puffer Bot 155464 spoken answer)
  Future<String> queryVoiceRag({
    required String transcript,
    String sessionId = '',
    String agentSlug = 'nishkarsh-ai',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/voice/query-rag');
      final body = json.encode({
        'transcript': transcript,
        'message': transcript,
        'session_id': sessionId,
        'agent_slug': agentSlug,
        'agent': agentSlug,
      });

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['reply'] != null) {
          return data['reply'];
        }
      }
    } catch (e) {
      debugPrint('Error querying voice RAG: $e');
    }
    return 'Namaste! Our travel specialist will connect with you on WhatsApp right away.';
  }

  /// 4. Fetch CRM Leads from WordPress & Connected CRMs
  Future<List<LeadModel>> fetchLeads() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/leads');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        final isSuccess = data != null && (data['ok'] == true || data['success'] == true);
        if (isSuccess && data['leads'] is List) {
          return (data['leads'] as List)
              .map(
                (item) => LeadModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching leads: $e');
    }
    return [];
  }

  /// 5. Smart Caller ID Lookup
  Future<Map<String, dynamic>?> lookupCallerId(String phone) => lookupCaller(phone);

  /// 6. Generate Dynamic Tour Quote & Tariff
  Future<QuoteModel?> generateQuote({
    required String destination,
    required int pax,
    String rateType = 'b2c',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/generate-quote');
      final body = json.encode({
        'destination': destination,
        'pax': pax,
        'rate_type': rateType,
      });

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['ok'] == true) {
          return QuoteModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Error generating quote: $e');
    }
    return null;
  }

  /// 7. Send Driver Dispatch SMS / Confirmation via Brevo
  Future<bool> sendDriverDispatch({
    required String phone,
    required String customerName,
    required String driverName,
    required String vehicleNumber,
    required String vehicleType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/send-dispatch');
      final body = json.encode({
        'phone': phone,
        'customer_name': customerName,
        'driver_name': driverName,
        'vehicle_number': vehicleNumber,
        'vehicle_type': vehicleType,
      });

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending driver dispatch: $e');
      return false;
    }
  }

  /// 8. Fetch Real-time Activity Events Feed (Visitor landings, Leads, Calls)
  Future<List<EventModel>> fetchEvents({int? sinceId, int limit = 20}) async {
    final res = await fetchEventsWithStats(sinceId: sinceId, limit: limit);
    if (res != null && res['events'] is List) {
      return (res['events'] as List).whereType<EventModel>().toList();
    }
    return [];
  }

  /// 8b. Fetch Real-time Activity Events Feed WITH Live Server Counters
  Future<Map<String, dynamic>?> fetchEventsWithStats({int? sinceId, int limit = 35}) async {
    if (!isAuthenticated) return null;
    try {
      final queryParams = <String, String>{
        'limit': '$limit',
        if (sinceId != null && sinceId > 0) 'since_id': '$sinceId',
      };
      final uri = Uri.parse('$baseUrl/mobile/events').replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        final isSuccess = data != null && (data['ok'] == true || data['success'] == true);
        if (isSuccess && data['events'] is List) {
          final parsedEvents = (data['events'] as List)
              .map((item) => EventModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          return {
            'events': parsedEvents,
            'active_now_count': data['active_now_count'] ?? 0,
            'visitors_24h_count': data['visitors_24h_count'] ?? 0,
            'total_visitors_all': data['total_visitors_all'] ?? 0,
            'leads_24h_count': data['leads_24h_count'] ?? 0,
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching mobile events: $e');
    }
    return null;
  }

  /// 9. Fetch Real-time Inbound WhatsApp Leads Stream
  Future<List<Map<String, dynamic>>> fetchWhatsAppLeads() async {
    final data = await fetchWhatsAppHubData();
    if (data != null && data['leads'] is List) {
      return (data['leads'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  /// 9b. Fetch Superfone Unified Hub Data (Leads + Evolution Live Status)
  Future<Map<String, dynamic>?> fetchWhatsAppHubData() async {
    if (!isAuthenticated) return null;
    try {
      final uri = Uri.parse('$baseUrl/mobile/whatsapp-leads');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        final isSuccess = data != null && (data['ok'] == true || data['success'] == true);
        if (isSuccess) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching WhatsApp hub data: $e');
    }
    return null;
  }

  /// 9c. Fetch Chronological Superfone Unified Timeline (Evolution WhatsApp + Calls + Notes + Web Chat)
  Future<Map<String, dynamic>?> fetchWhatsAppMessages({
    required String phone,
    String remoteJid = '',
    int contactId = 0,
  }) async {
    if (!isAuthenticated) return null;
    try {
      final queryParams = <String, String>{
        if (phone.isNotEmpty) 'phone': phone,
        if (remoteJid.isNotEmpty) 'remote_jid': remoteJid,
        if (contactId > 0) 'contact_id': contactId.toString(),
      };
      final uri = Uri.parse('$baseUrl/mobile/whatsapp-messages').replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && (data['ok'] == true || data['success'] == true)) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching WhatsApp messages for $phone: $e');
    }
    return null;
  }

  /// 10. Update Lead Stage, Owner, Follow-Up, AI Status & Activity Notes (Bidirectional CRM Sync)
  Future<bool> updateLead({
    String leadId = '',
    String? phone,
    String? name,
    String? stage,
    String? note,
    String? owner,
    String? nextFollowUpAt,
    bool? isAiActive,
    double? dealValue,
    String? destination,
    String? author,
  }) async {
    final cleanId = int.tryParse(leadId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (cleanId == 0 && (phone == null || phone.trim().isEmpty)) return false;

    try {
      final uri = Uri.parse('$baseUrl/mobile/update-lead');
      final payload = <String, dynamic>{
        if (cleanId > 0) 'lead_id': cleanId,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (name != null && name.isNotEmpty) 'name': name,
        if (stage != null && stage.isNotEmpty) 'stage': stage,
        if (note != null && note.isNotEmpty) 'note': note,
        if (owner != null && owner.isNotEmpty) 'owner': owner,
        if (nextFollowUpAt case final String val) 'next_follow_up_at': val,
        if (isAiActive case final bool val) 'is_ai_active': val,
        if (dealValue case final double val) 'deal_value': val,
        if (destination != null && destination.isNotEmpty) 'destination': destination,
        if (author != null && author.isNotEmpty) 'author': author,
      };

      final response = await http
          .post(uri, headers: _headers, body: json.encode(payload))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating lead on server: $e');
      return false;
    }
  }

  /// 10a. Assign Lead to Manager or AI Persona (Team Nishkarsh / Team Aditi)
  Future<bool> assignLead({
    required String leadId,
    required String managerName,
    bool notifyManager = false,
  }) async {
    final cleanId = int.tryParse(leadId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (cleanId == 0 || managerName.trim().isEmpty) return false;

    try {
      final uri = Uri.parse('$baseUrl/mobile/assign-lead');
      final payload = <String, dynamic>{
        'lead_id': cleanId,
        'manager_name': managerName.trim(),
        'notify_manager': notifyManager,
      };

      final response = await http
          .post(uri, headers: _headers, body: json.encode(payload))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error assigning lead on server: $e');
      return false;
    }
  }

  /// Create new lead on server (auto-syncs to TripCosmos CRM & FluentCRM)
  Future<Map<String, dynamic>?> createLead({
    required String name,
    required String phone,
    String? email,
    String? destination,
    String? budget,
    String? note,
    int pax = 2,
    String stage = 'new',
    String? nextFollowUpAt,
    String owner = 'Nishkarsh AI',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/create-lead');
      final body = json.encode({
        'name': name,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (destination != null && destination.isNotEmpty) 'destination': destination,
        if (budget != null && budget.isNotEmpty) 'budget': budget,
        if (note != null && note.isNotEmpty) 'note': note,
        'pax': pax,
        'stage': stage,
        if (nextFollowUpAt != null && nextFollowUpAt.isNotEmpty) 'next_follow_up_at': nextFollowUpAt,
        'owner': owner,
      });

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error creating lead on server: $e');
    }
    return null;
  }

  /// 10b. Real Server-Backed AI Call & Chat Summarizer
  Future<String?> summarizeCallWithAi({
    required String phone,
    String customerName = '',
    String circuit = '',
    int durationSeconds = 0,
    String notes = '',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/ai-summarize');
      final body = json.encode({
        'phone': phone,
        'customer_name': customerName,
        'circuit': circuit,
        'duration': durationSeconds,
        'notes': notes,
      });
      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['ok'] == true && data['summary'] != null) {
          return data['summary'].toString();
        }
      }
    } catch (e) {
      debugPrint('Error summarizing call with AI: $e');
    }
    return null;
  }

  /// 10c. Sync AI Agent Settings (Outbound Voice + 24/7 Receptionist) with WordPress
  Future<Map<String, dynamic>?> syncAiSettings({
    bool? outboundEnabled,
    bool? receptionistEnabled,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/ai-settings');
      if (outboundEnabled == null && receptionistEnabled == null) {
        final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          return _safeJsonDecode(response.body);
        }
      } else {
        final body = json.encode({
          if (outboundEnabled case final bool val) ...{
            'outbound_enabled': val,
            'outbound_ai_active': val,
          },
          if (receptionistEnabled case final bool val) ...{
            'receptionist_enabled': val,
            'receptionist_ai_active': val,
          },
        });
        final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          return _safeJsonDecode(response.body);
        }
      }
    } catch (e) {
      debugPrint('Error syncing AI settings: $e');
    }
    return null;
  }

  /// 10d. Master Automation Kill Switch & Sub-Automation Toggles (100% Human-Only Mode)
  Future<Map<String, dynamic>?> fetchAutomationSettings() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/automation-settings');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching automation settings: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateAutomationSettings({
    bool? disableAllAutomations,
    bool? firstGreetingEnabled,
    bool? autoReplyEnabled,
    bool? missedCallReplyEnabled,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/automation-settings');
      final body = json.encode({
        if (disableAllAutomations != null) 'disable_all_automations': disableAllAutomations ? '1' : '0',
        if (firstGreetingEnabled != null) 'whatsapp_first_greeting_enabled': firstGreetingEnabled ? '1' : '0',
        if (autoReplyEnabled != null) 'whatsapp_auto_reply': autoReplyEnabled ? '1' : '0',
        if (missedCallReplyEnabled != null) 'missed_call_auto_reply': missedCallReplyEnabled ? '1' : '0',
      });
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error updating automation settings: $e');
    }
    return null;
  }

  /// Fetch Authenticated Agent Profile & Dedicated AI Sales Co-Pilot (Aditi AI)
  Future<Map<String, dynamic>?> fetchAgentProfile() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/agent-profile');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['ok'] == true && data['agent'] is Map) {
          return Map<String, dynamic>.from(data['agent']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching agent profile: $e');
    }
    return null;
  }

  /// 11. Send WhatsApp Message via Central Evolution API
  Future<bool> sendWhatsAppMessage({
    required String phone,
    required String message,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/send-whatsapp');
      final body = json.encode({
        'phone': phone,
        'message': message,
      });

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        return data != null && (data['ok'] == true || data['success'] == true);
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp message via API: $e');
    }
    return false;
  }

  /// 11b. Delete Sent WhatsApp Message For Everyone
  Future<bool> deleteWhatsAppMessage({
    required String messageId,
    String? remoteJid,
    String? phone,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/whatsapp/delete-message');
      final body = json.encode({
        'message_id': messageId,
        'remote_jid': remoteJid ?? '',
        'phone': phone ?? '',
      });

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        return data != null && data['ok'] == true;
      }
    } catch (e) {
      debugPrint('Error deleting WhatsApp message: $e');
    }
    return false;
  }

  /// 11b. Check Live Evolution WhatsApp Gateway Connection State & Pairing QR
  Future<Map<String, dynamic>?> fetchEvolutionStatus() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/evolution-status');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['ok'] == true) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching Evolution status: $e');
    }
    return null;
  }

  /// 12. Initiate Multi-Mode Telephony Call (LiveKit WebRTC, GSM Bridge, SIP Trunk)
  Future<Map<String, dynamic>?> initiateTelephonyCall({
    required String phone,
    String customerName = 'Traveler',
    String reason = 'Spiritual Tour Follow-up',
    String? modeOverride,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/telephony-initiate');
      final payloadMap = <String, dynamic>{
        'phone': phone,
        'customer_name': customerName,
        'reason': reason,
      };
      if (modeOverride != null) {
        payloadMap['mode'] = modeOverride;
      }
      final body = json.encode(payloadMap);

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['ok'] == true) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('Error initiating telephony call via API: $e');
    }
    return null;
  }

  /// 13. Fetch Active Telephony Engine Configuration
  Future<Map<String, dynamic>?> getTelephonyConfig() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/telephony-config');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['ok'] == true) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('Error fetching telephony config: $e');
    }
    return null;
  }

  /// 14. Fetch Live Website Chatbot Conversations
  Future<List<Map<String, dynamic>>> fetchWebChats() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/web-chats?limit=30');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['ok'] == true && data['chats'] is List) {
          return (data['chats'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching web chats: $e');
    }
    return [];
  }

  /// 15. Fetch Full Message History for a Website Chatbot Conversation
  Future<Map<String, dynamic>?> fetchWebChatDetail(String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/web-chats/$sessionId');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['ok'] == true) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching web chat detail for $sessionId: $e');
    }
    return null;
  }

  /// 16. Human Agent Sends Live Reply to Website Chatbot Visitor
  Future<bool> sendWebChatReply({
    required String sessionId,
    required String message,
    String agentName = 'Santosh Yadav',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/web-chats/$sessionId/reply');
      final body = json.encode({
        'message': message,
        'agent_name': agentName,
      });

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        return data != null && data['ok'] == true;
      }
    } catch (e) {
      debugPrint('Error sending web chat reply to $sessionId: $e');
    }
    return false;
  }

  /// 17. Toggle AI vs Human Takeover for Website Chatbot Session
  Future<bool> toggleWebChatAi({
    required String sessionId,
    required bool enableAi,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/web-chats/$sessionId/ai');
      final body = json.encode({'enabled': enableAi});

      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        return data != null && data['ok'] == true;
      }
    } catch (e) {
      debugPrint('Error toggling web chat AI for $sessionId: $e');
    }
    return false;
  }

  /// 18. Fetch B2B Travel Partner Agencies Directory
  Future<Map<String, dynamic>?> fetchB2bAgencies({
    String search = '',
    String city = '',
    String status = '',
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
        if (city.isNotEmpty && city != 'All') 'city': city,
        if (status.isNotEmpty && status != 'all') 'status': status,
      };
      final uri = Uri.parse('$baseUrl/mobile/b2b-agencies').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['success'] == true) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching B2B agencies: $e');
    }
    return null;
  }

  /// 19. Send 1-Tap B2B WhatsApp Pitch to Agency
  Future<bool> sendB2bPitch({
    required int agencyId,
    String? customMessage,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/b2b-pitch');
      final body = json.encode({
        'agency_id': agencyId,
        if (customMessage != null && customMessage.isNotEmpty) 'message': customMessage,
      });
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        return data != null && data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error sending B2B pitch: $e');
    }
    return false;
  }

  /// 20. Sync B2B Agency to FluentCRM Funnel (List 8)
  Future<bool> syncB2bAgencyToCrm({required int agencyId}) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/b2b-sync-crm');
      final body = json.encode({'agency_id': agencyId});
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        return data != null && data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error syncing B2B agency to CRM: $e');
    }
    return false;
  }

  /// 21. Add New B2B Partner Agency from Mobile App
  Future<bool> addB2bAgency({
    required String name,
    required String city,
    required String phone,
    String email = '',
    String address = '',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/b2b-add-agency');
      final body = json.encode({
        'name': name,
        'city': city,
        'phone': phone,
        'email': email,
        'address': address,
      });
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        return data != null && data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error adding B2B agency: $e');
    }
    return false;
  }

  /// 22. Import B2B Agencies by City / Scheduled Rotation / Bulk CSV Paste from Mobile App
  Future<Map<String, dynamic>?> importB2bAgencies({
    String? city,
    bool runScheduledNow = false,
    String? rawList,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/b2b-import');
      final body = json.encode({
        if (city != null && city.isNotEmpty) 'city': city,
        if (runScheduledNow) 'run_scheduled_now': true,
        if (rawList != null && rawList.isNotEmpty) 'raw_list': rawList,
      });
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 18));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error importing B2B agencies: $e');
    }
    return null;
  }

  /// 23. Two-Way Sync All B2B Agencies with FluentCRM List 8 & Dev Deepawali Funnel
  Future<Map<String, dynamic>?> syncAllB2bAgenciesToCrm() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/b2b-sync-crm');
      final body = json.encode({'sync_all': true});
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error bulk syncing B2B agencies to FluentCRM: $e');
    }
    return null;
  }

  /// 23b. Launch Automated B2B Dev Deepawali Multi-Channel Campaign (WhatsApp + Brevo + FluentCRM Drip)
  Future<Map<String, dynamic>?> launchB2bBatchCampaign({
    String? city,
    int limit = 10,
    bool force = false,
    bool ignoreQuietHours = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/b2b-batch-pitch');
      final body = json.encode({
        if (city != null && city.isNotEmpty && city.toLowerCase() != 'all') 'city': city,
        'limit': limit,
        'force': force,
        'ignore_quiet_hours': ignoreQuietHours,
      });
      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error launching B2B batch campaign: $e');
    }
    return null;
  }

  /// 23c. Fetch Live Tour Package Catalog from WordPress (33+ Packages)
  Future<List<Map<String, dynamic>>> fetchCatalog() async {
    try {
      final uri = Uri.parse('$baseUrl/catalog');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final decoded = _safeJsonDecode(response.body);
        if (decoded is Map && decoded['items'] is List) {
          return List<Map<String, dynamic>>.from(
            (decoded['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching tour catalog: $e');
    }
    return [];
  }

  /// 23d. Official Quote & Booking Dispatch (stores in wp_tc_agent_quotes & wp_tc_agent_bookings)
  Future<Map<String, dynamic>?> dispatchQuote({
    required int contactId,
    required String destination,
    required String tier,
    required int pax,
    required double dealValue,
    required double advanceAmount,
    String? message,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/dispatch-quote');
      final body = json.encode({
        'contact_id': contactId,
        'destination': destination,
        'tier': tier,
        'pax': pax,
        'deal_value': dealValue,
        'advance_amount': advanceAmount,
        if (message != null && message.isNotEmpty) 'message': message,
      });
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error dispatching quote: $e');
    }
    return null;
  }

  /// 24. Real-Time Financials & Revenue Analytics
  Future<Map<String, dynamic>?> fetchFinancials() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/financials');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching financials: $e');
    }
    return null;
  }

  /// 25. Chauffeur & Vehicle Allocation WhatsApp Dispatch (Trip Sheet)
  Future<Map<String, dynamic>?> dispatchDriver({
    required int leadId,
    required String driverName,
    required String driverPhone,
    required String vehicleNumber,
    String vehicleModel = 'AC Sedan',
    String reportingTime = '',
    String pickupLocation = 'Varanasi',
    String dropLocation = '',
    double balanceAmount = 0.0,
    bool notifyCustomer = true,
    bool notifyDriver = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/dispatch-driver');
      final body = json.encode({
        'lead_id': leadId,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'vehicle_number': vehicleNumber,
        'vehicle_model': vehicleModel,
        'reporting_time': reportingTime,
        'pickup_location': pickupLocation,
        'drop_location': dropLocation,
        'balance_amount': balanceAmount,
        'notify_customer': notifyCustomer,
        'notify_driver': notifyDriver,
      });
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error dispatching driver: $e');
    }
    return null;
  }

  /// 26. Smart Incoming Caller-ID Live Lookup
  Future<Map<String, dynamic>?> lookupCaller(String phone) async {
    try {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final uri = Uri.parse('$baseUrl/mobile/caller-lookup?phone=$clean');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error looking up caller: $e');
    }
    return null;
  }

  /// 27. Audio Voice-Note Transcription & Field AI Lead Ingestion
  Future<Map<String, dynamic>?> submitVoiceNoteSummary({
    int? leadId,
    String? phone,
    required String transcript,
    String? stage,
    double? dealValue,
    String? followUpDate,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/voice-note-summary');
      final body = json.encode({
        if (leadId != null && leadId > 0) 'lead_id': leadId,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'transcript': transcript,
        if (stage != null && stage.isNotEmpty) 'stage': stage,
        if (dealValue != null && dealValue >= 0) 'deal_value': dealValue,
        if (followUpDate != null && followUpDate.isNotEmpty) 'follow_up_date': followUpDate,
      });
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error submitting voice note summary: $e');
    }
    return null;
  }

  /// 28. 1-Tap WhatsApp Advance UPI & Cashfree Payment Link Generator
  Future<Map<String, dynamic>?> generatePaymentLink({
    required int leadId,
    required double amount,
    String purpose = 'TripCosmos Pilgrimage Advance',
    bool sendWhatsApp = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/payments/generate-link');
      final body = json.encode({
        'lead_id': leadId,
        'amount': amount,
        'purpose': purpose,
        'send_whatsapp': sendWhatsApp,
      });
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error generating payment link: $e');
    }
    return null;
  }

  /// 29. Google Ads & Chatbot Conversion Telemetry
  Future<Map<String, dynamic>?> fetchGoogleAdsConversions() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/google-ads/conversions');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching Google Ads conversions: $e');
    }
    return null;
  }

  /// 30. Bank Statement Transactions & Cashflow Feed
  Future<Map<String, dynamic>?> fetchBankTransactions({
    String type = 'all',
    String status = 'all',
    int limit = 100,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/bank-statement/transactions?type=$type&status=$status&limit=$limit');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching bank transactions: $e');
    }
    return null;
  }

  /// 31. Bank Statement CSV Importer (SBI Format)
  Future<Map<String, dynamic>?> uploadBankStatement({
    required String csvData,
    String bankName = 'State Bank of India (SBI)',
    String accountNo = '',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/bank-statement/upload');
      final body = json.encode({
        'csv_data': csvData,
        'bank_name': bankName,
        'account_no': accountNo,
      });
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 25));
      if (response.statusCode < 500 && response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error uploading bank statement: $e');
    }
    return null;
  }

  /// 32. Reconcile Bank Transaction with Booking
  Future<Map<String, dynamic>?> reconcileBankTransaction({
    required int transactionId,
    int? bookingId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/bank-statement/reconcile');
      final payload = <String, dynamic>{'transaction_id': transactionId};
      if (bookingId != null) {
        payload['booking_id'] = bookingId;
      }
      final body = json.encode(payload);
      final response = await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 10));
      if (response.statusCode < 500 && response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error reconciling bank transaction: $e');
    }
    return null;
  }

  /// 33. Zoho Books / Invoice Summary & Invoices List
  Future<Map<String, dynamic>?> fetchZohoSummary() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/zoho/summary');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (response.statusCode < 500 && response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching Zoho summary: $e');
    }
    return null;
  }

  /// 34. Sync Zoho Books Invoices
  Future<Map<String, dynamic>?> syncZohoInvoices() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/zoho/sync');
      final response = await http.post(uri, headers: _headers).timeout(const Duration(seconds: 20));
      if (response.statusCode < 500 && response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error syncing Zoho: $e');
    }
    return null;
  }

  /// 34a. Fetch Zoho Books Safe Config Status
  Future<Map<String, dynamic>?> fetchZohoConfig() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/zoho/config');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode < 500 && response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching Zoho config: $e');
    }
    return null;
  }

  /// 34b. Connect & Save Zoho Books Credentials (In-App)
  Future<Map<String, dynamic>?> connectZoho({
    required String clientId,
    required String clientSecret,
    required String refreshToken,
    required String orgId,
    String datacenter = 'zoho.in',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/zoho/connect');
      final payload = {
        'client_id': clientId.trim(),
        'client_secret': clientSecret.trim(),
        'refresh_token': refreshToken.trim(),
        'org_id': orgId.trim(),
        'datacenter': datacenter.trim(),
      };
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 25));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error connecting Zoho: $e');
    }
    return null;
  }

  /// 34c. Google Ads Live Campaign & Ad Spend Sync
  Future<Map<String, dynamic>?> syncGoogleAds() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/google-ads/sync');
      final response = await http.post(uri, headers: _headers).timeout(const Duration(seconds: 25));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error syncing Google Ads: $e');
    }
    return null;
  }

  /// 34d. Fetch Customer Margins & Unit Economics
  Future<Map<String, dynamic>?> fetchCustomerMargins() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/customer-margins');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 25));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching customer margins: $e');
    }
    return null;
  }

  /// 34e. Add Customer Direct Expense (Hotel, Cab, Aarti/Boat, Guide)
  Future<Map<String, dynamic>?> addCustomerExpense({
    required String invoiceNo,
    String? customerName,
    required String category,
    required double amount,
    String? vendorName,
    String? expenseDate,
    String paymentMethod = 'bank_debit',
    int? bankTxnId,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/customer-expenses/add');
      final payload = {
        'invoice_number': invoiceNo,
        if (customerName != null) 'customer_name': customerName,
        'category': category,
        'amount': amount,
        if (vendorName != null) 'vendor_name': vendorName,
        if (expenseDate != null) 'expense_date': expenseDate,
        'payment_method': paymentMethod,
        if (bankTxnId != null) 'bank_txn_id': bankTxnId,
        if (notes != null) 'notes': notes,
      };
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 20));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error adding customer expense: $e');
    }
    return null;
  }

  /// 34f. Link Bank Debit Transaction directly to Customer Invoice
  Future<Map<String, dynamic>?> linkDebitToInvoice({
    required int transactionId,
    required String invoiceNo,
    String? customerName,
    String category = 'cab',
    String? vendorName,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/customer-expenses/link-debit');
      final payload = {
        'transaction_id': transactionId,
        'invoice_number': invoiceNo,
        if (customerName != null) 'customer_name': customerName,
        'category': category,
        if (vendorName != null) 'vendor_name': vendorName,
        if (notes != null) 'notes': notes,
      };
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 20));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error linking debit to invoice: $e');
    }
    return null;
  }

  /// 34g. Delete Customer Expense
  Future<Map<String, dynamic>?> deleteCustomerExpense(int expenseId) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/customer-expenses/delete');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({'id': expenseId}),
      ).timeout(const Duration(seconds: 15));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error deleting customer expense: $e');
    }
    return null;
  }

  /// 34d. Fetch Google Ads Configuration & Connection Status
  Future<Map<String, dynamic>?> fetchGoogleAdsConfig() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/google-ads/config');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching Google Ads config: $e');
    }
    return null;
  }

  /// 34e. Upload Offline Conversion (OCT) to Google Ads for Target ROAS
  Future<Map<String, dynamic>?> uploadGoogleAdsConversion({
    required String gclid,
    required double value,
    String? orderId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/google-ads/upload-conversion');
      final payload = {
        'gclid': gclid.trim(),
        'value': value,
        if (orderId != null) 'order_id': orderId.trim(),
      };
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 20));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error uploading Google Ads OCT: $e');
    }
    return null;
  }

  /// 35. 1-Click Google Sign-In Authentication
  Future<Map<String, dynamic>?> loginWithGoogle({
    required String email,
    String? idToken,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/auth/google');
      final payload = <String, dynamic>{'email': email};
      if (idToken != null) payload['id_token'] = idToken;
      if (name != null) payload['name'] = name;
      if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
      final body = json.encode(payload);
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['token'] != null) {
          await setApiToken(data['token'].toString());
        }
        return data;
      } else {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error with Google login: $e');
    }
    return null;
  }

  /// 36. WordPress Credentials Login
  Future<Map<String, dynamic>?> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/auth/login');
      final body = json.encode({
        'username': username,
        'password': password,
      });
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['token'] != null) {
          await setApiToken(data['token'].toString());
        }
        return data;
      } else {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error logging in with credentials: $e');
    }
    return null;
  }

  /// 37. Fetch Authenticated User Profile & Role
  Future<Map<String, dynamic>?> fetchMe() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/auth/me');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching me profile: $e');
    }
    return null;
  }

  /// 38. Payroll: Fetch Employees Directory
  Future<Map<String, dynamic>?> fetchPayrollEmployees() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/payroll/employees');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching payroll employees: $e');
    }
    return null;
  }

  /// 39. Payroll: Save or Update Employee
  Future<Map<String, dynamic>?> savePayrollEmployee(Map<String, dynamic> employeeData) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/payroll/employees');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(employeeData),
      ).timeout(const Duration(seconds: 15));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error saving payroll employee: $e');
    }
    return null;
  }

  /// 40. Payroll: Calculate Monthly Breakdown
  Future<Map<String, dynamic>?> calculatePayroll({
    String? month,
    Map<String, dynamic>? attendance,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/payroll/calculate');
      final payload = {
        if (month != null) 'month': month,
        if (attendance != null) 'attendance': attendance,
      };
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 20));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error calculating payroll: $e');
    }
    return null;
  }

  /// 41. Payroll: Generate & Dispatch Payslip via WhatsApp
  Future<Map<String, dynamic>?> dispatchPayrollPayslip({
    required String employeeId,
    String? month,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/payroll/dispatch-payslip');
      final payload = {
        'employee_id': employeeId,
        if (month != null) 'month': month,
      };
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 20));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error dispatching payslip: $e');
    }
    return null;
  }

  /// 42. Payroll: Sync Monthly Payroll Manual Journal to Zoho Books (Free Tier)
  Future<Map<String, dynamic>?> syncPayrollToZoho({String? month}) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/payroll/sync-zoho');
      final payload = {
        if (month != null) 'month': month,
      };
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 25));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error syncing payroll to Zoho: $e');
    }
    return null;
  }

  /// 43. Master AI Assistant: Conversational Operations & Intelligence Query
  Future<Map<String, dynamic>?> queryMasterAssistant({
    required String message,
    List<Map<String, String>>? history,
    Map<String, dynamic>? context,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/master-assistant/chat');
      final payload = {
        'message': message.trim(),
        if (history != null) 'history': history,
        if (context != null) 'context': context,
      };
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 40));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error querying Master AI Assistant: $e');
    }
    return null;
  }

  /// 44. Master AI Assistant: 1-Click Morning Daily Operations Briefing
  Future<Map<String, dynamic>?> fetchMasterAssistantBriefing() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/master-assistant/briefing');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 40));
      if (response.body.isNotEmpty) {
        return _safeJsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching Master AI Briefing: $e');
    }
    return null;
  }

  /// 45. Fetch Active Team & Staff Directory for Dynamic Lead Assignment
  Future<List<Map<String, String>>> fetchTeamMembers() async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/me');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['team'] is List) {
          final List<Map<String, String>> members = [];
          for (final item in data['team']) {
            if (item is Map) {
              final name = (item['name'] ?? '').toString().trim();
              if (name.isNotEmpty) {
                final role = (item['role'] ?? 'Sales Agent').toString();
                final cleanRole = role.replaceAll('tc_', '').replaceAll('_', ' ').trim();
                final formattedRole = cleanRole.isNotEmpty
                    ? cleanRole[0].toUpperCase() + cleanRole.substring(1)
                    : 'Sales Agent';
                final parts = name.split(' ');
                final initials = parts.map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase();
                members.add({
                  'name': name,
                  'initials': initials.isEmpty ? 'AG' : initials,
                  'role': formattedRole,
                  'id': (item['id'] ?? '').toString(),
                });
              }
            }
          }
          return members;
        }
      }
    } catch (e) {
      debugPrint('Error fetching team members: $e');
    }
    return [];
  }
}


