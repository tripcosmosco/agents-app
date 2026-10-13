import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/lead_provider.dart';
import '../services/api_service.dart';

class WhatsAppLiveChatSheet extends StatefulWidget {
  final String leadId;
  final String customerName;
  final String phone;
  final String destination;
  final String? initialMessage;

  const WhatsAppLiveChatSheet({
    super.key,
    required this.leadId,
    required this.customerName,
    required this.phone,
    required this.destination,
    this.initialMessage,
  });

  static void show(
    BuildContext context, {
    required String leadId,
    required String customerName,
    required String phone,
    required String destination,
    String? initialMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WhatsAppLiveChatSheet(
        leadId: leadId,
        customerName: customerName,
        phone: phone,
        destination: destination,
        initialMessage: initialMessage,
      ),
    );
  }

  @override
  State<WhatsAppLiveChatSheet> createState() => _WhatsAppLiveChatSheetState();
}

class _WhatsAppLiveChatSheetState extends State<WhatsAppLiveChatSheet> {
  late final ApiService _apiService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  late List<Map<String, dynamic>> _messages;

  final List<Map<String, String>> _cannedQuickReplies = [
    {
      'label': '🕉️ VIP Sugam Darshan',
      'text':
          'Namaste Ji! 🙏 Kashi Vishwanath VIP Sugam Darshan allows direct entry without waiting in the 3-hour queue. The pass fee is ₹300 per person and includes priest guidance directly to the Garbhagriha.',
    },
    {
      'label': '🚤 Evening Aarti Boat',
      'text':
          'For the Ganga Aarti at Dashashwamedh Ghat, we provide reserved Bajra / Electric Boat seating facing the main podium with complimentary life jackets and hot tea. Timings: 5:45 PM reporting.',
    },
    {
      'label': '🚗 Airport Cab Tariff',
      'text':
          'Pickup from Varanasi Airport (VNS) to Ghats / Godowlia: AC Sedan (Dzire) ₹1,100 | Innova Crysta ₹1,800. Sanitized vehicle with experienced UP65 driver.',
    },
    {
      'label': '💳 Advance UPI Payment',
      'text':
          'To lock your pilgrimage booking, an initial advance of ₹3,000 can be paid via UPI to our official TripCosmos desk: 9336116210@upi (+91 93361 16210). Balance is payable on arrival.',
    },
    {
      'label': '🛕 Temple Dress Code',
      'text':
          'For early morning Rudrabhishek and Sparsh Darshan at Kashi Vishwanath: Men: Dhoti/Kurta (unstitched preferred); Women: Saree or Salwar suit. Leather belts and wallets are prohibited.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _apiService = context.read<LeadProvider>().apiService;
    _messages = [
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty)
        {
          'sender': 'user',
          'text': widget.initialMessage!,
          'time': 'Earlier today',
        },
    ];
    _loadLiveMessages();
  }

  Future<void> _loadLiveMessages() async {
    try {
      final data = await _apiService.fetchWhatsAppMessages(phone: widget.phone);
      if (data != null && data['messages'] is List && mounted) {
        final rawMessages = List<Map<String, dynamic>>.from(data['messages']);
        if (rawMessages.isNotEmpty) {
          setState(() {
            _messages = rawMessages.map((m) {
              final isCustomer = m['is_from_customer'] == true || m['sender'] == 'customer';
              final tsStr = m['timestamp']?.toString() ?? '';
              final parsedTs = DateTime.tryParse(tsStr) ?? DateTime.now();
              final timeStr = DateFormat('h:mm a').format(parsedTs);
              return <String, dynamic>{
                'sender': isCustomer ? 'user' : 'agent',
                'text': m['text']?.toString() ?? m['message']?.toString() ?? '',
                'time': timeStr,
              };
            }).toList();
          });
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? textToSend]) async {
    final text = (textToSend ?? _messageController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'agent',
        'text': text,
        'time': DateFormat('h:mm a').format(DateTime.now()),
      });
      _messageController.clear();
      _isSending = true;
    });

    _scrollToBottom();

    // Dispatch via Central Evolution API
    final delivered = await _apiService.sendWhatsAppMessage(
      phone: widget.phone,
      message: text,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();

      if (!delivered) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.sync_problem_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gateway busy or queued. Message logged in CRM and retrying via Central Desk.',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.whatsappGreen,
                  child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.customerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CENTRAL EVOLUTION WA',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.phone} • ${widget.destination}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Canned Quick Reply Chips
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF161E2E),
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _cannedQuickReplies.length,
              itemBuilder: (context, index) {
                final item = _cannedQuickReplies[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Colors.white12),
                    label: Text(
                      item['label']!,
                      style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _sendMessage(item['text']),
                  ),
                );
              },
            ),
          ),

          // Message Feed
          Expanded(
            child: Container(
              color: const Color(0xFF0B132B),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isAgent = msg['sender'] == 'agent';

                  return Align(
                    alignment: isAgent ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isAgent ? const Color(0xFF059669) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(isAgent ? 14 : 2),
                          bottomRight: Radius.circular(isAgent ? 2 : 14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                msg['time'] ?? '',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              if (isAgent) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.done_all,
                                  size: 13,
                                  color: Color(0xFF38BDF8),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Message Composer Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Type WhatsApp reply from central number...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                      fillColor: const Color(0xFF0F172A),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.whatsappGreen,
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
