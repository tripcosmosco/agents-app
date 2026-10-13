import 'package:flutter/material.dart';
import '../models/whatsapp_thread_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class WhatsAppProvider extends ChangeNotifier {
  final ApiService apiService;

  List<WhatsAppThread> _threads = [];
  List<WhatsAppThread> get threads => _threads;

  String? _selectedThreadId;
  String? get selectedThreadId => _selectedThreadId;

  String _filter = 'all'; // 'all', 'whatsapp', 'unread', 'new', 'quoted', 'followup', 'b2b', 'mine', 'ai_active'
  String get filter => _filter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  bool _evolutionOnline = true;
  bool get evolutionOnline => _evolutionOnline;

  String _currentAgentName = '';
  String get currentAgentName => _currentAgentName;

  int get totalUnreadCount => _threads.fold(0, (sum, th) => sum + th.unreadCount);
  int get whatsappActiveCount => _threads.where((th) => th.hasWhatsappChat || th.sourceChannel == 'whatsapp').length;
  int get followUpDueCount => _threads.where((th) => th.nextFollowUpAt != null).length;
  int get b2bThreadsCount => _threads.where((th) => isB2bThread(th)).length;

  WhatsAppProvider({required this.apiService}) {
    _initAgentName();
    fetchThreadsFromServer();
  }

  Future<void> _initAgentName() async {
    final saved = await StorageService.getAgentName();
    if (saved.isNotEmpty && saved != 'Executive Agent') {
      _currentAgentName = saved;
      notifyListeners();
    }
  }

  bool isB2bThread(WhatsAppThread th) {
    if (th.isB2b || th.sourceChannel == 'b2b' || th.stage == 'b2b_partner') return true;
    final lowerName = th.customerName.toLowerCase();
    final lowerCircuit = th.circuit.toLowerCase();
    return lowerCircuit.contains('b2b') ||
        lowerName.contains('b2b') ||
        lowerName.contains('travels') ||
        lowerName.contains('holidays') ||
        lowerName.contains('tours') ||
        lowerName.contains('agency');
  }

  List<WhatsAppThread> get filteredThreads {
    return _threads.where((th) {
      final matchesSearch = _searchQuery.isEmpty ||
          th.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          th.customerPhone.contains(_searchQuery) ||
          th.circuit.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          th.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _filter == 'all' ||
          (_filter == 'whatsapp' && (th.hasWhatsappChat || th.sourceChannel == 'whatsapp')) ||
          (_filter == 'unread' && th.unreadCount > 0) ||
          (_filter == 'new' && (th.stage == 'new' || th.stage.isEmpty)) ||
          (_filter == 'quoted' && (th.stage == 'quote_sent' || th.stage == 'qualified' || th.dealValue > 0)) ||
          (_filter == 'followup' && th.nextFollowUpAt != null) ||
          (_filter == 'b2b' && isB2bThread(th)) ||
          (_filter == 'mine' && th.assignedAgent.toLowerCase() == _currentAgentName.toLowerCase()) ||
          (_filter == 'ai_active' && th.isAiAssisted);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  WhatsAppThread openOrCreateAgencyThread({
    required String agencyName,
    required String phone,
    required String city,
  }) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    final existingIdx = _threads.indexWhere((t) {
      final tClean = t.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
      return suffix.isNotEmpty && tClean.endsWith(suffix);
    });

    if (existingIdx != -1) {
      _selectedThreadId = _threads[existingIdx].id;
      notifyListeners();
      loadThreadMessages(_threads[existingIdx].id);
      return _threads[existingIdx];
    }

    final newThread = WhatsAppThread(
      id: 'th_b2b_$suffix',
      customerPhone: phone,
      customerName: agencyName.contains('B2B') ? agencyName : '$agencyName (B2B)',
      circuit: '🏢 B2B DMC • $city',
      assignedAgent: _currentAgentName,
      isAiAssisted: false,
      unreadCount: 0,
      lastMessage: 'B2B Partner Channel opened for $agencyName ($city)',
      lastMessageTime: DateTime.now(),
      stage: 'b2b_partner',
      sourceChannel: 'b2b',
      isB2b: true,
      messages: [
        WhatsAppMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          text: '🏢 B2B Partner Desk initialized for $agencyName ($city). Use 1-Tap B2B Canned Replies or White-Label Quote below.',
          isFromCustomer: false,
          timestamp: DateTime.now(),
          isInternalNote: true,
          authorName: 'System',
          channel: 'note',
        ),
      ],
    );

    _threads.insert(0, newThread);
    _selectedThreadId = newThread.id;
    notifyListeners();
    loadThreadMessages(newThread.id);
    return newThread;
  }

  WhatsAppThread? get activeThread {
    if (_threads.isEmpty) return null;
    if (_selectedThreadId == null) {
      return _threads.first;
    }
    return _threads.firstWhere(
      (th) => th.id == _selectedThreadId,
      orElse: () => _threads.first,
    );
  }

  void selectThread(String threadId) {
    _selectedThreadId = threadId;
    final index = _threads.indexWhere((th) => th.id == threadId);
    if (index != -1 && _threads[index].unreadCount > 0) {
      _threads[index] = _threads[index].copyWith(unreadCount: 0);
    }
    notifyListeners();
    loadThreadMessages(threadId);
  }

  void setFilter(String filterKey) {
    _filter = filterKey;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCurrentAgent(String agentName) {
    _currentAgentName = agentName;
    notifyListeners();
  }

  Future<void> toggleAiTakeover(String threadId) async {
    final index = _threads.indexWhere((th) => th.id == threadId);
    if (index != -1) {
      final th = _threads[index];
      final nextState = !th.isAiAssisted;
      _threads[index] = th.copyWith(isAiAssisted: nextState);
      notifyListeners();

      await apiService.updateLead(
        leadId: th.contactId > 0 ? th.contactId.toString() : th.id,
        phone: th.customerPhone,
        name: th.customerName,
        isAiActive: nextState,
      );
    }
  }

  Future<void> assignThreadAgent(String threadId, String newAgent) async {
    final index = _threads.indexWhere((th) => th.id == threadId);
    if (index != -1) {
      final th = _threads[index];
      _threads[index] = th.copyWith(assignedAgent: newAgent);
      notifyListeners();

      await apiService.updateLead(
        leadId: th.contactId > 0 ? th.contactId.toString() : th.id,
        phone: th.customerPhone,
        name: th.customerName,
        owner: newAgent,
      );
    }
  }

  Future<void> updateThreadName(String threadId, String newName) async {
    final index = _threads.indexWhere((th) => th.id == threadId);
    if (index != -1 && newName.trim().isNotEmpty) {
      final th = _threads[index];
      _threads[index] = th.copyWith(customerName: newName.trim());
      notifyListeners();

      await apiService.updateLead(
        leadId: th.contactId > 0 ? th.contactId.toString() : th.id,
        phone: th.customerPhone,
        name: newName.trim(),
      );
    }
  }

  Future<void> updateThreadStage(String threadId, String newStage, {double? dealValue}) async {
    final index = _threads.indexWhere((th) => th.id == threadId);
    if (index != -1) {
      final th = _threads[index];
      _threads[index] = th.copyWith(
        stage: newStage,
        dealValue: dealValue ?? th.dealValue,
      );
      notifyListeners();

      await apiService.updateLead(
        leadId: th.contactId > 0 ? th.contactId.toString() : th.id,
        phone: th.customerPhone,
        name: th.customerName,
        stage: newStage,
        dealValue: dealValue,
      );
    }
  }

  Future<void> scheduleThreadFollowUp(String threadId, DateTime? followUpAt) async {
    final index = _threads.indexWhere((th) => th.id == threadId);
    if (index != -1) {
      final th = _threads[index];
      _threads[index] = th.copyWith(
        nextFollowUpAt: followUpAt,
        clearFollowUp: followUpAt == null,
      );
      notifyListeners();

      await apiService.updateLead(
        leadId: th.contactId > 0 ? th.contactId.toString() : th.id,
        phone: th.customerPhone,
        name: th.customerName,
        nextFollowUpAt: followUpAt != null ? followUpAt.toIso8601String() : '',
      );
    }
  }

  Future<bool> sendMessage(String threadId, String text) async {
    final index = _threads.indexWhere((th) => th.id == threadId);
    if (index == -1 || text.trim().isEmpty) return false;

    final targetThread = _threads[index];
    final tempId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final newMsg = WhatsAppMessage(
      id: tempId,
      text: text.trim(),
      isFromCustomer: false,
      timestamp: DateTime.now(),
      status: 'sent',
      channel: 'whatsapp',
    );

    final updatedMessages = List<WhatsAppMessage>.from(targetThread.messages)..add(newMsg);
    _threads[index] = targetThread.copyWith(
      lastMessage: text.trim(),
      lastMessageTime: DateTime.now(),
      lastMessageFromMe: true,
      lastMessageStatus: 'sent',
      timeAgo: 'Just now',
      hasWhatsappChat: true,
      messages: updatedMessages,
    );
    notifyListeners();

    final ok = await apiService.sendWhatsAppMessage(
      phone: targetThread.customerPhone,
      message: text.trim(),
    );

    final updatedIdx = _threads.indexWhere((th) => th.id == threadId);
    if (updatedIdx != -1) {
      final msgs = List<WhatsAppMessage>.from(_threads[updatedIdx].messages);
      final msgIdx = msgs.indexWhere((m) => m.id == tempId);
      if (msgIdx != -1) {
        msgs[msgIdx] = WhatsAppMessage(
          id: tempId,
          text: text.trim(),
          isFromCustomer: false,
          timestamp: msgs[msgIdx].timestamp,
          status: ok ? 'delivered' : 'failed',
          channel: 'whatsapp',
        );
        _threads[updatedIdx] = _threads[updatedIdx].copyWith(
          messages: msgs,
          lastMessageStatus: ok ? 'delivered' : 'failed',
        );
        notifyListeners();
      }
    }
    return ok;
  }

  Future<void> addInternalNote(String threadId, String noteText) async {
    final index = _threads.indexWhere((th) => th.id == threadId);
    if (index == -1 || noteText.trim().isEmpty) return;

    final targetThread = _threads[index];
    final noteMsg = WhatsAppMessage(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      text: noteText.trim(),
      isFromCustomer: false,
      timestamp: DateTime.now(),
      status: 'saved',
      isInternalNote: true,
      authorName: _currentAgentName,
      channel: 'note',
    );

    final updatedMessages = List<WhatsAppMessage>.from(targetThread.messages)..add(noteMsg);
    _threads[index] = targetThread.copyWith(
      lastMessage: '🔒 [Internal Note] ${noteText.trim()}',
      lastMessageTime: DateTime.now(),
      timeAgo: 'Just now',
      messages: updatedMessages,
    );
    notifyListeners();

    await apiService.updateLead(
      leadId: targetThread.contactId > 0 ? targetThread.contactId.toString() : targetThread.id,
      phone: targetThread.customerPhone,
      name: targetThread.customerName,
      note: noteText.trim(),
      author: _currentAgentName,
    );
  }

  Future<void> loadThreadMessages(String threadId) async {
    final index = _threads.indexWhere((th) => th.id == threadId);
    if (index == -1) return;

    final target = _threads[index];
    _isLoadingMessages = true;
    notifyListeners();

    try {
      final data = await apiService.fetchWhatsAppMessages(
        phone: target.customerPhone,
        remoteJid: target.remoteJid,
        contactId: target.contactId,
      );

      if (data != null && data['messages'] is List) {
        final rawMessages = List<Map<String, dynamic>>.from(data['messages']);
        final parsedMessages = rawMessages.map((m) {
          final tsStr = m['timestamp']?.toString() ?? '';
          final parsedTs = DateTime.tryParse(tsStr) ?? DateTime.now();
          return WhatsAppMessage(
            id: m['id']?.toString() ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
            text: m['text']?.toString() ?? '',
            isFromCustomer: m['is_from_customer'] == true,
            timestamp: parsedTs,
            status: m['status']?.toString() ?? 'delivered',
            isInternalNote: m['is_internal_note'] == true,
            isCallEvent: m['is_call_event'] == true,
            authorName: m['author_name']?.toString() ?? 'Agent',
            channel: m['channel']?.toString() ?? 'whatsapp',
          );
        }).toList();

        final currIdx = _threads.indexWhere((th) => th.id == threadId);
        if (currIdx != -1 && parsedMessages.isNotEmpty) {
          final lastMsg = parsedMessages.last;
          _threads[currIdx] = _threads[currIdx].copyWith(
            messages: parsedMessages,
            lastMessage: lastMsg.text,
            lastMessageTime: lastMsg.timestamp,
            lastMessageFromMe: !lastMsg.isFromCustomer,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading thread messages: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> fetchThreadsFromServer() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hubData = await apiService.fetchWhatsAppHubData();
      if (hubData != null) {
        _evolutionOnline = hubData['evolution_online'] == true;
        final rawLeads = hubData['leads'] is List
            ? List<Map<String, dynamic>>.from(hubData['leads'])
            : <Map<String, dynamic>>[];

        if (rawLeads.isNotEmpty) {
          final existingById = {for (final t in _threads) t.id: t};

          final fetchedThreads = rawLeads.map((item) {
            final id = item['id']?.toString() ??
                'th_${(item['phone']?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), '')}';
            final phone = item['phone']?.toString() ?? '';
            final rawName = (item['customer_name']?.toString() ?? item['name']?.toString() ?? '').trim();
            final lowerRaw = rawName.toLowerCase();
            final String name;
            if (rawName.isEmpty ||
                lowerRaw == 'nobody' ||
                lowerRaw == 'null' ||
                lowerRaw == 'unknown' ||
                RegExp(r'^\+?[0-9]{7,15}$').hasMatch(rawName)) {
              final circuitHint = item['tour_interest']?.toString() ?? item['destination']?.toString() ?? '';
              if (circuitHint.isNotEmpty && circuitHint != 'Spiritual Circuit' && circuitHint != 'Varanasi Pilgrimage') {
                name = 'Traveler ($circuitHint)';
              } else if (phone.isNotEmpty) {
                final shortPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                name = 'Traveler ($shortPhone)';
              } else {
                name = 'Traveler';
              }
            } else {
              name = rawName;
            }
            final lastMsg = item['last_message']?.toString() ??
                item['message']?.toString() ??
                'Tap to open WhatsApp & CRM timeline';
            final circuit = item['tour_interest']?.toString() ??
                item['destination']?.toString() ??
                'Spiritual Circuit';
            final stage = item['stage']?.toString() ?? 'new';
            final owner = item['assigned_agent']?.toString() ??
                item['owner']?.toString() ??
                'Santosh Yadav';
            final unreadCount = int.tryParse(item['unread_count']?.toString() ?? '0') ?? 0;
            final contactId = int.tryParse(item['contact_id']?.toString() ?? '0') ?? 0;
            final callCount = int.tryParse(item['call_count']?.toString() ?? '0') ?? 0;
            final dealValue = double.tryParse(item['deal_value']?.toString() ?? '0') ?? 0.0;
            final remoteJid = item['remote_jid']?.toString() ?? '';
            final profilePicUrl = item['profile_pic_url']?.toString() ?? '';
            final lastMessageFromMe = item['last_message_from_me'] == true;
            final lastMessageStatus = item['last_message_status']?.toString() ?? 'read';
            final timeAgo = item['time_ago']?.toString() ?? '';
            final sourceChannel = item['source_channel']?.toString() ?? 'whatsapp';
            final hasWhatsappChat = item['has_whatsapp_chat'] == true;
            final isB2b = item['is_b2b'] == true;
            final isAiActive = item['is_ai_active'] != false;

            DateTime lastMessageTime = DateTime.now();
            final rawTs = item['timestamp']?.toString() ?? '';
            if (rawTs.isNotEmpty) {
              lastMessageTime = DateTime.tryParse(rawTs) ?? DateTime.now();
            }

            DateTime? nextFollowUpAt;
            final rawFollowUp = item['next_follow_up_at']?.toString() ?? '';
            if (rawFollowUp.isNotEmpty) {
              nextFollowUpAt = DateTime.tryParse(rawFollowUp);
            }

            final prevThread = existingById[id];
            final initialMessages = (prevThread != null && prevThread.messages.length > 1)
                ? prevThread.messages
                : <WhatsAppMessage>[
                    WhatsAppMessage(
                      id: 'preview_$id',
                      text: lastMsg,
                      isFromCustomer: !lastMessageFromMe,
                      timestamp: lastMessageTime,
                      status: lastMessageStatus,
                      channel: hasWhatsappChat ? 'whatsapp' : sourceChannel,
                    ),
                  ];

            return WhatsAppThread(
              id: id,
              contactId: contactId,
              remoteJid: remoteJid,
              customerPhone: phone,
              customerName: name,
              profilePicUrl: profilePicUrl,
              lastMessage: lastMsg,
              lastMessageTime: lastMessageTime,
              lastMessageFromMe: lastMessageFromMe,
              lastMessageStatus: lastMessageStatus,
              timeAgo: timeAgo,
              unreadCount: unreadCount,
              assignedAgent: owner,
              isAiAssisted: isAiActive,
              circuit: circuit,
              stage: stage,
              dealValue: dealValue,
              sourceChannel: sourceChannel,
              hasWhatsappChat: hasWhatsappChat,
              isB2b: isB2b,
              nextFollowUpAt: nextFollowUpAt,
              callCount: callCount,
              messages: initialMessages,
            );
          }).toList();

          _threads = fetchedThreads;
          if (_selectedThreadId == null && _threads.isNotEmpty) {
            _selectedThreadId = _threads.first.id;
          }
        }
      }
    } catch (e) {
      debugPrint('Error in fetchThreadsFromServer: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  WhatsAppThread getOrCreateThread({
    required String customerPhone,
    required String customerName,
    required String circuit,
    String? initialMessage,
  }) {
    final cleanPhone = customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    final existingIndex = _threads.indexWhere((th) {
      final thClean = th.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
      return suffix.isNotEmpty && thClean.endsWith(suffix);
    });
    if (existingIndex != -1) {
      _selectedThreadId = _threads[existingIndex].id;
      notifyListeners();
      loadThreadMessages(_threads[existingIndex].id);
      return _threads[existingIndex];
    }
    final newThread = WhatsAppThread(
      id: 'th_$suffix',
      customerPhone: customerPhone,
      customerName: customerName,
      circuit: circuit.isNotEmpty ? circuit : 'Spiritual Circuit',
      assignedAgent: _currentAgentName,
      isAiAssisted: true,
      unreadCount: 0,
      lastMessage: initialMessage ?? 'Tap to start WhatsApp conversation',
      lastMessageTime: DateTime.now(),
      stage: 'new',
      sourceChannel: 'whatsapp',
      messages: [
        if (initialMessage != null && initialMessage.isNotEmpty)
          WhatsAppMessage(
            id: 'init_msg_${DateTime.now().millisecondsSinceEpoch}',
            text: initialMessage,
            isFromCustomer: true,
            timestamp: DateTime.now(),
          ),
      ],
    );
    _threads.insert(0, newThread);
    _selectedThreadId = newThread.id;
    notifyListeners();
    loadThreadMessages(newThread.id);
    return newThread;
  }
}
