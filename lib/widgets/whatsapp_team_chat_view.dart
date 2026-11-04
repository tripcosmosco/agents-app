import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../models/whatsapp_thread_model.dart';
import '../providers/ai_agent_provider.dart';
import '../providers/call_provider.dart';
import '../providers/lead_provider.dart';
import '../providers/whatsapp_provider.dart';
import 'cab_fare_dialog.dart';
import 'travel_quote_dialog.dart';
import '../services/telephony_service.dart';

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

  List<Map<String, String>> _getPredictiveReplies(WhatsAppThread thread) {
    final text = thread.lastMessage.toLowerCase();
    final List<Map<String, String>> suggestions = [];

    // 1. Pricing & Packages Intent
    if (text.contains('rate') || text.contains('price') || text.contains('cost') || text.contains('kitna') || text.contains('package') || text.contains('budget')) {
      suggestions.add({
        'label': '✨ 💰 3D2N Kashi: ₹6,800/pax',
        'text': 'Namaste ${thread.customerName}! 🙏 Our most popular 3D2N Kashi Spiritual Package is ₹6,800/pax (includes AC Hotel, Airport/Station Transfers, Evening Ganga Aarti Boat & VIP Kashi Vishwanath Darshan). Would you like me to send the complete day-by-day plan?',
      });
      suggestions.add({
        'label': '✨ 📄 4D3N Circuit Tariff',
        'text': 'Namaste! Sharing our verified 4D3N Kashi-Ayodhya-Prayagraj Triveni Sangam circuit tariff. Hotel category: 3★/4★ available with breakfast & private AC cab.',
      });
    }

    // 2. Darshan & Aarti Intent
    if (text.contains('darshan') || text.contains('mandir') || text.contains('temple') || text.contains('aarti') || text.contains('vip') || text.contains('entry')) {
      suggestions.add({
        'label': '✨ 🕉️ VIP Sugam Darshan',
        'text': 'Namaste! We arrange confirmed VIP Sugam Darshan passes for Shri Kashi Vishwanath Temple with priority entry from Gate 4 and dedicated local escort so you don\'t have to wait in queues.',
      });
      suggestions.add({
        'label': '✨ 🚤 Bajra Ganga Aarti',
        'text': 'Namaste! We can reserve confirmed front-row seats on our traditional wooden Bajra Boat for the world-famous evening Dashashwamedh Ghat Ganga Aarti.',
      });
    }

    // 3. Cab & Transfer Intent
    if (text.contains('cab') || text.contains('taxi') || text.contains('airport') || text.contains('innova') || text.contains('car') || text.contains('pickup')) {
      suggestions.add({
        'label': '✨ 🚗 Airport Drop ₹1,100',
        'text': 'Pickup from Varanasi Airport (VNS) to Ghats / Godowlia: AC Sedan (Dzire) ₹1,100 | Innova Crysta ₹1,800. Sanitized vehicle with experienced UP65 driver.',
      });
      suggestions.add({
        'label': '✨ 🚕 Ayodhya Same-Day',
        'text': 'Varanasi to Ayodhya Ram Mandir same-day round trip: AC Sedan ₹3,800 | Innova Crysta ₹5,500 including toll, parking, and driver allowance.',
      });
    }

    // 4. Payment & UPI Intent
    if (text.contains('pay') || text.contains('advance') || text.contains('token') || text.contains('upi') || text.contains('account') || text.contains('qr') || text.contains('gpay')) {
      suggestions.add({
        'label': '✨ 💳 Advance Token ₹1,500',
        'text': 'To lock your confirmed Varanasi darshan dates & AC vehicle, an advance token of ₹1,500 can be paid via UPI to our official TripCosmos desk: 9336116210@upi (+91 93361 16210). Balance payable on arrival.',
      });
    }

    // 5. B2B DMC Intent
    if (thread.isB2b || text.contains('agent') || text.contains('b2b') || text.contains('partner') || text.contains('commission')) {
      suggestions.add({
        'label': '✨ 🏢 Wholesale Net Rates',
        'text': 'Namaste Partner! 🙏 Sharing TripCosmos Varanasi B2B Net DMC Tariffs:\n• 3D2N Kashi Spiritual: ₹7,100/pax net\n• 4D3N Kashi-Ayodhya-Prayagraj: ₹10,500/pax net\n• 100% White-Label Vouchers (Your Branding) & Dedicated UP65 Fleet.',
      });
    }

    // Merge with standard quick replies
    for (final def in _cannedQuickReplies) {
      if (!suggestions.any((s) => s['text'] == def['text'])) {
        suggestions.add(def);
      }
    }

    return suggestions;
  }

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
  void didUpdateWidget(WhatsAppTeamChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thread.id != widget.thread.id) {
      _textController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<WhatsAppProvider>().loadThreadMessages(widget.thread.id).then((_) {
          _scrollToBottom();
        });
      });
    }
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
        final isGatewayDown = !provider.evolutionOnline;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 14, right: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              isGatewayDown
                  ? '⚠️ Central WhatsApp Gateway disconnected (+91 9336116210). Send directly via WhatsApp App?'
                  : '⚠️ Message delivery failed for this recipient. Send directly via WhatsApp App?',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1E293B),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Open App ↗',
              textColor: AppColors.whatsappGreen,
              onPressed: () => TelephonyService.openWhatsApp(
                phoneNumber: widget.thread.customerPhone,
                message: text,
              ),
            ),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
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
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
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
            Text(
              'Update Superfone Lead Stage & Deal Value',
              style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dealController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white),
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
                  backgroundColor: isSelected
                      ? color.withValues(alpha: 0.25)
                      : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                  side: BorderSide(color: isSelected ? color : (isLight ? AppColors.lightBorderSubtle : Colors.white24)),
                  label: Text(
                    st['label'] as String,
                    style: TextStyle(
                      color: isSelected ? color : (isLight ? AppColors.lightTextPrimary : Colors.white),
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
    ).whenComplete(() => dealController.dispose());
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

  void _showEditNameDialog(BuildContext context, WhatsAppProvider provider, WhatsAppThread thread) {
    final controller = TextEditingController(
      text: thread.displayName.startsWith('Traveler') ? '' : thread.displayName,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Edit Traveler / Contact Name', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. Ramesh Kumar Ji',
            hintStyle: TextStyle(color: Colors.white38),
            labelText: 'Full Name',
            isDense: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.black),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                provider.updateThreadName(thread.id, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Name', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).whenComplete(() => controller.dispose());
  }

  void _showCallModeSelector(BuildContext context, WhatsAppThread currentThread) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final aiProvider = context.read<AiAgentProvider>();
    final activePersona = aiProvider.selectedPersona;

    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_forwarded_rounded, color: AppColors.accentGold, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Call ${currentThread.displayName}',
                  style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.successGreen,
                child: Icon(Icons.phone_android_rounded, color: Colors.white, size: 20),
              ),
              title: Text('Direct Carrier Call (Your Phone SIM)', style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Call ${currentThread.customerPhone} directly from your phone dialer (₹0 Cost)', style: TextStyle(color: isLight ? AppColors.lightTextMuted : Colors.white54, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<CallProvider>().startOutboundCall(
                  phone: currentThread.customerPhone,
                  name: currentThread.displayName,
                  tourInterest: currentThread.circuit,
                );
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.accentBlue,
                child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
              ),
              title: Text('Dispatch Autonomous AI Voice Agent (${activePersona.name})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('AI Agent dials customer, discusses ${currentThread.circuit} and generates post-call summary', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await aiProvider.apiService.initiateTelephonyCall(
                  phone: currentThread.customerPhone,
                  customerName: currentThread.displayName,
                  reason: '${currentThread.circuit} Package Follow-up',
                  modeOverride: 'livekit_sip',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res != null ? '🚀 AI Voice Agent ${activePersona.name} dialed ${currentThread.customerPhone}!' : '⚠️ Telephony bridge queued call dispatch.'),
                      backgroundColor: AppColors.accentBlue,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFailedMessageDetailsSheet(BuildContext context, WhatsAppProvider provider, WhatsAppMessage msg, WhatsAppThread thread) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 24),
                const SizedBox(width: 10),
                Text(
                  'WhatsApp Delivery Failed',
                  style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFFEF2F2) : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error Diagnostic:',
                    style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.evolutionOnline
                        ? 'The central WhatsApp Gateway (+91 9336116210) is connected and online. However, WhatsApp was unable to deliver this message to the recipient (the phone number may be inactive, incorrect, or unreachable on WhatsApp).'
                        : 'Evolution WhatsApp Gateway is disconnected. The central WhatsApp session (+91 9336116210) must be re-linked.',
                    style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Message: "${msg.text}"',
                    style: TextStyle(color: isLight ? AppColors.lightTextMuted : Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEvolutionQrSheet(context, provider);
                    },
                    icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.accentGold),
                    label: const Text('Check QR', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.whatsappGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      TelephonyService.openWhatsApp(
                        phoneNumber: thread.customerPhone,
                        message: msg.text,
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Open in App', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEvolutionQrSheet(BuildContext context, WhatsAppProvider provider) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FutureBuilder<Map<String, dynamic>?>(
        future: provider.apiService.fetchEvolutionStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
            );
          }

          final data = snapshot.data;
          final state = data?['state']?.toString() ?? 'unknown';
          final qr = data?['qr']?.toString() ?? '';
          final isOpen = data?['is_open'] == true;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isOpen ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      color: isOpen ? AppColors.successGreen : AppColors.errorRed,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isOpen ? 'WhatsApp Gateway Connected' : 'WhatsApp Gateway Disconnected',
                      style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Instance: ${data?['instance'] ?? 'TripCosmos.co'} • State: $state',
                  style: TextStyle(color: isLight ? AppColors.lightTextMuted : Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (!isOpen && qr.isNotEmpty && qr.startsWith('data:image')) ...[
                  const Text(
                    'Scan with business phone: Settings > Linked devices > Link a device',
                    style: TextStyle(color: AppColors.accentGold, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Image.network(qr, width: 180, height: 180, fit: BoxFit.contain),
                    ),
                  ),
                ] else if (!isOpen) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      'Session is closed. Open WhatsApp on +91 9336116210 and link device, or reload container at wa.vmstudio.digital.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ] else ...[
                  const Text('All outbound messages from CRM are delivering normally.', style: TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.black),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReassignAgentSheet(BuildContext context, WhatsAppProvider provider, WhatsAppThread currentThread) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final aiProvider = context.read<AiAgentProvider>();
    final aiPersonas = aiProvider.personas;

    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Assign Thread Handler (AI Persona or Human Rep)',
                    style: TextStyle(
                      color: isLight ? AppColors.lightTextPrimary : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // AI Personas Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    '🤖 AUTONOMOUS AI SALES PERSONAS',
                    style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                ...aiPersonas.map((persona) {
                  final isCurrent = currentThread.assignedAgent.toLowerCase().contains(persona.name.toLowerCase());
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentGold,
                      child: Text(
                        persona.name.substring(0, 1),
                        style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(persona.name, style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('AI Specialist', style: TextStyle(color: AppColors.accentGold, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    subtitle: Text('${persona.title} • ${persona.skills.where((s) => s.isEnabled).length} active skills', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: AppColors.successGreen) : null,
                    onTap: () {
                      provider.assignThreadAgent(currentThread.id, persona.name);
                      if (!currentThread.isAiAssisted) {
                        provider.toggleAiTakeover(currentThread.id);
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Assigned AI Agent ${persona.name} to this traveler thread!'),
                          backgroundColor: AppColors.accentBlue,
                        ),
                      );
                    },
                  );
                }),

                const Divider(color: Colors.white12),

                // Human Sales Reps Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    '👤 HUMAN SALES TEAM',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                ...Provider.of<LeadProvider>(context, listen: false).teamMembers.map((member) {
                  final name = member['name'] ?? '';
                  final isCurrent = currentThread.assignedAgent.toLowerCase() == name.toLowerCase();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentBlue,
                      child: Text(
                        member['initials'] ?? 'AG',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(member['role'] ?? 'Sales Agent', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: isCurrent ? const Icon(Icons.check, color: AppColors.successGreen) : null,
                    onTap: () {
                      provider.assignThreadAgent(currentThread.id, name);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
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

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFEFEAE2) : const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        iconTheme: IconThemeData(color: isLight ? AppColors.lightTextPrimary : Colors.white),
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
              child: InkWell(
                onTap: () => _showEditNameDialog(context, provider, currentThread),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            currentThread.displayName,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isLight ? AppColors.lightTextPrimary : Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_note_rounded, size: 14, color: isLight ? AppColors.lightTextMuted : Colors.white38),
                      ],
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            currentThread.customerPhone,
                            style: TextStyle(fontSize: 10.5, color: isLight ? AppColors.lightTextSecondary : Colors.white70, fontFamily: 'monospace'),
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
            ),
          ],
        ),
        actions: [
          // 1-Tap Open in WhatsApp App
          if (currentThread.customerPhone.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Open in WhatsApp App ↗',
              icon: const Icon(Icons.open_in_new_rounded, color: AppColors.whatsappGreen, size: 20),
              onPressed: () => TelephonyService.openWhatsApp(
                phoneNumber: currentThread.customerPhone,
              ),
            ),

          // 1-Tap Phone Call (SIM vs AI Voice Agent)
          if (currentThread.customerPhone.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Call ${currentThread.displayName}',
              icon: const Icon(Icons.call_rounded, color: AppColors.successGreen, size: 20),
              onPressed: () => _showCallModeSelector(context, currentThread),
            ),

          // Compact More Tools Menu (Quote Generator, Cab Fare Calculator, Live Sync)
          PopupMenuButton<String>(
            tooltip: 'Sales Tools & Sync',
            icon: Icon(Icons.more_vert_rounded, color: isLight ? AppColors.lightTextSecondary : Colors.white70, size: 20),
            onSelected: (val) {
              if (val == 'quote') {
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
              } else if (val == 'cab') {
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
              } else if (val == 'sync') {
                provider.loadThreadMessages(currentThread.id);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'quote',
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFFFBBF24), size: 18),
                    const SizedBox(width: 8),
                    Text(provider.isB2bThread(currentThread) ? 'Send B2B Net DMC Quote ⚡' : 'Send Package Quote ⚡'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cab',
                child: Row(
                  children: [
                    Icon(Icons.local_taxi_rounded, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 8),
                    Text('Calculate Cab Fare 🚕'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync_rounded, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text('Sync Evolution WhatsApp History'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // SUPERFONE STICKY CRM BAR (Stage + Deal Value + Follow-Up Alarm + Owner + AI Toggle + AI Summary)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF141E33),
              border: Border(bottom: BorderSide(color: isLight ? AppColors.lightBorderSubtle : Colors.white12)),
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
                              style: TextStyle(
                                color: isLight ? AppColors.lightTextPrimary : Colors.white,
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
                            : (isLight ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.06)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: currentThread.nextFollowUpAt != null
                              ? AppColors.accentGold
                              : (isLight ? const Color(0xFFCBD5E1) : Colors.white24),
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
                                : (isLight ? AppColors.lightTextSecondary : Colors.white70),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentThread.nextFollowUpAt != null
                                ? DateFormat('dd MMM, h:mm a').format(currentThread.nextFollowUpAt!)
                                : 'Set Follow-up',
                            style: TextStyle(
                              color: currentThread.nextFollowUpAt != null
                                  ? AppColors.accentGold
                                  : (isLight ? AppColors.lightTextSecondary : Colors.white70),
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
                        color: isLight ? const Color(0xFFEFF6FF) : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isLight ? const Color(0xFFBFDBFE) : const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, size: 12, color: isLight ? const Color(0xFF2563EB) : const Color(0xFF60A5FA)),
                          const SizedBox(width: 4),
                          Text(
                            currentThread.assignedAgent,
                            style: TextStyle(
                              color: isLight ? const Color(0xFF1D4ED8) : const Color(0xFF93C5FD),
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

          // Quick Actions: 1-Tap Quote Builder + Canned Quick Reply Chips
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: isLight ? AppColors.lightBorderSubtle : Colors.transparent)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primaryDark),
                  label: const Text(
                    '⚡ Build & Send Quote',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                  ),
                  backgroundColor: AppColors.accentGold,
                  side: BorderSide.none,
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
                const SizedBox(width: 8),
                ..._getPredictiveReplies(currentThread).map((reply) {
                  final isPredictive = reply['label']!.startsWith('✨');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        reply['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isPredictive ? FontWeight.w800 : FontWeight.w600,
                          color: isPredictive
                              ? (isLight ? const Color(0xFFB45309) : const Color(0xFFFBBF24))
                              : (isLight ? const Color(0xFF1E293B) : Colors.white),
                        ),
                      ),
                      backgroundColor: isPredictive
                          ? (isLight ? const Color(0xFFFEF3C7) : const Color(0xFF78350F).withValues(alpha: 0.35))
                          : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                      side: BorderSide(
                        color: isPredictive
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                            : (isLight ? const Color(0xFFCBD5E1) : Colors.white12),
                        width: isPredictive ? 1.2 : 0.8,
                      ),
                      onPressed: () => _sendMessage(provider, reply['text']),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Input Bar with WhatsApp vs Internal Team Note Mode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1E293B),
              border: Border(top: BorderSide(color: isLight ? AppColors.lightBorderSubtle : Colors.white12)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live Gateway Status & Individual Delivery Warning Banners
                  if (!provider.evolutionOnline) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFFEF2F2) : AppColors.errorRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isLight ? const Color(0xFFF87171) : AppColors.errorRed.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 14, color: isLight ? const Color(0xFFDC2626) : AppColors.errorRed),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'WhatsApp Gateway session disconnected (+91 9336116210)',
                              style: TextStyle(
                                color: isLight ? const Color(0xFF991B1B) : Colors.white70,
                                fontSize: 10.5,
                                fontWeight: isLight ? FontWeight.w600 : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => TelephonyService.openWhatsApp(
                              phoneNumber: currentThread.customerPhone,
                              message: _textController.text.trim(),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: AppColors.whatsappGreen.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.whatsappGreen.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.open_in_new_rounded, size: 10, color: AppColors.whatsappGreen),
                                  SizedBox(width: 3),
                                  Text(
                                    'Open App ↗',
                                    style: TextStyle(color: AppColors.whatsappGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showEvolutionQrSheet(context, provider),
                            child: Text(
                              'QR / Status',
                              style: TextStyle(
                                color: isLight ? const Color(0xFFB45309) : AppColors.accentGold,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (currentThread.lastMessageStatus == 'failed') ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFFFFBEB) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isLight ? const Color(0xFFFCD34D) : const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: isLight ? const Color(0xFFD97706) : const Color(0xFFFBBF24)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Message delivery failed for this recipient (Central Gateway online)',
                              style: TextStyle(
                                color: isLight ? const Color(0xFF92400E) : Colors.white70,
                                fontSize: 10.5,
                                fontWeight: isLight ? FontWeight.w600 : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => TelephonyService.openWhatsApp(
                              phoneNumber: currentThread.customerPhone,
                              message: _textController.text.trim(),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: AppColors.whatsappGreen.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.whatsappGreen.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.open_in_new_rounded, size: 10, color: AppColors.whatsappGreen),
                                  SizedBox(width: 3),
                                  Text(
                                    'Open App ↗',
                                    style: TextStyle(color: AppColors.whatsappGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Mode Selector Pill (WhatsApp vs Internal Whisper)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _isInternalNoteMode = false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: !_isInternalNoteMode
                                    ? (isLight ? const Color(0xFFDCFCE7) : AppColors.whatsappGreen.withValues(alpha: 0.25))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_isInternalNoteMode ? (isLight ? const Color(0xFF22C55E) : AppColors.whatsappGreen) : (isLight ? AppColors.lightBorderSubtle : Colors.white12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_rounded,
                                    size: 11,
                                    color: !_isInternalNoteMode ? (isLight ? const Color(0xFF15803D) : AppColors.whatsappGreen) : (isLight ? AppColors.lightTextMuted : Colors.white38),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'WhatsApp (+91 93361 16210)',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: !_isInternalNoteMode ? FontWeight.bold : FontWeight.normal,
                                      color: !_isInternalNoteMode ? (isLight ? const Color(0xFF15803D) : Colors.white) : (isLight ? AppColors.lightTextSecondary : Colors.white54),
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
                                    ? (isLight ? const Color(0xFFFEF3C7) : const Color(0xFFF59E0B).withValues(alpha: 0.25))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isInternalNoteMode ? const Color(0xFFF59E0B) : (isLight ? AppColors.lightBorderSubtle : Colors.white12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 11,
                                    color: _isInternalNoteMode ? (isLight ? const Color(0xFFB45309) : const Color(0xFFFBBF24)) : (isLight ? AppColors.lightTextMuted : Colors.white38),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Private CRM Note',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: _isInternalNoteMode ? FontWeight.bold : FontWeight.normal,
                                      color: _isInternalNoteMode ? (isLight ? const Color(0xFFB45309) : const Color(0xFFFDE68A)) : (isLight ? AppColors.lightTextSecondary : Colors.white54),
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

                  // Text Field Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _isInternalNoteMode
                                ? 'Add private CRM team note (persisted on server)...'
                                : 'Type WhatsApp message to ${currentThread.displayName}...',
                            hintStyle: TextStyle(color: isLight ? AppColors.lightTextMuted : Colors.white38, fontSize: 13),
                            filled: true,
                            fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: _isInternalNoteMode ? const Color(0xFFF59E0B) : (isLight ? const Color(0xFFCBD5E1) : Colors.transparent),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: _isInternalNoteMode ? const Color(0xFFF59E0B) : (isLight ? const Color(0xFFCBD5E1) : Colors.transparent),
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
            color: Theme.of(context).brightness == Brightness.light ? const Color(0xFFEFF6FF) : const Color(0xFF172554),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).brightness == Brightness.light ? const Color(0xFFBFDBFE) : const Color(0xFF3B82F6).withValues(alpha: 0.45)),
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
            color: Theme.of(context).brightness == Brightness.light ? const Color(0xFFFEF3C7) : const Color(0xFF451A03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).brightness == Brightness.light ? const Color(0xFFFDE68A) : const Color(0xFFF59E0B).withValues(alpha: 0.5)),
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
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isCustomer = msg.isFromCustomer;
    final isWebChat = msg.channel == 'web';
    final isFailed = msg.status == 'failed';

    final hasImage = (msg.mediaType == 'image') ||
        (msg.mediaUrl != null &&
            (msg.mediaUrl!.startsWith('data:image') ||
                msg.mediaUrl!.toLowerCase().contains('.jpg') ||
                msg.mediaUrl!.toLowerCase().contains('.png') ||
                msg.mediaUrl!.toLowerCase().contains('.jpeg') ||
                msg.mediaUrl!.toLowerCase().contains('/tc-media/') ||
                msg.mediaUrl!.toLowerCase().contains('whatsapp.net'))) ||
        msg.text.trim().toLowerCase().startsWith('[photo]') ||
        msg.text.trim().toLowerCase() == '[photo]';

    final hasVideo = (msg.mediaType == 'video') ||
        (msg.mediaUrl != null &&
            (msg.mediaUrl!.toLowerCase().contains('.mp4') ||
                msg.mediaUrl!.toLowerCase().contains('.mov') ||
                msg.mediaUrl!.toLowerCase().contains('.mkv') ||
                msg.mediaUrl!.toLowerCase().contains('.webm'))) ||
        msg.text.trim().toLowerCase().startsWith('[video]') ||
        msg.text.trim().toLowerCase() == '[video]';

    final hasDocument = (msg.mediaType == 'document' || msg.mediaType == 'pdf') ||
        (msg.mediaUrl != null &&
            (msg.mediaUrl!.toLowerCase().contains('.pdf') ||
                msg.mediaUrl!.toLowerCase().contains('.doc') ||
                msg.mediaUrl!.toLowerCase().contains('.docx') ||
                msg.mediaUrl!.toLowerCase().contains('.xls'))) ||
        msg.text.toLowerCase().contains('[document:');

    final cleanText = msg.text
        .replaceFirst(RegExp(r'^\s*\[Photo\]\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\s*\[Video\]\s*', caseSensitive: false), '')
        .trim();
    final shouldShowText = cleanText.isNotEmpty || (!hasImage && !hasVideo && !hasDocument);

    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? (isCustomer ? Colors.white : const Color(0xFFD9FDD3))
            : (isCustomer
                ? (isWebChat ? const Color(0xFF0C4A6E) : const Color(0xFF1E293B))
                : const Color(0xFF065F46)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isCustomer ? 2 : 16),
          bottomRight: Radius.circular(isCustomer ? 16 : 2),
        ),
        border: Border.all(
          color: isFailed
              ? AppColors.errorRed.withValues(alpha: 0.6)
              : (Theme.of(context).brightness == Brightness.light
                  ? (isCustomer ? const Color(0xFFE2E8F0) : const Color(0xFFBBF7D0))
                  : Colors.white10),
          width: isFailed ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
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

          // Visual Photo Rendering
          if (hasImage) ...[
            if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showFullScreenImage(context, msg.mediaUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: msg.mediaUrl!.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(msg.mediaUrl!.split(',').last),
                          fit: BoxFit.cover,
                          height: 190,
                          width: double.infinity,
                        )
                      : Image.network(
                          msg.mediaUrl!,
                          fit: BoxFit.cover,
                          height: 190,
                          width: double.infinity,
                          loadingBuilder: (ctx, child, progress) => progress == null
                              ? child
                              : Container(
                                  height: 190,
                                  color: Theme.of(context).brightness == Brightness.light
                                      ? const Color(0xFFF1F5F9)
                                      : Colors.white10,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold),
                                  ),
                                ),
                          errorBuilder: (context, error, stackTrace) => InkWell(
                            onTap: () => TelephonyService.launchBrowser(msg.mediaUrl!),
                            child: Container(
                              height: 100,
                              color: Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFFF1F5F9)
                                  : Colors.white10,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.photo_rounded, size: 28, color: AppColors.accentGold),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Photo Attachment (Tap to Open)',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.light
                                            ? AppColors.lightTextPrimary
                                            : Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ] else ...[
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFFF8FAFC)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppColors.lightBorderSubtle
                        : Colors.white12,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_rounded, size: 24, color: AppColors.accentGold),
                      const SizedBox(width: 8),
                      Text(
                        'Photo Received',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light
                              ? AppColors.lightTextPrimary
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
          ],

          // Visual Video Rendering
          if (hasVideo) ...[
            GestureDetector(
              onTap: () {
                if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) {
                  TelephonyService.launchBrowser(msg.mediaUrl!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video link is processing or syncing.')),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppColors.lightBorderSubtle
                        : Colors.white24,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.4,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 36),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'Watch Video',
                                style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Visual Document / PDF Card Rendering
          if (hasDocument) ...[
            InkWell(
              onTap: () {
                if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) {
                  TelephonyService.launchBrowser(msg.mediaUrl!);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFFF1F5F9)
                      : Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppColors.lightBorderSubtle
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text.replaceAll('[Document: ', '').replaceAll(']', '').trim().isNotEmpty
                                ? msg.text.replaceAll('[Document: ', '').replaceAll(']', '').trim()
                                : 'PDF Document',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? AppColors.lightTextPrimary
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tap to open / download',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? AppColors.lightTextMuted
                                  : Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      color: Theme.of(context).brightness == Brightness.light
                          ? AppColors.lightTextSecondary
                          : Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Message Text
          if (shouldShowText) ...[
            _buildFormattedMessageText(
              cleanText.isNotEmpty ? cleanText : msg.text,
              TextStyle(
                color: Theme.of(context).brightness == Brightness.light ? const Color(0xFF111B21) : Colors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Metadata Row (Timestamp & Delivery Receipts)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light ? const Color(0xFF667781) : Colors.white38,
                  fontSize: 9.5,
                ),
              ),
              if (!isCustomer) ...[
                const SizedBox(width: 4),
                Icon(
                  isFailed ? Icons.error_outline : Icons.done_all,
                  color: isFailed
                      ? AppColors.errorRed
                      : (msg.status == 'read' ? const Color(0xFF53BDEB) : (Theme.of(context).brightness == Brightness.light ? const Color(0xFF667781) : Colors.white60)),
                  size: 13,
                ),
                if (isFailed) ...[
                  const SizedBox(width: 4),
                  const Text(
                    'Failed • Tap to retry',
                    style: TextStyle(color: AppColors.errorRed, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );

    return Align(
      alignment: isCustomer ? Alignment.centerLeft : Alignment.centerRight,
      child: InkWell(
        onTap: isFailed
            ? () {
                final waProvider = context.read<WhatsAppProvider>();
                final currentThread = waProvider.threads.firstWhere(
                  (th) => th.id == widget.thread.id,
                  orElse: () => widget.thread,
                );
                _showFailedMessageDetailsSheet(context, waProvider, msg, currentThread);
              }
            : null,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showMessageActionsSheet(context, msg, thread);
        },
        borderRadius: BorderRadius.circular(16),
        child: bubble,
      ),
    );
  }

  Widget _buildFormattedMessageText(String text, TextStyle baseStyle) {
    final pattern = RegExp(r'\*([^*]+)\*');
    final matches = pattern.allMatches(text);
    if (matches.isEmpty) {
      return SelectableText(text, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    int currentIndex = 0;
    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      currentIndex = match.end;
    }
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return SelectableText.rich(
      TextSpan(children: spans, style: baseStyle),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.startsWith('data:image')
                      ? Image.memory(base64Decode(imageUrl.split(',').last), fit: BoxFit.contain)
                      : Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Open in Browser / Download',
                    icon: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                    ),
                    onPressed: () => TelephonyService.launchBrowser(imageUrl),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Close',
                    icon: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageActionsSheet(BuildContext context, WhatsAppMessage msg, WhatsAppThread thread) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isSentByMe = !msg.isFromCustomer && !msg.isInternalNote && !msg.isCallEvent;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<WhatsAppProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: isLight ? Colors.black26 : Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              // 1. Copy Message Text
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: AppColors.accentGold),
                title: Text('Copy Message Text', style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(msg.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isLight ? AppColors.lightTextMuted : Colors.white54, fontSize: 11)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.text));
                  Navigator.pop(ctx);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('✓ Message copied to clipboard!'),
                      backgroundColor: AppColors.successGreen,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // 2. Quote / Reply in Chat
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Color(0xFF38BDF8)),
                title: Text('Quote / Reply in Chat', style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _textController.text = '> ${msg.text}\n';
                  });
                },
              ),
              // 3. Delete Message for Everyone (Outbound WhatsApp messages)
              if (isSentByMe) ...[
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.errorRed),
                  title: const Text('Delete for Everyone', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Retract & delete this message from traveler\'s WhatsApp', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
                        title: Text('Delete Message?', style: TextStyle(color: isLight ? AppColors.lightTextPrimary : Colors.white)),
                        content: Text('This will delete this message for everyone in this WhatsApp conversation.', style: TextStyle(color: isLight ? AppColors.lightTextSecondary : Colors.white70)),
                        actions: [
                           TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                           ElevatedButton(
                             style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                             onPressed: () => Navigator.pop(dCtx, true),
                             child: const Text('Delete for Everyone', style: TextStyle(color: Colors.white)),
                           ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final ok = await provider.deleteMessage(
                        threadId: thread.id,
                        messageId: msg.id,
                        remoteJid: thread.remoteJid,
                        phone: thread.customerPhone,
                      );
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(ok ? '✓ Message deleted from WhatsApp' : 'Message removed from view'),
                            backgroundColor: ok ? AppColors.successGreen : Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
