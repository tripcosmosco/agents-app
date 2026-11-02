import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/call_log_model.dart';
import '../models/lead_model.dart';
import '../providers/call_provider.dart';
import '../providers/lead_provider.dart';
import '../screens/quotation_desk_screen.dart';
import '../services/telephony_service.dart';

class PostCallActionSheet extends StatefulWidget {
  final CallLogModel callLog;
  final VoidCallback onDismiss;

  const PostCallActionSheet({
    super.key,
    required this.callLog,
    required this.onDismiss,
  });

  @override
  State<PostCallActionSheet> createState() => _PostCallActionSheetState();
}

class _PostCallActionSheetState extends State<PostCallActionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();

  late String _selectedStage;
  DateTime? _scheduledFollowUp;
  bool _isGeneratingAiSummary = false;
  String? _sendingActionId;
  final Set<String> _dispatchedActionIds = {};

  final List<String> _quickNoteTags = [
    '♿ Wheelchair Needed',
    '🥗 Pure Veg / Jain',
    '🚩 Sugam Darshan VIP',
    '🪔 Aarti Boat Request',
    '✈️ Airport Transfer',
    '🏨 4★ Deluxe Hotel',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final isZeroDuration = widget.callLog.durationSeconds <= 0;
    _selectedStage = isZeroDuration ? 'follow_up' : 'qualified';

    if (widget.callLog.notes != null && widget.callLog.notes!.isNotEmpty) {
      _noteController.text = widget.callLog.notes!;
    } else if (isZeroDuration) {
      _noteController.text =
          'Outbound call unanswered (0s). Scheduled callback required.';
    } else {
      _noteController.text =
          'Consulted regarding ${widget.callLog.tourInterest ?? "Varanasi Pilgrimage"}. Duration: ${widget.callLog.formattedDuration}. Interested in customized itinerary.';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _copyPhoneNumber() {
    Clipboard.setData(ClipboardData(text: widget.callLog.phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Copied phone: ${widget.callLog.phone}'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  void _redialCustomer() {
    TelephonyService.dialNumber(widget.callLog.phone);
  }

  Future<void> _generateAiCallSummary() async {
    setState(() => _isGeneratingAiSummary = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final apiService = context.read<LeadProvider>().apiService;
      final summary = await apiService.summarizeCallWithAi(
        phone: widget.callLog.phone,
        customerName: widget.callLog.customerName,
        circuit: widget.callLog.tourInterest ?? 'Varanasi Spiritual Circuit',
        durationSeconds: widget.callLog.durationSeconds,
        notes: _noteController.text,
      );

      if (!mounted) return;
      setState(() {
        _isGeneratingAiSummary = false;
        if (summary != null && summary.isNotEmpty) {
          _noteController.text = summary;
        }
        _selectedStage = 'quote_sent';
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('✨ AI Call & Intent Summary generated!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isGeneratingAiSummary = false);
    }
  }

  Future<void> _sendDirectWhatsApp() async {
    final isMissed = widget.callLog.durationSeconds <= 0;
    final message = isMissed
        ? '''Namaste ${widget.callLog.customerName} ji! 🙏
Greetings from TripCosmos.co Varanasi Desk (+91 93361 16210).

We just tried reaching you regarding your tour inquiry. Please let us know a convenient time to speak, or reply with your travel dates and requirements here!'''
        : '''Namaste ${widget.callLog.customerName} ji! 🙏
Thank you for speaking with TripCosmos.co regarding your ${widget.callLog.tourInterest ?? "Varanasi Pilgrimage"}.

I am your dedicated tour coordinator from our Varanasi desk (+91 93361 16210). Let me know if you would like me to share hotel options, VIP darshan passes, or a dedicated AC cab itinerary!''';

    await TelephonyService.openWhatsApp(
      phoneNumber: widget.callLog.phone,
      message: message,
    );
  }

  Future<void> _sendBrochure(
    String id,
    String title,
    String summary,
    String price,
  ) async {
    if (_sendingActionId != null) return;
    setState(() => _sendingActionId = id);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final apiService = context.read<LeadProvider>().apiService;
      final delivered = await apiService.sendWhatsAppButtons(
        phone: widget.callLog.phone,
        title: '📍 *$title*',
        description:
            'Namaste ${widget.callLog.customerName} ji! 🙏\n\nConfirmed details for your trip:\n🏷️ Price: $price\n✨ Inclusions: $summary\n\nTap an instant action below:',
        buttons: [
          {'id': 'btn_book', 'text': '1️⃣ Confirm & Block Cab'},
          {'id': 'btn_call', 'text': '2️⃣ Call Varanasi Desk'},
          {'id': 'btn_pay', 'text': '💳 Pay Token ₹1,500'},
        ],
        footer: 'TripCosmos.co • Official Desk (+91 93361 16210)',
      );

      if (!mounted) return;
      setState(() {
        _sendingActionId = null;
        _dispatchedActionIds.add(id);
        if (_selectedStage == 'qualified' || _selectedStage == 'follow_up') {
          _selectedStage = 'quote_sent';
        }
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            delivered
                ? '✓ $title sent via WhatsApp!'
                : '⚠️ Queued for dispatch via Varanasi Gateway (+91 93361 16210)',
          ),
          backgroundColor:
              delivered ? AppColors.successGreen : const Color(0xFF1E293B),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _sendingActionId = null);
    }
  }

  Future<void> _sendAdvancePaymentLink() async {
    if (_sendingActionId != null) return;
    setState(() => _sendingActionId = 'advance_token');
    final messenger = ScaffoldMessenger.of(context);

    try {
      final apiService = context.read<LeadProvider>().apiService;
      final delivered = await apiService.sendWhatsAppButtons(
        phone: widget.callLog.phone,
        title: '💳 *Block Cab & Confirm Dates (₹1,500 Token)*',
        description:
            'Namaste ${widget.callLog.customerName} ji! 🙏\n\nTo block your confirmed Varanasi darshan dates & reserved AC cab:\n\n💳 Advance Booking Token: ₹1,500\nUPI ID: 9336116210@upi\n\nBalance payable upon arrival in Varanasi.',
        buttons: [
          {'id': 'btn_paid', 'text': '✅ I have Paid ₹1,500'},
          {'id': 'btn_qr', 'text': '📲 Send UPI QR Code'},
          {'id': 'btn_call', 'text': '📞 Call Varanasi Desk'},
        ],
        footer: 'TripCosmos.co • Official Desk (+91 93361 16210)',
      );

      if (!mounted) return;
      setState(() {
        _sendingActionId = null;
        _dispatchedActionIds.add('advance_token');
        if (_selectedStage == 'qualified' || _selectedStage == 'quote_sent') {
          _selectedStage = 'quote_sent';
        }
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            delivered
                ? '✓ Advance token link dispatched via WhatsApp!'
                : '⚠️ Link queued for delivery via TripCosmos gateway',
          ),
          backgroundColor:
              delivered ? AppColors.successGreen : const Color(0xFF1E293B),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _sendingActionId = null);
    }
  }

  void _quickSetFollowUp(Duration offset) {
    final target = DateTime.now().add(offset);
    setState(() {
      _scheduledFollowUp = target;
      if (_selectedStage == 'qualified') {
        _selectedStage = 'follow_up';
      }
    });
  }

  void _setSpecificFollowUp({required int hour, required int minute, int daysAhead = 0}) {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: daysAhead));
    setState(() {
      _scheduledFollowUp = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      );
      if (_selectedStage == 'qualified') {
        _selectedStage = 'follow_up';
      }
    });
  }

  void _addNoteTag(String tag) {
    final current = _noteController.text.trim();
    if (current.contains(tag)) return;
    setState(() {
      _noteController.text = current.isEmpty ? tag : '$current • $tag';
    });
  }

  void _saveAndClose() {
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    final cleanPhone = widget.callLog.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneSuffix = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;

    final existingLead = leadProvider.leads.where((l) {
      final lp = l.phone.replaceAll(RegExp(r'[^0-9]'), '');
      return phoneSuffix.isNotEmpty && lp.endsWith(phoneSuffix);
    }).firstOrNull;

    if (existingLead != null) {
      leadProvider.updateLeadStage(existingLead.id, _selectedStage);
      if (_noteController.text.trim().isNotEmpty) {
        leadProvider.addLeadNote(existingLead.id, _noteController.text.trim());
      }
      if (_scheduledFollowUp != null) {
        leadProvider.scheduleFollowUp(existingLead.id, _scheduledFollowUp!);
      }
    } else {
      leadProvider.createNewLead(
        name: widget.callLog.customerName,
        phone: widget.callLog.phone,
        destination: widget.callLog.tourInterest ?? 'Varanasi',
        source: 'phone_call',
        stage: _selectedStage,
        note: _noteController.text.trim(),
        nextFollowUpAt: _scheduledFollowUp,
      );
    }

    final callProvider = Provider.of<CallProvider>(context, listen: false);
    widget.onDismiss();
    if (callProvider.isPowerDialerActive) {
      callProvider.nextPowerDialerLead();
    }
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isZeroDuration = widget.callLog.durationSeconds <= 0;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.accentGold, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Caller Dossier Header
          _buildHeader(isZeroDuration),

          // 3. Segmented Navigation Tabs
          _buildTabBar(),

          // 4. Tab Body Content
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWhatsAppTab(isZeroDuration),
                _buildCrmTab(),
              ],
            ),
          ),

          // 5. Persistent Bottom Action Bar
          _buildPersistentFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isZeroDuration) {
    final durationLabel = widget.callLog.formattedDuration;
    final statusColor =
        isZeroDuration ? const Color(0xFFF87171) : AppColors.successGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isZeroDuration ? Icons.call_missed : Icons.call_end,
                      color: statusColor,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isZeroDuration
                          ? 'UNANSWERED (0s)'
                          : 'COMPLETED ($durationLabel)',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Quick Actions: Copy Phone & Redial
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                color: AppColors.textSecondary,
                tooltip: 'Copy Phone',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: _copyPhoneNumber,
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.phone_forwarded_rounded, size: 16),
                color: AppColors.accentGold,
                tooltip: 'Redial Customer',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: _redialCustomer,
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textMuted,
                tooltip: 'Dismiss',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: widget.onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Customer Identity Row
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.accentGold.withValues(alpha: 0.15),
                child: Text(
                  widget.callLog.customerName.isNotEmpty
                      ? widget.callLog.customerName[0].toUpperCase()
                      : 'T',
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.callLog.customerName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.callLog.phone} • ${widget.callLog.tourInterest ?? "Varanasi Pilgrimage"}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF070D1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.accentGold,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            icon: Icon(Icons.send_rounded, size: 14),
            text: '1-Tap WhatsApp',
          ),
          Tab(
            icon: Icon(Icons.assignment_turned_in_rounded, size: 14),
            text: 'CRM Disposition',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: WhatsApp Dispatches
  // ---------------------------------------------------------------------------

  Widget _buildWhatsAppTab(bool isZeroDuration) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      physics: const BouncingScrollPhysics(),
      children: [
        // Hero 1: Direct WhatsApp Chat
        _buildHeroWhatsAppCard(isZeroDuration),
        const SizedBox(height: 10),

        // Section Title: Quick Itinerary Brochures
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOP SPIRITUAL CIRCUITS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '1-Tap Interactive Buttons',
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2x2 Grid of Package Cards
        _buildPackageGrid(),
        const SizedBox(height: 10),

        // Action 1: Open Full Quotation Builder
        _buildQuotationBuilderCard(),
        const SizedBox(height: 8),

        // Action 2: Advance Token Payment Link
        _buildTokenPaymentCard(),
      ],
    );
  }

  Widget _buildHeroWhatsAppCard(bool isZeroDuration) {
    return InkWell(
      onTap: _sendDirectWhatsApp,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.whatsappGreen.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.whatsappGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isZeroDuration
                        ? 'Send Missed-Call Recovery WhatsApp'
                        : 'Direct WhatsApp Chat with Traveler',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isZeroDuration
                        ? 'One-tap polite greeting & callback prompt via WhatsApp'
                        : 'Opens official WhatsApp with personalized greeting',
                    style: const TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              color: AppColors.whatsappGreen,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageGrid() {
    final brochures = AppConstants.quickBrochures;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: brochures.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 110,
      ),
      itemBuilder: (context, index) {
        final item = brochures[index];
        final id = item['id'] ?? 'item_$index';
        final isSending = _sendingActionId == id;
        final isDispatched = _dispatchedActionIds.contains(id);

        return InkWell(
          onTap: isSending
              ? null
              : () => _sendBrochure(
                    id,
                    item['title']!,
                    item['summary']!,
                    item['price']!,
                  ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDispatched
                  ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDispatched
                    ? AppColors.successGreen
                    : const Color(0xFF334155),
                width: isDispatched ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Badge & Send State
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['badge'] ?? 'Verified',
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isSending)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentGold,
                        ),
                      )
                    else if (isDispatched)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.successGreen,
                        size: 15,
                      )
                    else
                      const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF38BDF8),
                        size: 13,
                      ),
                  ],
                ),

                // Title
                Text(
                  item['title']!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Price & Action prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['price']!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentGold,
                      ),
                    ),
                    Text(
                      isDispatched ? 'Sent ✓' : 'Send ➔',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isDispatched
                            ? AppColors.successGreen
                            : const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuotationBuilderCard() {
    return InkWell(
      onTap: () {
        widget.onDismiss();
        QuotationDeskScreen.open(
          context,
          LeadModel(
            id: 'call_${widget.callLog.phone}',
            name: widget.callLog.customerName,
            phone: widget.callLog.phone,
            destination: widget.callLog.tourInterest ?? 'Varanasi',
            pax: 2,
            source: 'telephony',
            stage: _selectedStage,
            createdAt: DateTime.now(),
            notes: _noteController.text.trim().isNotEmpty
                ? [_noteController.text.trim()]
                : [],
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_fix_high_rounded, color: Color(0xFF60A5FA), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚡ Open Full Quotation Desk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Customize 2D–5D itinerary, hotels, fleet & calculate margin',
                    style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF60A5FA), size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenPaymentCard() {
    final isSending = _sendingActionId == 'advance_token';
    final isDispatched = _dispatchedActionIds.contains('advance_token');

    return InkWell(
      onTap: isSending ? null : _sendAdvancePaymentLink,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF451A03), Color(0xFF0F172A)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDispatched
                ? AppColors.successGreen
                : const Color(0xFFD97706).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDispatched ? Icons.check_circle_rounded : Icons.payment_rounded,
              color: isDispatched ? AppColors.successGreen : const Color(0xFFFBBF24),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDispatched
                        ? 'Token Payment Link Sent ✓'
                        : 'Send Advance Token Payment Link (₹1,500)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Blocks travel dates & dedicated cab with instant receipt',
                    style: TextStyle(color: Color(0xFFFDE68A), fontSize: 10.5),
                  ),
                ],
              ),
            ),
            if (isSending)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFBBF24)),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFBBF24), size: 12),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: CRM Disposition & Follow-Up
  // ---------------------------------------------------------------------------

  Widget _buildCrmTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Stage Selection
        const Text(
          'UPDATE CRM STAGE',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildStageTile('qualified', '🎯 Qualified', const Color(0xFF38BDF8)),
            _buildStageTile('quote_sent', '📤 Quote Sent', const Color(0xFFA855F7)),
            _buildStageTile('follow_up', '⏳ Follow-Up', const Color(0xFFFBBF24)),
            _buildStageTile('won', '🏆 Advance Paid', const Color(0xFF34D399)),
            _buildStageTile('lost', '❌ Lost / Junk', const Color(0xFFF87171)),
          ],
        ),
        const SizedBox(height: 16),

        // 2. 1-Tap Quick Follow-up Reminder Presets
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SCHEDULE CALLBACK',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            if (_scheduledFollowUp != null)
              InkWell(
                onTap: () => setState(() => _scheduledFollowUp = null),
                child: const Text(
                  'Clear Reminder ✕',
                  style: TextStyle(color: Color(0xFFF87171), fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Follow-up status card (if set)
        if (_scheduledFollowUp != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm_on_rounded, size: 14, color: AppColors.accentGold),
                const SizedBox(width: 6),
                Text(
                  'Reminder set for ${_scheduledFollowUp!.day}/${_scheduledFollowUp!.month} at ${TimeOfDay.fromDateTime(_scheduledFollowUp!).format(context)}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Quick Preset Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetChip('+30 mins', () => _quickSetFollowUp(const Duration(minutes: 30))),
              _buildPresetChip('Today 4 PM', () => _setSpecificFollowUp(hour: 16, minute: 0)),
              _buildPresetChip('Tomorrow 11 AM', () => _setSpecificFollowUp(hour: 11, minute: 0, daysAhead: 1)),
              _buildPresetChip('In 2 Days', () => _setSpecificFollowUp(hour: 11, minute: 0, daysAhead: 2)),
              _buildPresetChip('📅 Custom Date', _pickCustomDateTime),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. AI Call Summary & Quick Tags
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CALL SUMMARY & NOTES',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            InkWell(
              onTap: _isGeneratingAiSummary ? null : _generateAiCallSummary,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    if (_isGeneratingAiSummary)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black),
                      )
                    else
                      const Icon(Icons.auto_awesome, size: 11, color: Colors.black),
                    const SizedBox(width: 4),
                    const Text(
                      'AI Summarize',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Quick Note Tags
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickNoteTags.map((tag) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => _addNoteTag(tag),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Note Input Field
        TextField(
          controller: _noteController,
          maxLines: 3,
          style: const TextStyle(fontSize: 12.5, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter call takeaways, traveler group size, budget...',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accentGold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStageTile(String stage, String label, Color color) {
    final isSelected = _selectedStage == stage;

    return InkWell(
      onTap: () => setState(() => _selectedStage = stage),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF334155),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 11, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledFollowUp = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (_selectedStage == 'qualified') {
        _selectedStage = 'follow_up';
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 5. Persistent Sticky Bottom Bar
  // ---------------------------------------------------------------------------

  Widget _buildPersistentFooter() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),
      decoration: const BoxDecoration(
        color: Color(0xFF070D1E),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Row(
        children: [
          // Quick Flip Tab button
          InkWell(
            onTap: () {
              final nextIndex = _tabController.index == 0 ? 1 : 0;
              _tabController.animateTo(nextIndex);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final isTabZero = _tabController.index == 0;
                  return Row(
                    children: [
                      Icon(
                        isTabZero ? Icons.assignment_rounded : Icons.chat_rounded,
                        size: 15,
                        color: AppColors.accentGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTabZero ? 'CRM Notes ➔' : '← WhatsApp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Primary CRM Save Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveAndClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: Consumer<CallProvider>(
                builder: (context, cp, _) => Text(
                  cp.isPowerDialerActive ? 'Save & Next Lead ➔' : 'Save & Update CRM',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
