import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../services/api_service.dart';

class WebChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> chat;
  final ApiService apiService;

  const WebChatDetailScreen({
    super.key,
    required this.chat,
    required this.apiService,
  });

  @override
  State<WebChatDetailScreen> createState() => _WebChatDetailScreenState();
}

class _WebChatDetailScreenState extends State<WebChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  late bool _isAiActive;
  Timer? _pollTimer;

  final List<Map<String, String>> _cannedQuickReplies = [
    {
      'label': '🕉️ VIP Sugam Darshan',
      'text':
          'Namaste! We can confirm VIP Sugam Darshan passes for Shri Kashi Vishwanath Temple with priority entry and dedicated temple escort.',
    },
    {
      'label': '🚗 Airport Cab Tariff',
      'text':
          'Pickup from Varanasi Airport (VNS) to Ghats / Godowlia: AC Sedan (Dzire) ₹1,100 | Innova Crysta ₹1,800. Sanitized vehicle with experienced UP65 driver.',
    },
    {
      'label': '💳 Advance UPI Payment',
      'text':
          'To lock your pilgrimage booking, an initial advance of ₹2,000 can be paid via UPI to our official TripCosmos desk: 9336116210@upi (+91 93361 16210). Balance is payable on arrival.',
    },
    {
      'label': '🛕 Temple Dress Code',
      'text':
          'For early morning Rudrabhishek and Sparsh Darshan at Kashi Vishwanath: Men: Dhoti/Kurta; Women: Saree or Salwar suit. Leather items prohibited inside corridor.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _isAiActive = widget.chat['is_ai_active'] ?? true;
    _fetchDetail();
    // Poll every 3 seconds for new live visitor messages
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _pollMessages();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _sessionId => widget.chat['session_id']?.toString() ?? '';

  Future<void> _fetchDetail() async {
    final detail = await widget.apiService.fetchWebChatDetail(_sessionId);
    if (!mounted) return;

    if (detail != null && detail['messages'] is List) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(detail['messages']);
        _isAiActive = detail['is_ai_active'] ?? _isAiActive;
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pollMessages() async {
    final detail = await widget.apiService.fetchWebChatDetail(_sessionId);
    if (!mounted || detail == null) return;

    final incoming = List<Map<String, dynamic>>.from(detail['messages'] ?? []);
    if (incoming.length != _messages.length) {
      setState(() {
        _messages = incoming;
        _isAiActive = detail['is_ai_active'] ?? _isAiActive;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? directText]) async {
    final text = (directText ?? _textController.text).trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _textController.clear();

    // Optimistically add agent message
    final tempMsg = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'from': 'agent',
      'role': 'agent',
      'content': text,
      'agent_name': 'Santosh Yadav',
      'created_at': DateTime.now().toIso8601String(),
    };
    setState(() {
      _messages.add(tempMsg);
      _isAiActive = false; // Human takeover is now active
    });
    _scrollToBottom();

    final success = await widget.apiService.sendWebChatReply(
      sessionId: _sessionId,
      message: text,
      agentName: 'Santosh Yadav',
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to deliver reply to website visitor.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleAiTakeover() async {
    final newAiState = !_isAiActive;
    setState(() => _isAiActive = newAiState);

    final success = await widget.apiService.toggleWebChatAi(
      sessionId: _sessionId,
      enableAi: newAiState,
    );

    if (mounted && !success) {
      setState(() => _isAiActive = !newAiState);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update AI takeover state.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitorName = widget.chat['customer_name']?.toString() ?? 'Web Visitor';
    final pageUrl = widget.chat['page_url']?.toString() ?? '/';
    final pageTitle = widget.chat['page_title']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0284C7)),
              ),
              child: const Center(
                child: Text('🌐', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visitorName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    pageTitle.isNotEmpty ? pageTitle : pageUrl,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // AI Takeover Switch Pill
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _toggleAiTakeover,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isAiActive
                      ? AppColors.accentGold.withValues(alpha: 0.15)
                      : AppColors.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isAiActive ? AppColors.accentGold : AppColors.successGreen,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAiActive ? Icons.smart_toy : Icons.person,
                      size: 14,
                      color: _isAiActive ? AppColors.accentGold : AppColors.successGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isAiActive ? 'AI Replying' : 'You are Live',
                      style: TextStyle(
                        color: _isAiActive ? AppColors.accentGold : AppColors.successGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner indicating live human takeover status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              color: _isAiActive
                  ? Colors.blueGrey.withValues(alpha: 0.15)
                  : AppColors.successGreen.withValues(alpha: 0.12),
              child: Row(
                children: [
                  Icon(
                    _isAiActive ? Icons.info_outline : Icons.verified,
                    size: 14,
                    color: _isAiActive ? AppColors.textMuted : AppColors.successGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isAiActive
                          ? 'AI is auto-answering pilgrim queries. Tap badge above to take over.'
                          : 'Human Takeover Active: AI paused. Your messages appear live in their browser.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isAiActive ? AppColors.textMuted : AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messages Stream
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accentGold),
                    )
                  : _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages in this web session yet.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final from = msg['from']?.toString() ?? 'customer';
                            final isCustomer = from == 'customer';
                            final isAgent = from == 'agent';
                            final content = msg['content']?.toString() ?? '';
                            final agentName = msg['agent_name']?.toString() ?? 'Specialist';
                            final createdAt = msg['created_at']?.toString() ?? '';

                            DateTime? dt;
                            try {
                              dt = DateTime.parse(createdAt);
                            } catch (_) {}
                            final timeStr = dt != null ? DateFormat('hh:mm a').format(dt) : '';

                            return Align(
                              alignment: isAgent
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isAgent
                                      ? const Color(0xFF064E3B)
                                      : (isCustomer
                                          ? AppColors.surfaceCard
                                          : const Color(0xFF1E293B)),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isAgent ? 16 : 4),
                                    bottomRight: Radius.circular(isAgent ? 4 : 16),
                                  ),
                                  border: Border.all(
                                    color: isAgent
                                        ? AppColors.successGreen.withValues(alpha: 0.5)
                                        : (isCustomer
                                            ? Colors.white12
                                            : AppColors.accentGold.withValues(alpha: 0.3)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Author Tag
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isAgent) ...[
                                          const Icon(Icons.person, size: 12, color: AppColors.successGreen),
                                          const SizedBox(width: 4),
                                          Text(
                                            agentName,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.successGreen,
                                            ),
                                          ),
                                        ] else if (isCustomer) ...[
                                          const Icon(Icons.language, size: 12, color: Colors.blueAccent),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Website Visitor',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                        ] else ...[
                                          const Icon(Icons.smart_toy, size: 12, color: AppColors.accentGold),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'TripCosmos AI Guide',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accentGold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    // Message Body
                                    Text(
                                      content,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        height: 1.35,
                                      ),
                                    ),
                                    if (timeStr.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          timeStr,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Quick Canned Replies Bar
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _cannedQuickReplies.length,
                itemBuilder: (context, index) {
                  final reply = _cannedQuickReplies[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: AppColors.surfaceCard,
                      side: BorderSide(
                        color: AppColors.accentGold.withValues(alpha: 0.3),
                      ),
                      label: Text(
                        reply['label']!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGold,
                        ),
                      ),
                      onPressed: () => _sendMessage(reply['text']),
                    ),
                  );
                },
              ),
            ),

            // Text Input Box
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type live reply to website visitor...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isSending ? null : () => _sendMessage(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
