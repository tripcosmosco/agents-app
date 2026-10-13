import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/quote_model.dart';
import '../models/whatsapp_thread_model.dart';
import '../providers/call_provider.dart';
import '../providers/event_provider.dart';
import '../providers/lead_provider.dart';
import '../providers/whatsapp_provider.dart';
import '../services/api_service.dart';
import '../services/telephony_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/live_activity_sheet.dart';
import '../widgets/whatsapp_team_chat_view.dart';
import 'settings_screen.dart';
import 'web_chat_detail_screen.dart';

class WhatsAppHubScreen extends StatefulWidget {
  const WhatsAppHubScreen({super.key});

  @override
  State<WhatsAppHubScreen> createState() => _WhatsAppHubScreenState();
}

class _WhatsAppHubScreenState extends State<WhatsAppHubScreen> {
  late final ApiService _apiService;

  int _selectedTab = 0; // 0 = Superfone WhatsApp & Lead Hub, 1 = Website Live Chat, 2 = Quotes & Brochures
  List<Map<String, dynamic>> _webChats = [];
  bool _isLoadingWebChats = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _targetPhoneController = TextEditingController();
  String _selectedDestination = 'Varanasi 3D2N';
  int _pax = 2;
  String _rateType = 'b2c';

  QuoteModel? _generatedQuote;
  bool _isGeneratingQuote = false;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<LeadProvider>().apiService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WhatsAppProvider>().fetchThreadsFromServer();
      _fetchWebChats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _targetPhoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchWebChats() async {
    setState(() {
      _isLoadingWebChats = true;
    });

    final chats = await _apiService.fetchWebChats();

    if (mounted) {
      setState(() {
        _webChats = chats;
        _isLoadingWebChats = false;
      });
    }
  }

  void _generateQuote() async {
    setState(() {
      _isGeneratingQuote = true;
    });

    final quote = await _apiService.generateQuote(
      destination: _selectedDestination,
      pax: _pax,
      rateType: _rateType,
    );

    if (mounted) {
      setState(() {
        _generatedQuote = quote;
        _isGeneratingQuote = false;
      });
    }
  }

  Future<void> _shareGeneratedQuote() async {
    if (_generatedQuote == null) return;
    final phone = _targetPhoneController.text.trim().isNotEmpty
        ? _targetPhoneController.text.trim()
        : AppConstants.officeJioPhone;

    final delivered = await _apiService.sendWhatsAppMessage(
      phone: phone,
      message: _generatedQuote!.quoteText,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          delivered
              ? '✓ Official quotation dispatched to $phone via WhatsApp (+91 93361 16210)'
              : '⚠️ Quotation queued for delivery to $phone via Official Desk (+91 93361 16210)',
        ),
        backgroundColor: delivered ? AppColors.successGreen : const Color(0xFF1E293B),
      ),
    );
  }

  void _openThread(WhatsAppThread thread, {bool forceFullscreen = false}) {
    final wp = context.read<WhatsAppProvider>();
    wp.selectThread(thread.id);

    final isWide = MediaQuery.of(context).size.width >= 900;
    if (!isWide || forceFullscreen) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: WhatsAppTeamChatView(
                thread: thread,
                onBack: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      );
    }
  }

  void _showNewWhatsAppLeadDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+91 ');
    final circuitCtrl = TextEditingController(text: 'Varanasi & Ayodhya');
    final msgCtrl = TextEditingController(
      text: 'Namaste! 🙏 Sharing your requested TripCosmos Varanasi spiritual tour details.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'New WhatsApp Chat & CRM Lead',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Customer / Agency Name',
                  hintText: 'e.g. Harshal Thakker',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'WhatsApp Phone Number',
                  hintText: '+91 9876543210',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: circuitCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tour Circuit / Requirement',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: msgCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Initial WhatsApp Message (Optional)',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.whatsappGreen,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.chat_rounded, size: 16),
            label: const Text('Open Chat & Save Lead'),
            onPressed: () async {
              final phone = phoneCtrl.text.trim();
              if (phone.length < 8) return;
              final name = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Pilgrim ($phone)';
              final circuit = circuitCtrl.text.trim().isNotEmpty ? circuitCtrl.text.trim() : 'Varanasi';
              final initialMsg = msgCtrl.text.trim();

              Navigator.pop(ctx);

              final wp = context.read<WhatsAppProvider>();
              final leadProv = context.read<LeadProvider>();

              await leadProv.createNewLead(
                name: name,
                phone: phone,
                destination: circuit,
                source: 'whatsapp',
                note: initialMsg,
              );

              final thread = wp.getOrCreateThread(
                customerPhone: phone,
                customerName: name,
                circuit: circuit,
                initialMessage: initialMsg,
              );

              if (initialMsg.isNotEmpty) {
                await wp.sendMessage(thread.id, initialMsg);
              }

              if (mounted) {
                _openThread(thread);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEvolutionGatewayModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FutureBuilder<Map<String, dynamic>?>(
        future: _apiService.fetchEvolutionStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.whatsappGreen),
                    SizedBox(height: 16),
                    Text(
                      'Checking Evolution API Gateway Status...',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          final state = data?['state']?.toString() ?? 'unknown';
          final qr = data?['qr']?.toString() ?? '';
          final pairingCode = data?['pairing_code']?.toString() ?? '';
          final isOpen = data?['is_open'] == true || state == 'open';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isOpen ? AppColors.successGreen : AppColors.errorRed).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isOpen ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded,
                        color: isOpen ? AppColors.successGreen : AppColors.accentGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Evolution WhatsApp Gateway',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'wa.vmstudio.digital • Instance: TripCosmos.co',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (isOpen) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.successGreen, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your WhatsApp session (+91 93361 16210) is active and connected. Real-time message sending and delivery receipts are functioning.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (qr.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions to Link Device:',
                          style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '1. Open WhatsApp on office phone (+91 93361 16210)\n'
                          '2. Tap Settings / 3-dots Menu (⋮) -> Linked Devices\n'
                          '3. Tap "Link a Device" and scan the QR code below:',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Builder(
                        builder: (_) {
                          if (qr.startsWith('http://') || qr.startsWith('https://')) {
                            return Image.network(qr, width: 220, height: 220, fit: BoxFit.contain);
                          }
                          try {
                            final base64String = qr.contains(',') ? qr.split(',').last : qr;
                            final cleanString = base64String.replaceAll(RegExp(r'\s+'), '');
                            final bytes = base64Decode(cleanString);
                            return Image.memory(bytes, width: 220, height: 220, fit: BoxFit.contain);
                          } catch (e) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Error decoding QR: $e', style: const TextStyle(color: Colors.black, fontSize: 11)),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  if (pairingCode.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'Pairing Code: $pairingCode',
                          style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚠️ Session State: Disconnected / Closed',
                          style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Baileys session disconnected on wa.vmstudio.digital. You can initialize a new pairing QR directly from the Evolution web dashboard:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            TelephonyService.launchBrowser('https://wa.vmstudio.digital/manager');
                          },
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Open Evolution Manager Dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whatsappGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<WhatsAppProvider>().fetchThreadsFromServer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      foregroundColor: Colors.white,
                    ),
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

  @override
  Widget build(BuildContext context) {
    final wp = Provider.of<WhatsAppProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.whatsappGreen.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.whatsappGreen.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.hub_rounded, color: AppColors.whatsappGreen, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Superfone WhatsApp & Lead Hub',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: wp.evolutionOnline ? AppColors.successGreen : AppColors.errorRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          wp.evolutionOnline
                              ? 'Evolution Live (+91 93361 16210) • ${wp.threads.length} Threads'
                              : 'Syncing Evolution Gateway...',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
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
          IconButton(
            onPressed: () => LiveActivitySheet.show(context),
            icon: Badge(
              isLabelVisible: eventProvider.activeNowCount > 0,
              backgroundColor: AppColors.successGreen,
              label: Text('${eventProvider.activeNowCount}'),
              child: const Icon(Icons.radar_rounded, color: AppColors.successGreen),
            ),
            tooltip: 'Live Website Visitor Radar',
          ),
          IconButton(
            onPressed: () => _showEvolutionGatewayModal(context),
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              color: wp.evolutionOnline ? AppColors.whatsappGreen : AppColors.errorRed,
            ),
            tooltip: 'WhatsApp Gateway & QR Reconnect',
          ),
          IconButton(
            onPressed: () {
              wp.fetchThreadsFromServer();
              _fetchWebChats();
            },
            icon: const Icon(Icons.refresh, color: AppColors.accentGold),
            tooltip: 'Sync Evolution WhatsApp & CRM',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(apiService: _apiService),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: AppColors.accentGold),
            tooltip: 'Server & Companion Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showNewWhatsAppLeadDialog(context),
              backgroundColor: AppColors.whatsappGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: const Text(
                'New Chat / Lead',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!wp.evolutionOnline)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B0764), Color(0xFF1E1B4B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, color: AppColors.accentGold, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WhatsApp Gateway Disconnected',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            'Office phone (+91 93361 16210) unlinked. Scan QR to restore live messaging.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showEvolutionGatewayModal(context),
                      icon: const Icon(Icons.qr_code_scanner, size: 14),
                      label: const Text('Scan QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.whatsappGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            // Top Mode Switcher Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildTabPill(
                      index: 0,
                      label: 'WhatsApp Hub',
                      badge: '${wp.threads.length}',
                      icon: Icons.chat_bubble_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: _buildTabPill(
                      index: 1,
                      label: 'Web Live',
                      badge: '${_webChats.length}',
                      icon: Icons.language,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _buildTabPill(
                      index: 2,
                      label: 'Quotes',
                      icon: Icons.receipt_long_rounded,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildSuperfoneInboxTab(wp)
                  : (_selectedTab == 1
                      ? _buildWebChatsTab()
                      : _buildBrochuresAndQuotesTab()),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 0: SUPERFONE CENTRAL WHATSAPP & LEAD INBOX
  // ===========================================================================
  Widget _buildSuperfoneInboxTab(WhatsAppProvider wp) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    if (isWide) {
      final activeThread = wp.activeThread;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 400,
            child: _buildThreadsListView(wp, isWide: true),
          ),
          Container(
            width: 1,
            color: AppColors.borderSubtle,
          ),
          Expanded(
            child: activeThread != null
                ? WhatsAppTeamChatView(
                    key: ValueKey(activeThread.id),
                    thread: activeThread,
                  )
                : _buildNoActiveThreadPlaceholder(),
          ),
        ],
      );
    }

    return _buildThreadsListView(wp, isWide: false);
  }

  Widget _buildNoActiveThreadPlaceholder() {
    return Container(
      color: const Color(0xFF0B132B),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.whatsappGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.whatsappGreen.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.forum_rounded, color: AppColors.whatsappGreen, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'TripCosmos Omnichannel Sales Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const Text(
                  'Select a conversation from the left to review traveler history, chat live via official WhatsApp (+91 93361 16210), assign AI Sales Personas, or dispatch itineraries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showNewWhatsAppLeadDialog(context),
                icon: const Icon(Icons.add_comment_rounded, size: 16),
                label: const Text('Start New WhatsApp Chat / Lead'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.whatsappGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThreadsListView(WhatsAppProvider wp, {required bool isWide}) {
    final threads = wp.filteredThreads;

    return Column(
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: _searchController,
            onChanged: wp.setSearchQuery,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by name, +91 phone, circuit, or message...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.accentGold),
              suffixIcon: wp.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        wp.setSearchQuery('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),

        // 2. Superfone Instant Filter Pills
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            children: [
              _buildFilterChip(wp, 'all', 'All (${wp.threads.length})'),
              _buildFilterChip(wp, 'whatsapp', '💬 WhatsApp (${wp.whatsappActiveCount})'),
              _buildFilterChip(wp, 'unread', '🟢 Unread (${wp.totalUnreadCount})'),
              _buildFilterChip(wp, 'new', '🔥 New'),
              _buildFilterChip(wp, 'quoted', '💰 Quoted'),
              _buildFilterChip(wp, 'followup', '⏰ Follow-Up (${wp.followUpDueCount})'),
              _buildFilterChip(wp, 'b2b', '🏢 B2B (${wp.b2bThreadsCount})'),
              _buildFilterChip(wp, 'mine', '👤 My Leads'),
              _buildFilterChip(wp, 'ai_active', '🤖 AI Auto'),
            ],
          ),
        ),

        if (wp.isLoading)
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.whatsappGreen,
            backgroundColor: Colors.transparent,
          ),

        // 3. Unified Thread List
        Expanded(
          child: threads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 48,
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        wp.isLoading
                            ? 'Loading real WhatsApp & CRM threads...'
                            : 'No threads match this filter',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!wp.isLoading)
                        TextButton.icon(
                          onPressed: () {
                            wp.setFilter('all');
                            wp.fetchThreadsFromServer();
                          },
                          icon: const Icon(Icons.refresh, size: 16, color: AppColors.accentGold),
                          label: const Text('Reset Filter & Sync', style: TextStyle(color: AppColors.accentGold)),
                        ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: wp.fetchThreadsFromServer,
                  color: AppColors.whatsappGreen,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 80),
                    itemCount: threads.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final th = threads[index];
                      return _buildSuperfoneThreadTile(th, wp, isWide: isWide);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(WhatsAppProvider wp, String key, String label) {
    final isSelected = wp.filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => wp.setFilter(key),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.whatsappGreen.withValues(alpha: 0.22)
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.whatsappGreen : AppColors.borderSubtle,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuperfoneThreadTile(WhatsAppThread th, WhatsAppProvider wp, {bool isWide = false}) {
    final isB2b = wp.isB2bThread(th);
    final stageColor = _getStageColor(th.stage);
    final timeLabel = th.timeAgo.isNotEmpty
        ? th.timeAgo
        : DateFormat('dd MMM, h:mm a').format(th.lastMessageTime);
    final isSelected = isWide && wp.selectedThreadId == th.id;

    IconData channelIcon = Icons.chat_rounded;
    Color channelColor = AppColors.whatsappGreen;
    if (isB2b) {
      channelIcon = Icons.business_rounded;
      channelColor = Colors.purpleAccent;
    } else if (th.sourceChannel == 'web') {
      channelIcon = Icons.language_rounded;
      channelColor = const Color(0xFF38BDF8);
    } else if (!th.hasWhatsappChat) {
      channelIcon = Icons.person_pin_circle_rounded;
      channelColor = AppColors.accentGold;
    }

    return InkWell(
      onTap: () => _openThread(th),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E293B)
              : (th.unreadCount > 0
                  ? const Color(0xFF13233F)
                  : AppColors.surfaceCard),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.accentGold
                : (th.unreadCount > 0
                    ? AppColors.whatsappGreen.withValues(alpha: 0.6)
                    : AppColors.borderSubtle),
            width: isSelected ? 1.6 : (th.unreadCount > 0 ? 1.3 : 1.0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Time + Call Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Channel Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: isB2b
                          ? Colors.purple.withValues(alpha: 0.25)
                          : AppColors.whatsappGreen.withValues(alpha: 0.18),
                      backgroundImage: th.profilePicUrl.isNotEmpty
                          ? NetworkImage(th.profilePicUrl)
                          : null,
                      child: th.profilePicUrl.isEmpty
                          ? Text(
                              th.initials,
                              style: TextStyle(
                                color: isB2b ? Colors.purpleAccent : AppColors.whatsappGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          border: Border.all(color: channelColor, width: 1),
                        ),
                        child: Icon(channelIcon, size: 10, color: channelColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 11),

                // Customer Name, Phone & Last Message Preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              th.displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: th.unreadCount > 0 ? FontWeight.w800 : FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              color: th.unreadCount > 0 ? AppColors.whatsappGreen : AppColors.textMuted,
                              fontSize: 10.5,
                              fontWeight: th.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        th.customerPhone,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Last Message Row with read ticks
                      Row(
                        children: [
                          if (th.lastMessageFromMe) ...[
                            Icon(
                              Icons.done_all,
                              size: 13,
                              color: th.lastMessageStatus == 'read'
                                  ? Colors.cyanAccent
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              th.lastMessage,
                              style: TextStyle(
                                color: th.unreadCount > 0 ? Colors.white : AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: th.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (th.unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.whatsappGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${th.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // 1-Tap Direct Call Icon Button
                if (th.customerPhone.isNotEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Call ${th.displayName}',
                    onPressed: () {
                      context.read<CallProvider>().startOutboundCall(
                        phone: th.customerPhone,
                        name: th.displayName,
                        tourInterest: th.circuit,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.call_rounded, size: 15, color: AppColors.successGreen),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Bottom Superfone CRM Tags Strip (Stage + Deal Value + Circuit + Follow-Up + Call Count + Owner)
            Wrap(
              spacing: 6,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Stage Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: stageColor.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    th.stageLabel.toUpperCase(),
                    style: TextStyle(
                      color: stageColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                // Deal Value
                if (th.dealValue > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₹${NumberFormat.compact().format(th.dealValue)}',
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                // Circuit / Requirement
                if (th.circuit.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      th.circuit,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Scheduled Follow-Up Alarm
                if (th.nextFollowUpAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '⏰ ${DateFormat('dd MMM, h:mm a').format(th.nextFollowUpAt!)}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                // Call Counter
                if (th.callCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '📞 ${th.callCount} calls',
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                // Assigned Owner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '👤 ${th.assignedAgent}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: LIVE WEBSITE CHATBOT SESSIONS
  // ===========================================================================
  Widget _buildWebChatsTab() {
    if (_isLoadingWebChats) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      );
    }

    if (_webChats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 54,
                color: AppColors.textMuted.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'No active website chatbot sessions right now',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'When visitors message the AI Concierge on tripcosmos.co, their live chat appears here for 1-tap human takeover.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _fetchWebChats,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh Web Chats'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceCard,
                      foregroundColor: AppColors.accentGold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => LiveActivitySheet.show(context),
                    icon: const Icon(Icons.radar_rounded, size: 16),
                    label: const Text('Open Visitor Radar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _webChats.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final chat = _webChats[index];
        final visitorName = chat['customer_name']?.toString() ?? 'Web Visitor';
        final pageUrl = chat['page_url']?.toString() ?? '/';
        final lastMsg = chat['last_message']?.toString() ?? '';
        final isAiActive = chat['is_ai_active'] == true;
        final unread = chat['unread_count'] ?? 0;
        final phone = chat['phone']?.toString() ?? '';

        return GlassCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WebChatDetailScreen(
                  chat: chat,
                  apiService: _apiService,
                ),
              ),
            ).then((_) => _fetchWebChats());
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                visitorName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$unread NEW',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 11, color: AppColors.accentGold),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                pageUrl,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isAiActive
                          ? AppColors.accentGold.withValues(alpha: 0.15)
                          : AppColors.successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAiActive
                            ? AppColors.accentGold.withValues(alpha: 0.4)
                            : AppColors.successGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAiActive ? Icons.smart_toy : Icons.person,
                          size: 11,
                          color: isAiActive ? AppColors.accentGold : AppColors.successGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAiActive ? 'AI Replying' : 'Human Live',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isAiActive ? AppColors.accentGold : AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  '"$lastMsg"',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WebChatDetailScreen(
                              chat: chat,
                              apiService: _apiService,
                            ),
                          ),
                        ).then((_) => _fetchWebChats());
                      },
                      icon: const Icon(Icons.chat, size: 14),
                      label: const Text('Live Chat & Takeover', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAiActive ? const Color(0xFF0284C7) : AppColors.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        TelephonyService.dialNumber(phone);
                      },
                      icon: const Icon(Icons.call, size: 14, color: AppColors.accentGold),
                      label: const Text('Call Jio ₹0', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: const BorderSide(color: AppColors.accentGold),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabPill({
    required int index,
    required String label,
    String? badge,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.whatsappGreen.withValues(alpha: 0.2)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.whatsappGreen : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.whatsappGreen : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null && badge != '0') ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.whatsappGreen : AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'won':
      case 'advance_received':
        return AppColors.successGreen;
      case 'qualified':
      case 'quote_sent':
      case 'proposal':
        return AppColors.accentGold;
      case 'b2b_partner':
        return Colors.purpleAccent;
      case 'lost':
        return AppColors.errorRed;
      default:
        return const Color(0xFF38BDF8);
    }
  }

  // ===========================================================================
  // TAB 2: 1-TAP BROCHURES & DYNAMIC TARIFF QUOTE ENGINE
  // ===========================================================================
  Widget _buildBrochuresAndQuotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.person_pin,
                  color: AppColors.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _targetPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Customer WhatsApp Phone (e.g. 9876543210)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            '1-TAP PILGRIMAGE BROCHURES',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          ...AppConstants.quickBrochures.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['title']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accentGold.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item['badge']!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['summary']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['price']!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentGold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final phone =
                                _targetPhoneController.text.trim().isNotEmpty
                                    ? _targetPhoneController.text.trim()
                                    : AppConstants.officeJioPhone;
                            final message =
                                "Namaste! 🙏 Here is the requested TripCosmos itinerary:\n\n*${item['title']}*\nRate: ${item['price']}\nInclusions: ${item['summary']}\n\nShall I reserve your booking slot?";
                            final delivered = await _apiService.sendWhatsAppMessage(
                              phone: phone,
                              message: message,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    delivered
                                        ? '✓ Itinerary sent to $phone via Official WhatsApp (+91 93361 16210)'
                                        : '⚠️ Itinerary queued for delivery to $phone via Official WhatsApp',
                                  ),
                                  backgroundColor: delivered ? AppColors.successGreen : const Color(0xFF1E293B),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text('Send In-App'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whatsappGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 18),

          const Text(
            'DYNAMIC TARIFF & QUOTE ENGINE',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: const ['Varanasi 3D2N', 'Varanasi Ayodhya 4D3N', 'Kashi Gaya Bodhgaya 4D', 'Prayagraj Sangam Day Trip'].contains(_selectedDestination)
                      ? _selectedDestination
                      : 'Varanasi 3D2N',
                  decoration: const InputDecoration(
                    labelText: 'Select Tour Circuit',
                    isDense: true,
                  ),
                  dropdownColor: AppColors.surfaceCard,
                  items: const [
                    DropdownMenuItem(
                      value: 'Varanasi 3D2N',
                      child: Text('Varanasi Spiritual 3D2N'),
                    ),
                    DropdownMenuItem(
                      value: 'Varanasi Ayodhya 4D3N',
                      child: Text('Varanasi + Ayodhya 4D3N'),
                    ),
                    DropdownMenuItem(
                      value: 'Kashi Gaya Bodhgaya 4D',
                      child: Text('Kashi + Gaya + Bodhgaya 4D'),
                    ),
                    DropdownMenuItem(
                      value: 'Prayagraj Sangam Day Trip',
                      child: Text('Prayagraj Sangam Day Trip'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDestination = val);
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: (_pax >= 1 && _pax <= 10) ? _pax : 2,
                        decoration: const InputDecoration(
                          labelText: 'No. of Pax',
                          isDense: true,
                        ),
                        dropdownColor: AppColors.surfaceCard,
                        items: List.generate(
                          10,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('${i + 1} Guests'),
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null) setState(() => _pax = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: const ['b2c', 'b2b'].contains(_rateType) ? _rateType : 'b2c',
                        decoration: const InputDecoration(
                          labelText: 'Rate Type',
                          isDense: true,
                        ),
                        dropdownColor: AppColors.surfaceCard,
                        items: const [
                          DropdownMenuItem(
                            value: 'b2c',
                            child: Text('B2C Retail'),
                          ),
                          DropdownMenuItem(
                            value: 'b2b',
                            child: Text('B2B Net Partner'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _rateType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGeneratingQuote ? null : _generateQuote,
                    child: _isGeneratingQuote
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryDark,
                            ),
                          )
                        : const Text('Calculate Tariff & Quote'),
                  ),
                ),

                if (_generatedQuote != null) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Tariff: ₹${_generatedQuote!.pricing}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGold,
                            ),
                          ),
                          Text(
                            'Advance Token: ₹${_generatedQuote!.advanceRequired}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _shareGeneratedQuote,
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Send WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.whatsappGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
