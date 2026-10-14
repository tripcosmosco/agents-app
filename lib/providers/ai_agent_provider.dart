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

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.provider,
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

  AiAgentProvider({required this.apiService}) {
    _personas = AiAgentPersona.defaultTravelPersonas();
    _loadPreferences();
    _initializePlayground();
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
    if (serverSettings != null && serverSettings['ok'] == true) {
      if (serverSettings['outbound_enabled'] is bool) {
        _isOutboundAgentActive = serverSettings['outbound_enabled'] as bool;
        await StorageService.setAiOutboundActive(_isOutboundAgentActive);
      }
      if (serverSettings['receptionist_enabled'] is bool) {
        _isReceptionistActive = serverSettings['receptionist_enabled'] as bool;
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

    final reply = await apiService.queryVoiceRag(transcript: promptContext);

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
}
