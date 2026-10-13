import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../models/whatsapp_thread_model.dart';
import '../providers/call_provider.dart';
import '../providers/whatsapp_provider.dart';
import 'cab_fare_dialog.dart';
import 'travel_quote_dialog.dart';

class WhatsAppTeamChatView extends StatefulWidget {
  final WhatsAppThread thread;
  final VoidCallback? onBack;

  const WhatsAppTeamChatView({
    super.key,
    required this.thread,
    this.onBack,
  });

  @override
  State<WhatsAppTeamChatView> createState() => _WhatsAppTeamChatViewState();
}

class _WhatsAppTeamChatViewState extends State<WhatsAppTeamChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isInternalNoteMode = false;
  bool _isSummarizing = false;

  final List<Map<String, String>> _cannedQuickReplies = [
    {
      'label': '🙏 Welcome & Itinerary',
      'text':
          'Namaste! 🙏 Welcome to TripCosmos.co (Varanasi Official Desk). Please share your travel dates and number of guests so I can send your customized Kashi-Ayodhya-Prayagraj itinerary.',
    },
    {
      'label': '🕉️ VIP Sugam Darshan',
      'text':
          'Namaste! We can confirm VIP Sugam Darshan passes for Shri Kashi Vishwanath Temple with priority entry and dedicated local escort.',
    },
    {
      'label': '🚗 Airport Cab Tariff',
      'text':
          'Pickup from Varanasi Airport (VNS) to Ghats / Godowlia: AC Sedan (Dzire) ₹1,100 | Innova Crysta ₹1,800. Sanitized vehicle with experienced UP65 driver.',
    },
    {
      'label': '💳 Advance UPI ₹1,500',
      'text':
          'To lock your confirmed Varanasi darshan dates & AC vehicle, an advance token of ₹1,500 can be paid via UPI to our official TripCosmos desk: 9336116210@upi (+91 93361 16210). Balance payable on arrival.',
    },
    {
      'label': '🏢 B2B DMC Net Tariff',
      'text':
          'Namaste Partner! 🙏 Sharing TripCosmos Varanasi B2B Net DMC Tariffs:\n• 3D2N Kashi Spiritual: ₹7,100/pax net\n• 4D3N Kashi-Ayodhya-Prayagraj: ₹10,500/pax net\n• 100% White-Label Vouchers (Your Branding) & Dedicated UP65 Fleet.',
    },
    {
      'label': '🪔 Dev Deepawali 2026',
      'text':
          '🪔 *Dev Deepawali 2026 B2B Allocation Open!* Pre-booked Dashashwamedh Ghat Bajra Boat seats, 3★/4★ Hotel blocks & Tempo Travellers at Net DMC rates. Share group size to hold inventory.',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WhatsAppProvider>().loadThreadMessages(widget.thread.id).then((_) {
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage(WhatsAppProvider provider, [String? directText]) async {
    final text = (directText ?? _textController.text).trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    if (directText == null) {
      _textController.clear();
    }

    if (_isInternalNoteMode) {
      await provider.addInternalNote(widget.thread.id, text);
    } else {
      final ok = await provider.sendMessage(widget.thread.id, text);
      if (mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Message queued on server. Check Evolution WhatsApp connection if delayed.'),
            backgroundColor: Color(0xFF1E293B),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<void> _summarizeThreadWithAi(WhatsAppProvider provider, WhatsAppThread thread) async {
    setState(() => _isSummarizing = true);
    final summary = await provider.apiService.summarizeCallWithAi(
      phone: thread.customerPhone,
      customerName: thread.customerName,
      circuit: thread.circuit,
      notes: thread.lastMessage,
    );
    if (!mounted) return;
    setState(() => _isSummarizing = false);
    if (summary != null && summary.isNotEmpty) {
      await provider.addInternalNote(thread.id, summary);
      _scrollToBottom();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ AI Thread & Call Summary added to Team Notes!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }

  void _showStageSelectorSheet(BuildContext context, WhatsAppProvider provider, WhatsAppThread thread) {
    final stages = [
      {'key': 'new', 'label': '🔥 New Inquiry', 'color': const Color(0xFF38BDF8)},
      {'key': 'contacted', 'label': '📞 Contacted', 'color': Colors.amber},
      {'key': 'qualified', 'label': '✅ Qualified', 'color': AppColors.accentGold},
      {'key': 'quote_sent', 'label': '💰 Quote Sent', 'color': Colors.orangeAccent},
      {'key': 'advance_received', 'label': '💳 Advance Paid', 'color': AppColors.successGreen},
      {'key': 'won', 'label': '🏆 Won / Booked', 'color': AppColors.successGreen},
      {'key': 'b2b_partner', 'label': '🏢 B2B Partner', 'color': Colors.purpleAccent},
      {'key': 'lost', 'label': '❌ Not Interested', 'color': AppColors.errorRed},
    ];

    final dealController = TextEditingController(
      text: thread.dealValue > 0 ? thread.dealValue.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Superfone Lead Stage & Deal Value',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dealController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Package / Deal Value (₹)',
                hintText: 'e.g. 28500',
                prefixText: '₹ ',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stages.map((st) {
                final isSelected = thread.stage.toLowerCase() == st['key'];
                final color = st['color'] as Color;
                return ActionChip(
                  backgroundColor: isSelected ? color.withValues(alpha: 0.25) : const Color(0xFF0F172A),
                  side: BorderSide(color: isSelected ? color : Colors.white24),
                  label: Text(
                    st['label'] as String,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () {
                    final dealVal = double.tryParse(dealController.text.trim());
                    provider.updateThreadStage(
                      thread.id,
                      st['key'] as String,
                      dealValue: dealVal,
                    );
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFollowUpDateTime(BuildContext context, WhatsAppProvider provider, WhatsAppThread thread) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: thread.nextFollowUpAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: thread.nextFollowUpAt != null
          ? TimeOfDay.fromDateTime(thread.nextFollowUpAt!)
          : const TimeOfDay(hour: 11, minute: 0),
    );
    if (time == null || !context.mounted) return;

    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await provider.scheduleThreadFollowUp(thread.id, scheduled);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ Follow-up reminder saved for ${DateFormat('dd MMM, h:mm a').format(scheduled)}'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _showReassignAgentSheet(BuildContext context, WhatsAppProvider provider, WhatsAppThread currentThread) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Assign Lead & WhatsApp Thread Owner',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...AppConstants.teamMembers.map((member) {
                final isCurrent = currentThread.assignedAgent.toLowerCase() == member['name']!.toLowerCase();
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accentBlue,
                    child: Text(
                      member['initials']!,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(member['name']!, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(member['role']!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: isCurrent ? const Icon(Icons.check, color: AppColors.successGreen) : null,
                  onTap: () {
                    provider.assignThreadAgent(currentThread.id, member['name']!);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Color _stageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'won':
      case 'advance_received':
        return AppColors.successGreen;
      case 'quote_sent':
      case 'qualified':
        return AppColors.accentGold;
      case 'b2b_partner':
        return Colors.purpleAccent;
      case 'lost':
        return AppColors.errorRed;
      default:
        return const Color(0xFF38BDF8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WhatsAppProvider>(context);
    final currentThread = provider.threads.firstWhere(
      (th) => th.id == widget.thread.id,
      orElse: () => widget.thread,
    );

    final stageColor = _stageColor(currentThread.stage);

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 1,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBack,
              )
            : null,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: provider.isB2bThread(currentThread)
                  ? Colors.purple.shade700
                  : AppColors.whatsappGreen,
              backgroundImage: currentThread.profilePicUrl.isNotEmpty
                  ? NetworkImage(currentThread.profilePicUrl)
                  : null,
              child: currentThread.profilePicUrl.isEmpty
                  ? Text(
                      currentThread.initials,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentThread.customerName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          currentThread.customerPhone,
                          style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontFamily: 'monospace'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '• ${currentThread.circuit}',
                          style: const TextStyle(fontSize: 10, color: AppColors.accentGold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 1-Tap Direct Phone Call
          if (currentThread.customerPhone.isNotEmpty)
            IconButton(
              tooltip: 'Call ${currentThread.customerName}',
              icon: const Icon(Icons.call_rounded, color: AppColors.successGreen, size: 20),
              onPressed: () {
                context.read<CallProvider>().startOutboundCall(
                  phone: currentThread.customerPhone,
                  name: currentThread.customerName,
                  tourInterest: currentThread.circuit,
                );
              },
            ),

          // 1-Tap B2B / Retail Quote Generator
          IconButton(
            tooltip: provider.isB2bThread(currentThread) ? 'Send B2B Net DMC Quote ⚡' : 'Send Package Quote ⚡',
            icon: const Icon(Icons.bolt, color: Color(0xFFFBBF24), size: 20),
            onPressed: () {
              final tempLead = LeadModel(
                id: currentThread.id,
                name: currentThread.customerName,
                phone: currentThread.customerPhone,
                destination: currentThread.circuit,
                pax: provider.isB2bThread(currentThread) ? 12 : 4,
                stage: currentThread.stage,
                source: provider.isB2bThread(currentThread) ? 'b2b_partner' : 'whatsapp',
                createdAt: DateTime.now(),
              );
              TravelQuoteDialog.show(
                context,
                tempLead,
                initialB2bMode: provider.isB2bThread(currentThread),
              );
            },
          ),

          // 1-Tap Cab Fare Calculator
          IconButton(
            tooltip: 'Calculate Cab Fare 🚕',
            icon: const Icon(Icons.local_taxi_rounded, color: Color(0xFF38BDF8), size: 19),
            onPressed: () {
              final tempLead = LeadModel(
                id: currentThread.id,
                name: currentThread.customerName,
                phone: currentThread.customerPhone,
                destination: currentThread.circuit,
                pax: 4,
                stage: currentThread.stage,
                source: 'whatsapp',
                createdAt: DateTime.now(),
              );
              CabFareDialog.show(context, lead: tempLead);
            },
          ),

          // Refresh Thread History
          IconButton(
            tooltip: 'Sync Live Evolution WhatsApp History',
            icon: const Icon(Icons.sync_rounded, color: Colors.white70, size: 18),
            onPressed: () => provider.loadThreadMessages(currentThread.id),
          ),
        ],
      ),
      body: Column(
        children: [
          // SUPERFONE STICKY CRM BAR (Stage + Deal Value + Follow-Up Alarm + Owner + AI Toggle + AI Summary)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF141E33),
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 1. Stage + Deal Value Chip
                  InkWell(
                    onTap: () => _showStageSelectorSheet(context, provider, currentThread),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: stageColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: stageColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag_rounded, size: 12, color: stageColor),
                          const SizedBox(width: 4),
                          Text(
                            currentThread.stageLabel.toUpperCase(),
                            style: TextStyle(
                              color: stageColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (currentThread.dealValue > 0) ...[
                            const SizedBox(width: 5),
                            Text(
                              '• ₹${NumberFormat.compact().format(currentThread.dealValue)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_drop_down, size: 14, color: stageColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 2. Follow-Up Reminder Chip
                  InkWell(
                    onTap: () => _pickFollowUpDateTime(context, provider, currentThread),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: currentThread.nextFollowUpAt != null
                            ? AppColors.accentGold.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: currentThread.nextFollowUpAt != null
                              ? AppColors.accentGold
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alarm_rounded,
                            size: 12,
                            color: currentThread.nextFollowUpAt != null
                                ? AppColors.accentGold
                                : Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentThread.nextFollowUpAt != null
                                ? DateFormat('dd MMM, h:mm a').format(currentThread.nextFollowUpAt!)
                                : 'Set Follow-up',
                            style: TextStyle(
                              color: currentThread.nextFollowUpAt != null
                                  ? AppColors.accentGold
                                  : Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 3. Assigned Owner Chip
                  InkWell(
                    onTap: () => _showReassignAgentSheet(context, provider, currentThread),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: Color(0xFF60A5FA)),
                          const SizedBox(width: 4),
                          Text(
                            currentThread.assignedAgent,
                            style: const TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 4. AI Auto-Reply Toggle Chip
                  InkWell(
                    onTap: () => provider.toggleAiTakeover(currentThread.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: currentThread.isAiAssisted
                            ? AppColors.whatsappGreen.withValues(alpha: 0.18)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: currentThread.isAiAssisted ? AppColors.whatsappGreen : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_toy_rounded,
                            size: 12,
                            color: currentThread.isAiAssisted ? AppColors.whatsappGreen : Colors.white54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentThread.isAiAssisted ? 'AI Auto: ON' : 'Human Only',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: currentThread.isAiAssisted ? AppColors.whatsappGreen : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 5. 1-Tap AI Summarize Thread
                  InkWell(
                    onTap: _isSummarizing ? null : () => _summarizeThreadWithAi(provider, currentThread),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSummarizing)
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.amber),
                            )
                          else
                            const Icon(Icons.auto_awesome, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          const Text(
                            'AI Summary',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (provider.isLoadingMessages)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.whatsappGreen,
              backgroundColor: Colors.transparent,
            ),

          // Unified Omnichannel Message + Call + Note Stream
          Expanded(
            child: currentThread.messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Send a WhatsApp message or log a note below.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: currentThread.messages.length,
                    itemBuilder: (context, index) {
                      final msg = currentThread.messages[index];
                      return _buildMessageBubble(msg, currentThread);
                    },
                  ),
          ),

          // Canned Quick Reply Chips
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFF1E293B),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _cannedQuickReplies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final reply = _cannedQuickReplies[i];
                return ActionChip(
                  label: Text(
                    reply['label']!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Colors.white12),
                  onPressed: () => _sendMessage(provider, reply['text']),
                );
              },
            ),
          ),

          // Input Bar with WhatsApp vs Internal Team Note Mode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode Selector Pill (WhatsApp vs Internal Whisper)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _isInternalNoteMode = false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: !_isInternalNoteMode
                                  ? AppColors.whatsappGreen.withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !_isInternalNoteMode ? AppColors.whatsappGreen : Colors.white12,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_rounded,
                                  size: 11,
                                  color: !_isInternalNoteMode ? AppColors.whatsappGreen : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Official WhatsApp (+91 93361 16210)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: !_isInternalNoteMode ? FontWeight.bold : FontWeight.normal,
                                    color: !_isInternalNoteMode ? Colors.white : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _isInternalNoteMode = true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isInternalNoteMode
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isInternalNoteMode ? const Color(0xFFF59E0B) : Colors.white12,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 11,
                                  color: _isInternalNoteMode ? const Color(0xFFFBBF24) : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Team Note (Saved to CRM)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: _isInternalNoteMode ? FontWeight.bold : FontWeight.normal,
                                    color: _isInternalNoteMode ? const Color(0xFFFDE68A) : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Text Field Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _isInternalNoteMode
                                ? 'Add private CRM team note (persisted on server)...'
                                : 'Type WhatsApp message to ${currentThread.customerName}...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: _isInternalNoteMode ? const Color(0xFFF59E0B) : Colors.transparent,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(provider),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _isInternalNoteMode
                            ? const Color(0xFFD97706)
                            : AppColors.whatsappGreen,
                        child: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : IconButton(
                                icon: Icon(
                                  _isInternalNoteMode ? Icons.lock_rounded : Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () => _sendMessage(provider),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(WhatsAppMessage msg, WhatsAppThread thread) {
    final timeStr = DateFormat('dd MMM, h:mm a').format(msg.timestamp);

    // 1. Superfone Inline Call Event Card
    if (msg.isCallEvent || msg.channel == 'call') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF172554),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.45)),
          ),
          constraints: const BoxConstraints(maxWidth: 340),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_in_talk_rounded, size: 15, color: Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Superfone-style Internal Whisper Note
    if (msg.isInternalNote || msg.channel == 'note') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF451A03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
          ),
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 4),
                  Text(
                    'CRM NOTE • ${msg.authorName ?? "Agent"}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFBBF24),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                msg.text,
                style: const TextStyle(color: Color(0xFFFEF3C7), fontSize: 12.5, height: 1.3),
              ),
            ],
          ),
        ),
      );
    }

    final isCustomer = msg.isFromCustomer;
    final isWebChat = msg.channel == 'web';

    return Align(
      alignment: isCustomer ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCustomer
              ? (isWebChat ? const Color(0xFF0C4A6E) : const Color(0xFF1E293B))
              : const Color(0xFF065F46),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isCustomer ? 2 : 16),
            bottomRight: Radius.circular(isCustomer ? 16 : 2),
          ),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWebChat)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  isCustomer ? '🌐 Website Visitor' : '🤖 AI / Web Reply',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                ),
                if (!isCustomer) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.status == 'failed' ? Icons.error_outline : Icons.done_all,
                    color: msg.status == 'failed'
                        ? AppColors.errorRed
                        : (msg.status == 'read' ? Colors.cyanAccent : Colors.white60),
                    size: 13,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
