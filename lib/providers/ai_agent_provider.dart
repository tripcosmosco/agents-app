import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/ai_agent_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? provider;
  final List<String>? suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.provider,
    this.suggestions,
  });
}

class AiAgentProvider extends ChangeNotifier {
  final ApiService apiService;

  bool _isOutboundAgentActive = true;
  bool get isOutboundAgentActive => _isOutboundAgentActive;

  bool _isReceptionistActive = true;
  bool get isReceptionistActive => _isReceptionistActive;

  int _autoCallsTriggeredToday = 0;
  int get autoCallsTriggeredToday => _autoCallsTriggeredToday;

  int _aiQualifiedLeadsToday = 0;
  int get aiQualifiedLeadsToday => _aiQualifiedLeadsToday;

  List<AiAgentPersona> _personas = [];
  List<AiAgentPersona> get personas => _personas;

  String _selectedPersonaId = 'agent_nishkarsh_ai';
  String get selectedPersonaId => _selectedPersonaId;

  AiAgentPersona get selectedPersona {
    return _personas.firstWhere(
      (p) => p.id == _selectedPersonaId,
      orElse: () => _personas.isNotEmpty ? _personas.first : AiAgentPersona.defaultTravelPersonas().first,
    );
  }

  List<ChatMessage> _playgroundMessages = [];
  List<ChatMessage> get playgroundMessages => _playgroundMessages;

  bool _isQueryingRag = false;
  bool get isQueryingRag => _isQueryingRag;

  List<ChatMessage> _masterAssistantMessages = [];
  List<ChatMessage> get masterAssistantMessages => _masterAssistantMessages;

  bool _isQueryingMasterAi = false;
  bool get isQueryingMasterAi => _isQueryingMasterAi;

  String? _masterAiError;
  String? get masterAiError => _masterAiError;

  AiAgentProvider({required this.apiService}) {
    _personas = AiAgentPersona.defaultTravelPersonas();
    _loadPreferences();
    _initializePlayground();
    _initializeMasterAssistant();
  }

  Future<void> _loadPreferences() async {
    _isOutboundAgentActive = await StorageService.getAiOutboundActive();
    _isReceptionistActive = await StorageService.getAiReceptionistActive();
    
    // Load custom personas from storage if saved
    final savedPersonasJson = await StorageService.getString('custom_ai_personas');
    if (savedPersonasJson != null && savedPersonasJson.isNotEmpty) {
      try {
        final decoded = json.decode(savedPersonasJson);
        if (decoded is List) {
          final loaded = decoded.map((e) => AiAgentPersona.fromJson(Map<String, dynamic>.from(e))).toList();
          final defaults = AiAgentPersona.defaultTravelPersonas();
          final existingIds = loaded.map((e) => e.id).toSet();
          for (final d in defaults) {
            if (!existingIds.contains(d.id)) {
              loaded.add(d);
            }
          }
          if (loaded.isNotEmpty) {
            _personas = loaded;
          }
        }
      } catch (e) {
        debugPrint('Error loading saved personas: $e');
      }
    }

    notifyListeners();

    final serverSettings = await apiService.syncAiSettings();
    if (serverSettings != null && (serverSettings['ok'] == true || serverSettings['success'] == true)) {
      final outbound = serverSettings['outbound_enabled'] ?? serverSettings['outbound_ai_active'];
      if (outbound is bool) {
        _isOutboundAgentActive = outbound;
        await StorageService.setAiOutboundActive(_isOutboundAgentActive);
      }
      final receptionist = serverSettings['receptionist_enabled'] ?? serverSettings['receptionist_ai_active'];
      if (receptionist is bool) {
        _isReceptionistActive = receptionist;
        await StorageService.setAiReceptionistActive(_isReceptionistActive);
      }
      notifyListeners();
    }
  }

  Future<void> _persistPersonas() async {
    try {
      final jsonStr = json.encode(_personas.map((p) => p.toJson()).toList());
      await StorageService.setString('custom_ai_personas', jsonStr);
    } catch (e) {
      debugPrint('Error persisting personas: $e');
    }
  }

  void selectPersona(String personaId) {
    if (_selectedPersonaId != personaId) {
      _selectedPersonaId = personaId;
      _initializePlayground();
      notifyListeners();
    }
  }

  void toggleSkill(String personaId, String skillId, bool isEnabled) {
    final pIdx = _personas.indexWhere((p) => p.id == personaId);
    if (pIdx == -1) return;

    final target = _personas[pIdx];
    final updatedSkills = target.skills.map((s) {
      if (s.id == skillId) {
        return s.copyWith(isEnabled: isEnabled);
      }
      return s;
    }).toList();

    _personas[pIdx] = target.copyWith(skills: updatedSkills);
    notifyListeners();
    _persistPersonas();
  }

  void updatePersona(AiAgentPersona updated) {
    final index = _personas.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _personas[index] = updated;
    } else {
      _personas.add(updated);
    }
    notifyListeners();
    _persistPersonas();
  }

  void addPersona(AiAgentPersona newPersona) {
    _personas.add(newPersona);
    _selectedPersonaId = newPersona.id;
    notifyListeners();
    _persistPersonas();
  }

  void deletePersona(String id) {
    _personas.removeWhere((p) => p.id == id);
    if (_personas.isEmpty) {
      _personas = AiAgentPersona.defaultTravelPersonas();
    }
    if (_selectedPersonaId == id) {
      _selectedPersonaId = _personas.first.id;
    }
    notifyListeners();
    _persistPersonas();
  }

  void incrementAutoCalls() {
    _autoCallsTriggeredToday++;
    notifyListeners();
  }

  void incrementAiQualified() {
    _aiQualifiedLeadsToday++;
    notifyListeners();
  }

  void updateStats({int? autoCalls, int? qualifiedLeads}) {
    if (autoCalls != null) _autoCallsTriggeredToday = autoCalls;
    if (qualifiedLeads != null) _aiQualifiedLeadsToday = qualifiedLeads;
    notifyListeners();
  }

  void _initializePlayground() {
    final persona = selectedPersona;
    final activeSkillsCount = persona.skills.where((s) => s.isEnabled).length;
    _playgroundMessages = [
      ChatMessage(
        text: 'Namaste! I am ${persona.name} (${persona.title}). I am live with $activeSkillsCount active skills for circuits: ${persona.circuits.join(', ')}. Test my voice or chat responses here!',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        provider: '${persona.name} • ${persona.voiceName}',
      ),
    ];
    notifyListeners();
  }

  Future<void> toggleOutboundAgent(bool active) async {
    _isOutboundAgentActive = active;
    await StorageService.setAiOutboundActive(active);
    notifyListeners();
    await apiService.syncAiSettings(outboundEnabled: active);
  }

  Future<void> toggleReceptionist(bool active) async {
    _isReceptionistActive = active;
    await StorageService.setAiReceptionistActive(active);
    notifyListeners();
    await apiService.syncAiSettings(receptionistEnabled: active);
  }

  /// Send test question to live AI Puffer RAG Bot with active Persona Context
  Future<void> testRagQuery(String question) async {
    if (question.trim().isEmpty) return;

    final persona = selectedPersona;
    final userMsg = ChatMessage(
      text: question.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _playgroundMessages.add(userMsg);
    _isQueryingRag = true;
    notifyListeners();

    final promptContext = 'System Role: ${persona.systemPrompt}\nActive Skills: ${persona.skills.where((s) => s.isEnabled).map((s) => s.name).join(', ')}\nUser Question: ${question.trim()}';

    final agentSlug = persona.id.replaceAll('agent_', '').replaceAll('_', '-');
    final reply = await apiService.queryVoiceRag(
      transcript: promptContext,
      agentSlug: agentSlug,
    );

    final aiMsg = ChatMessage(
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
      provider: '${persona.name} (${persona.tone})',
    );
    _playgroundMessages.add(aiMsg);
    _isQueryingRag = false;
    notifyListeners();
  }

  void clearPlayground() {
    _initializePlayground();
  }

  void _initializeMasterAssistant() {
    _masterAssistantMessages = [
      ChatMessage(
        text: 'Namaste! I am Garuda Master AI, your Chief Operations & Sales Intelligence Co-Pilot for TripCosmos.co.\n\nI have real-time visibility across CRM leads, wholesale B2B travel partners, staff payroll, bank balances, and dynamic tour tariffs. How can I assist you right now?',
        isUser: false,
        timestamp: DateTime.now(),
        provider: 'Garuda Master AI (Gateway)',
        suggestions: const [
          '🌅 Daily Operations Briefing',
          '🔥 Hot Leads Triaging',
          '💰 Financial & Payroll Status',
          '🚗 Cab Tariff Calculator',
          '🤝 B2B Wholesale Intel',
        ],
      ),
    ];
    notifyListeners();
  }

  /// Send a conversational query to Master AI Assistant with multi-turn history and business context
  Future<void> sendMasterAiQuery(String question, {Map<String, dynamic>? context}) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    final userMsg = ChatMessage(
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _masterAssistantMessages.add(userMsg);
    _isQueryingMasterAi = true;
    _masterAiError = null;
    notifyListeners();

    // Prepare history (last 6 messages)
    final history = _masterAssistantMessages
        .take(_masterAssistantMessages.length - 1)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    try {
      final res = await apiService.queryMasterAssistant(
        message: trimmed,
        history: history,
        context: context,
      );

      if (res != null && (res['ok'] == true || res['success'] == true)) {
        final replyText = res['reply']?.toString() ?? 'Operations status verified.';
        final provider = res['provider']?.toString() ?? 'Gateway';
        final rawSuggestions = (res['suggestions'] as List?)?.map((s) => s.toString()).toList();

        final aiMsg = ChatMessage(
          text: replyText,
          isUser: false,
          timestamp: DateTime.now(),
          provider: 'Garuda Master AI ($provider)',
          suggestions: rawSuggestions,
        );
        _masterAssistantMessages.add(aiMsg);
      } else {
        _masterAiError = res?['error']?.toString() ?? 'Error receiving response from Master AI';
        _masterAssistantMessages.add(
          ChatMessage(
            text: 'I encountered an operational issue: ${_masterAiError ?? "Please verify connection."}',
            isUser: false,
            timestamp: DateTime.now(),
            provider: 'System Error',
          ),
        );
      }
    } catch (e) {
      _masterAiError = 'Connection error: $e';
      _masterAssistantMessages.add(
        ChatMessage(
          text: 'Unable to reach Master AI router: $e',
          isUser: false,
          timestamp: DateTime.now(),
          provider: 'System Error',
        ),
      );
    } finally {
      _isQueryingMasterAi = false;
      notifyListeners();
    }
  }

  /// 1-Click Morning Operations & Sales Briefing
  Future<void> requestMasterBriefing() async {
    _isQueryingMasterAi = true;
    _masterAiError = null;
    _masterAssistantMessages.add(
      ChatMessage(
        text: '🌅 Daily Operations Briefing',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    try {
      final res = await apiService.fetchMasterAssistantBriefing();
      if (res != null && (res['ok'] == true || res['success'] == true)) {
        final replyText = res['reply']?.toString() ?? 'Morning briefing compiled.';
        final provider = res['provider']?.toString() ?? 'Gateway';
        final rawSuggestions = (res['suggestions'] as List?)?.map((s) => s.toString()).toList();

        _masterAssistantMessages.add(
          ChatMessage(
            text: replyText,
            isUser: false,
            timestamp: DateTime.now(),
            provider: 'Garuda Master AI ($provider)',
            suggestions: rawSuggestions,
          ),
        );
      } else {
        final errorMsg = res?['error'] ?? res?['message'] ?? res?['reply'] ?? (res == null ? 'Network connection timeout. Please retry.' : 'Briefing temporarily unavailable.');
        _masterAssistantMessages.add(
          ChatMessage(
            text: 'Could not generate briefing: $errorMsg',
            isUser: false,
            timestamp: DateTime.now(),
            provider: 'System Error',
          ),
        );
      }
    } catch (e) {
      _masterAssistantMessages.add(
        ChatMessage(
          text: 'Briefing request failed: $e',
          isUser: false,
          timestamp: DateTime.now(),
          provider: 'System Error',
        ),
      );
    } finally {
      _isQueryingMasterAi = false;
      notifyListeners();
    }
  }

  void clearMasterAssistant() {
    _initializeMasterAssistant();
  }
}
