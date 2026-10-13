import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/call_log_model.dart';
import '../models/event_model.dart';
import '../models/lead_model.dart';
import '../models/quote_model.dart';

class ApiService {
  String _baseUrl;
  String? _apiToken;

  ApiService({String? baseUrl, String? apiToken})
      : _baseUrl = baseUrl ?? AppConstants.defaultApiBaseUrl,
        _apiToken = apiToken ?? AppConstants.defaultMobileToken;

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
    if (_apiToken != null && _apiToken!.isNotEmpty) 'X-Mobile-Token': _apiToken!,
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
      final savedToken = prefs.getString('tc_mobile_api_token');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = savedUrl;
      }
      if (savedToken != null && savedToken.isNotEmpty) {
        _apiToken = savedToken;
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
      await prefs.setString('tc_mobile_api_token', newApiToken.trim());
      _baseUrl = newBaseUrl.trim();
      _apiToken = newApiToken.trim();
      return true;
    } catch (e) {
      debugPrint('Error saving API config: $e');
      return false;
    }
  }

  /// Disconnect workspace by removing API token
  Future<bool> clearConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tc_mobile_api_token');
      _apiToken = '';
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
          return List<Map<String, dynamic>>.from(data['calls']);
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
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/voice/query-rag');
      final body = json.encode({
        'transcript': transcript,
        'session_id': sessionId,
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
  Future<Map<String, dynamic>?> lookupCallerId(String phone) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/mobile/caller-id?phone=${Uri.encodeComponent(phone)}',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body);
        if (data != null && data['ok'] == true) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Error looking up caller ID: $e');
    }
    return null;
  }

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
    if (res != null && res['events'] is List<EventModel>) {
      return res['events'] as List<EventModel>;
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
      return List<Map<String, dynamic>>.from(data['leads']);
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
          if (outboundEnabled case final bool val) 'outbound_enabled': val,
          if (receptionistEnabled case final bool val) 'receptionist_enabled': val,
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
          return List<Map<String, dynamic>>.from(data['chats']);
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
}

