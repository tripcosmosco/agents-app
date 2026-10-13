import 'package:flutter/material.dart';

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

  List<ChatMessage> _playgroundMessages = [];
  List<ChatMessage> get playgroundMessages => _playgroundMessages;

  bool _isQueryingRag = false;
  bool get isQueryingRag => _isQueryingRag;

  AiAgentProvider({required this.apiService}) {
    _loadPreferences();
    _initializePlayground();
  }

  Future<void> _loadPreferences() async {
    _isOutboundAgentActive = await StorageService.getAiOutboundActive();
    _isReceptionistActive = await StorageService.getAiReceptionistActive();
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

  void _initializePlayground() {
    _playgroundMessages = [
      ChatMessage(
        text: 'Namaste! I am your AI Voice & Sales Agent powered by TripCosmos Local RAG Bot 155464. Ask me any Varanasi or pilgrimage tour question to test live spoken responses!',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        provider: 'TripCosmos AI Bot 155464',
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

  /// Send test question to live AI Puffer RAG Bot 155464
  Future<void> testRagQuery(String question) async {
    if (question.trim().isEmpty) return;

    final userMsg = ChatMessage(
      text: question.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _playgroundMessages.add(userMsg);
    _isQueryingRag = true;
    notifyListeners();

    final reply = await apiService.queryVoiceRag(transcript: question);

    final aiMsg = ChatMessage(
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
      provider: 'Local RAG Bot 155464 (TripCosmos AI)',
    );
    _playgroundMessages.add(aiMsg);
    _isQueryingRag = false;
    notifyListeners();
  }

  void clearPlayground() {
    _initializePlayground();
  }
}
