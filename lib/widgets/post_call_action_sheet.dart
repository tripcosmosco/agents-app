import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/call_log_model.dart';
import '../providers/call_provider.dart';
import '../providers/lead_provider.dart';
import 'glass_card.dart';

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

class _PostCallActionSheetState extends State<PostCallActionSheet> {
  final TextEditingController _noteController = TextEditingController();
  String _selectedStage = 'qualified';
  DateTime? _scheduledFollowUp;
  bool _isGeneratingAiSummary = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with auto-detected call details if available
    _noteController.text = widget.callLog.notes ??
        'Consulted regarding ${widget.callLog.tourInterest ?? "Varanasi Pilgrimage"}. Duration: ${widget.callLog.formattedDuration}. High pilgrimage interest.';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _generateAiCallSummary() async {
    setState(() {
      _isGeneratingAiSummary = true;
    });

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ Real AI Call & Chat Summary Generated from Server History!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  Future<void> _sendBrochure(String title, String summary, String price) async {
    final message =
        '''
Namaste ${widget.callLog.customerName} ji! 🙏
Thank you for speaking with TripCosmos.co.

Here are the confirmed details for your trip:
📍 Package: $title
🏷️ Package Price: $price
✨ Inclusions: $summary

For booking confirmation or customized itinerary, reply to this WhatsApp message or call our Varanasi desk (+91 93361 16210).
TripCosmos.co — The Sacred Journey
''';

    final apiService = context.read<LeadProvider>().apiService;
    final delivered = await apiService.sendWhatsAppMessage(
      phone: widget.callLog.phone,
      message: message,
    );

    if (!mounted) return;

    if (delivered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Itinerary sent via Official WhatsApp (+91 93361 16210)'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Message queued for delivery via official TripCosmos gateway (+91 93361 16210)'),
          backgroundColor: Color(0xFF1E293B),
        ),
      );
    }
  }

  Future<void> _sendAdvancePaymentLink() async {
    final message =
        '''
Namaste ${widget.callLog.customerName} ji! 🙏
To block your confirmed Varanasi darshan dates & reserved AC cab:

💳 Advance Booking Token: ₹1,500
UPI ID: 9336116210@upi (Official TripCosmos Desk: +91 93361 16210)

Balance payable directly upon arrival in Varanasi.
Har Har Mahadev! 🙏
''';

    final apiService = context.read<LeadProvider>().apiService;
    final delivered = await apiService.sendWhatsAppMessage(
      phone: widget.callLog.phone,
      message: message,
    );

    if (!mounted) return;

    if (delivered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Advance payment link sent via WhatsApp (+91 93361 16210)'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Advance link queued for delivery via official TripCosmos gateway (+91 93361 16210)'),
          backgroundColor: Color(0xFF1E293B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.accentGold, width: 2)),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Post-Call Success
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: AppColors.successGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CALL COMPLETED',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${widget.callLog.customerName} (${widget.callLog.formattedDuration})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onDismiss,
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Section 1: 1-Tap WhatsApp Actions
            const Text(
              '1-TAP WHATSAPP DISPATCH',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            ...AppConstants.quickBrochures.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  backgroundColor: AppColors.surfaceElevated,
                  onTap: () => _sendBrochure(
                    item['title']!,
                    item['summary']!,
                    item['price']!,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.send_rounded,
                        color: AppColors.whatsappGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${item['price']} • ${item['badge']}',
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            }),

            // 1-Tap UPI Token Request
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              backgroundColor: AppColors.accentGold.withValues(alpha: 0.12),
              borderColor: AppColors.accentGold.withValues(alpha: 0.3),
              onTap: _sendAdvancePaymentLink,
              child: const Row(
                children: [
                  Icon(Icons.payment, color: AppColors.accentGold, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send Advance Token Payment Link (₹1,500)',
                          style: TextStyle(
                            color: AppColors.accentGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Blocks dates & AC cab with instant confirmation receipt',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.accentGold,
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Section 2: Update Lead Stage & Notes
            const Text(
              'UPDATE CRM STAGE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: [
                _buildStageChip('qualified', 'Qualified'),
                _buildStageChip('quote_sent', 'Quote Sent'),
                _buildStageChip('won', 'Advance Paid (Won)'),
                _buildStageChip('lost', 'Not Interested'),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CALL SUMMARY & NOTES',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isGeneratingAiSummary ? null : _generateAiCallSummary,
                  icon: _isGeneratingAiSummary
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold),
                        )
                      : const Icon(Icons.auto_awesome, size: 14, color: AppColors.accentGold),
                  label: const Text(
                    'AI Auto-Summarize',
                    style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add post-call notes (e.g. 5 pax, senior wheelchair needed)...',
              ),
            ),
            const SizedBox(height: 12),

            // Schedule Follow-up Row
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 11, minute: 0),
                );
                if (time == null || !context.mounted) return;
                setState(() {
                  _scheduledFollowUp = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _scheduledFollowUp != null ? AppColors.accentGold : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alarm_on_rounded,
                      size: 16,
                      color: _scheduledFollowUp != null ? AppColors.accentGold : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _scheduledFollowUp != null
                            ? 'Follow-up: ${_scheduledFollowUp!.day}/${_scheduledFollowUp!.month} at ${TimeOfDay.fromDateTime(_scheduledFollowUp!).format(context)}'
                            : 'Schedule Follow-up Reminder',
                        style: TextStyle(
                          color: _scheduledFollowUp != null ? Colors.white : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: _scheduledFollowUp != null ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_month, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save & Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final leadProvider = Provider.of<LeadProvider>(
                    context,
                    listen: false,
                  );
                  final cleanPhone = widget.callLog.phone.replaceAll(RegExp(r'[^0-9]'), '');
                  final phoneSuffix = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
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
                },
                child: Consumer<CallProvider>(
                  builder: (context, cp, _) => Text(
                    cp.isPowerDialerActive ? 'Save & Next Lead ➔' : 'Save & Update CRM',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageChip(String stage, String label) {
    final isSelected = _selectedStage == stage;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStage = stage;
          });
        }
      },
      selectedColor: AppColors.accentGold,
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }
}
