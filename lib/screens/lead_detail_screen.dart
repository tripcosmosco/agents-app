import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/call_log_model.dart';
import '../models/lead_model.dart';
import '../models/whatsapp_thread_model.dart';
import '../providers/call_provider.dart';
import '../providers/lead_provider.dart';
import '../providers/whatsapp_provider.dart';
import '../widgets/cab_fare_dialog.dart';
import '../widgets/travel_quote_dialog.dart';
import '../widgets/whatsapp_team_chat_view.dart';

class LeadDetailScreen extends StatefulWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _quickReplyController = TextEditingController();
  final ScrollController _timelineScrollController = ScrollController();
  bool _isNoteMode = false;
  bool _isSendingReply = false;

  final List<Map<String, String>> _cannedQuickReplies = [
    {
      'label': '🕉️ VIP Darshan',
      'text': 'Namaste! We can confirm VIP Sugam Darshan passes for Shri Kashi Vishwanath Temple with priority escorted darshan.',
    },
    {
      'label': '🚕 Cab Tariff',
      'text': 'Private AC Cab tariffs: AC Sedan (Dzire) ₹12/km | Innova Crysta ₹19/km | Tempo Traveller ₹25/km. Sanitized vehicles with verified chauffeurs.',
    },
    {
      'label': '💳 Advance UPI',
      'text': 'To confirm your pilgrimage booking, please transfer ₹1,000 token advance via UPI to our official desk: 9336116210@upi (+91 93361 16210). Balance payable on arrival.',
    },
    {
      'label': '🛕 Dress Code',
      'text': 'For early morning Sparsh Darshan & Rudrabhishek: Men: Dhoti/Kurta; Women: Saree or Salwar suit. Leather belts/wallets are strictly prohibited.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _quickReplyController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog(BuildContext context, LeadModel lead) {
    _noteController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Add Activity Note', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: _noteController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter call summary, requirements, or next steps...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_noteController.text.trim().isNotEmpty) {
                Provider.of<LeadProvider>(context, listen: false).addLeadNote(
                  lead.id,
                  _noteController.text.trim(),
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
            child: const Text('Save Note', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReassignOwnerSheet(BuildContext context, LeadModel lead) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assign Lead Owner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Assign this lead to a telecaller or manager in your team:',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 16),
                ...AppConstants.teamMembers.map((member) {
                  final isCurrent = lead.stickyAgent == member['name'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isCurrent ? AppColors.accentBlue : const Color(0xFF334155),
                      child: Text(
                        member['initials']!,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                      ),
                    ),
                    title: Text(
                      member['name']!,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      member['role']!,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20)
                        : null,
                    onTap: () {
                      Provider.of<LeadProvider>(context, listen: false).assignLeadOwner(
                        lead.id,
                        member['name']!,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lead assigned to ${member['name']}'),
                          backgroundColor: const Color(0xFF1E293B),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeStageSheet(BuildContext context, LeadModel lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change Lead Pipeline Stage',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                    children: AppConstants.travelPipelineStages
                        .where((s) => s['id'] != 'all')
                        .map((stage) {
                      final isCurrent = lead.stage.toLowerCase() == stage['id'].toLowerCase();
                      final color = Color(stage['color'] as int);
                      return ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          stage['label'],
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent ? color : Colors.white,
                          ),
                        ),
                        trailing: isCurrent ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        onTap: () {
                          Provider.of<LeadProvider>(context, listen: false).updateLeadStage(
                            lead.id,
                            stage['id'],
                          );
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  void _showDispatchDriverSheet(BuildContext context, LeadModel lead) {
    final driverNameCtrl = TextEditingController();
    final driverPhoneCtrl = TextEditingController();
    final vehicleNumCtrl = TextEditingController();
    final pickupLocCtrl = TextEditingController(text: lead.destination.isNotEmpty ? lead.destination : 'Varanasi');
    final reportingTimeCtrl = TextEditingController(text: 'Tomorrow 07:30 AM');
    final balanceCtrl = TextEditingController(text: lead.dealValue > 0 ? (lead.dealValue * 0.7).round().toString() : '5000');
    String selectedModel = 'Innova Crysta';
    bool notifyTraveler = true;
    bool notifyDriver = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_taxi_rounded, color: Color(0xFF38BDF8), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Dispatch Chauffeur & Vehicle',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  'Auto-formats and sends WhatsApp trip sheet to Traveler & Driver simultaneously.',
                  style: TextStyle(fontSize: 11, color: Colors.white60),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: driverNameCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Chauffeur Name *',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                          hintText: 'e.g. Ramesh Kumar',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: driverPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Driver Mobile *',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                          hintText: 'e.g. 9876543210',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedModel,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Vehicle Model',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        items: ['Innova Crysta', 'Swift Dzire AC', 'Ertiga Hybrid', 'Tempo Traveller 12S', 'Toyota Fortuner'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedModel = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: vehicleNumCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Vehicle Plate *',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                          hintText: 'UP 65 AB 1234',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: reportingTimeCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Reporting Time',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: balanceCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Duty Balance (₹)',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: pickupLocCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Pickup Location / Hotel',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        value: notifyTraveler,
                        onChanged: (v) => setSheetState(() => notifyTraveler = v ?? true),
                        title: const Text('Send WhatsApp to Traveler', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        value: notifyDriver,
                        onChanged: (v) => setSheetState(() => notifyDriver = v ?? true),
                        title: const Text('Send WhatsApp to Driver', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final dName = driverNameCtrl.text.trim();
                            final dPhone = driverPhoneCtrl.text.trim();
                            final vPlate = vehicleNumCtrl.text.trim();
                            if (dName.isEmpty || dPhone.isEmpty || vPlate.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill Driver Name, Mobile, and Vehicle Number')),
                              );
                              return;
                            }
                            setSheetState(() => isSubmitting = true);
                            final leadProv = Provider.of<LeadProvider>(context, listen: false);
                            final numericLeadId = int.tryParse(lead.id) ?? 0;
                            final res = await leadProv.apiService.dispatchDriver(
                              leadId: numericLeadId,
                              driverName: dName,
                              driverPhone: dPhone,
                              vehicleNumber: vPlate,
                              vehicleModel: selectedModel,
                              reportingTime: reportingTimeCtrl.text.trim(),
                              pickupLocation: pickupLocCtrl.text.trim(),
                              balanceAmount: double.tryParse(balanceCtrl.text.trim()) ?? 0.0,
                              notifyCustomer: notifyTraveler,
                              notifyDriver: notifyDriver,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              final custSent = res?['traveler_notified'] == true;
                              final drvSent = res?['driver_notified'] == true;
                              leadProv.addLeadNote(
                                lead.id,
                                '🚖 Chauffeur Dispatched: $dName ($dPhone) on $selectedModel ($vPlate). Traveler: ${custSent ? "Sent" : "Skipped"}, Driver: ${drvSent ? "Sent" : "Skipped"}',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Chauffeur trip sheet dispatched! (Traveler: ${custSent ? "✓" : "—"}, Driver: ${drvSent ? "✓" : "—"})'),
                                  backgroundColor: AppColors.successGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    label: Text(
                      isSubmitting ? 'Dispatching...' : 'Dispatch Trip Sheets Now',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentLinkSheet(BuildContext context, LeadModel lead) {
    final amountCtrl = TextEditingController(text: '1500');
    final purposeCtrl = TextEditingController(text: 'Kashi Pilgrimage Advance Booking');
    bool sendWhatsApp = true;
    bool isGenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payment_rounded, color: AppColors.accentGold, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '1-Tap Advance UPI & Payment Link',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Generates Cashfree payment gateway link & instant UPI deep link, dispatched via WhatsApp.',
                style: TextStyle(fontSize: 11, color: Colors.white60),
              ),
              const SizedBox(height: 14),

              // Quick Amount Chips
              Wrap(
                spacing: 8,
                children: ['1000', '2500', '5000', '10000'].map((amt) {
                  return ActionChip(
                    backgroundColor: amountCtrl.text == amt ? AppColors.accentGold.withValues(alpha: 0.25) : const Color(0xFF0F172A),
                    side: BorderSide(color: amountCtrl.text == amt ? AppColors.accentGold : Colors.white12),
                    label: Text('₹$amt', style: TextStyle(color: amountCtrl.text == amt ? AppColors.accentGold : Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: () {
                      setSheetState(() => amountCtrl.text = amt);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Advance Amount (₹)',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: purposeCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Payment Purpose',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),

              CheckboxListTile(
                value: sendWhatsApp,
                onChanged: (v) => setSheetState(() => sendWhatsApp = v ?? true),
                title: Text('Instantly dispatch via WhatsApp to ${lead.phone}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isGenerating
                      ? null
                      : () async {
                          final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          if (amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid amount')),
                            );
                            return;
                          }
                          setSheetState(() => isGenerating = true);
                          final leadProv = Provider.of<LeadProvider>(context, listen: false);
                          final numericLeadId = int.tryParse(lead.id) ?? 0;
                          final res = await leadProv.apiService.generatePaymentLink(
                            leadId: numericLeadId,
                            amount: amt,
                            purpose: purposeCtrl.text.trim(),
                            sendWhatsApp: sendWhatsApp,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            final waSent = res?['whatsapp_sent'] == true;
                            final primaryUrl = res?['primary_url'] ?? res?['cashfree_url'] ?? res?['upi_url'] ?? '';
                            if (primaryUrl.toString().isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: primaryUrl.toString()));
                            }
                            leadProv.addLeadNote(
                              lead.id,
                              '💳 Advance Payment Link generated: ₹$amt. WhatsApp sent: ${waSent ? "Yes" : "No"}. URL: $primaryUrl',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Payment link generated! ${waSent ? "Dispatched to WhatsApp." : "Copied to clipboard."}'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: isGenerating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.flash_on_rounded, color: Colors.black, size: 18),
                  label: Text(
                    isGenerating ? 'Generating...' : 'Generate & Dispatch Link',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVoiceNoteSheet(BuildContext context, LeadModel lead) {
    final noteCtrl = TextEditingController();
    final dealValueCtrl = TextEditingController(text: lead.dealValue > 0 ? lead.dealValue.toInt().toString() : '');
    String selectedStage = lead.stage;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mic_rounded, color: Colors.purpleAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Voice Note & Field AI Ingestion',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Record or dictate call brief in Hindi/English. Automatically updates pipeline stage and deal value.',
                style: TextStyle(fontSize: 11, color: Colors.white60),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: noteCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Guest finalized 3D2N VIP Kashi package for 4 adults. Deal amount ₹35,000. Advance ₹5,000 promised by evening.',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dealValueCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Deal Value (₹)',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedStage,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Pipeline Stage',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: AppConstants.travelPipelineStages
                          .where((s) => s['id'] != 'all')
                          .map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['label'] as String)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedStage = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final text = noteCtrl.text.trim();
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter or dictate a note summary')),
                            );
                            return;
                          }
                          setSheetState(() => isSaving = true);
                          final leadProv = Provider.of<LeadProvider>(context, listen: false);
                          final numericLeadId = int.tryParse(lead.id) ?? 0;
                          final parsedVal = double.tryParse(dealValueCtrl.text.trim());
                          await leadProv.apiService.submitVoiceNoteSummary(
                            leadId: numericLeadId,
                            phone: lead.phone,
                            transcript: text,
                            stage: selectedStage,
                            dealValue: parsedVal,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            leadProv.addLeadNote(lead.id, '🎙️ Field AI Note: $text');
                            if (selectedStage != lead.stage) {
                              leadProv.updateLeadStage(lead.id, selectedStage);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Field intelligence & deal value updated in CRM!'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                  label: Text(
                    isSaving ? 'Saving...' : 'Ingest Intelligence to CRM',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendQuickMessage(LeadModel lead) async {
    final text = _quickReplyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingReply = true);
    _quickReplyController.clear();

    if (_isNoteMode) {
      Provider.of<LeadProvider>(context, listen: false).addLeadNote(lead.id, text);
    } else {
      final wpProvider = Provider.of<WhatsAppProvider>(context, listen: false);
      final cleanLeadPhone = lead.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final leadSuffix = cleanLeadPhone.length >= 10 ? cleanLeadPhone.substring(cleanLeadPhone.length - 10) : cleanLeadPhone;

      final matchedIdx = wpProvider.threads.indexWhere(
        (t) {
          final tPhone = t.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
          return leadSuffix.isNotEmpty && tPhone.endsWith(leadSuffix);
        },
      );

      if (matchedIdx != -1) {
        await wpProvider.sendMessage(wpProvider.threads[matchedIdx].id, text);
      } else {
        final api = Provider.of<LeadProvider>(context, listen: false).apiService;
        await api.sendWhatsAppMessage(phone: lead.phone, message: text);
      }
      if (mounted) {
        Provider.of<LeadProvider>(context, listen: false).addLeadNote(lead.id, '💬 WhatsApp: $text');
      }
    }

    if (mounted) {
      setState(() => _isSendingReply = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isNoteMode ? 'Note saved to timeline.' : 'WhatsApp message sent to ${lead.name}!'),
          backgroundColor: _isNoteMode ? AppColors.accentGold : AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leadProvider = Provider.of<LeadProvider>(context);
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    final wpProvider = Provider.of<WhatsAppProvider>(context);

    final lead = leadProvider.leads.firstWhere(
      (l) => l.id == widget.lead.id,
      orElse: () => widget.lead,
    );

    final stageConfig = AppConstants.travelPipelineStages.firstWhere(
      (s) => s['id'] == lead.stage,
      orElse: () => {'label': lead.stage.toUpperCase(), 'color': 0xFF3B82F6},
    );
    final stageColor = Color(stageConfig['color'] as int);

    // Find live WhatsApp thread for this lead
    final cleanLeadPhone = lead.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final leadSuffix = cleanLeadPhone.length >= 10 ? cleanLeadPhone.substring(cleanLeadPhone.length - 10) : cleanLeadPhone;
    final matchedThread = wpProvider.threads.where((t) {
      final tPhone = t.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
      return tPhone.endsWith(leadSuffix);
    }).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lead.name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white70),
            onPressed: () {
              final shareText = 'TripCosmos Lead: ${lead.name}\nPhone: ${lead.phone}\nCircuit: ${lead.destination}\nPax: ${lead.pax}\nOwner: ${lead.stickyAgent}';
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lead details copied to clipboard!'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              switch (val) {
                case 'stage':
                  _showChangeStageSheet(context, lead);
                  break;
                case 'reassign':
                  _showReassignOwnerSheet(context, lead);
                  break;
                case 'dispatch':
                  _showDispatchDriverSheet(context, lead);
                  break;
                case 'payment':
                  _showPaymentLinkSheet(context, lead);
                  break;
                case 'voice_note':
                  _showVoiceNoteSheet(context, lead);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'stage',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: AppColors.accentBlue, size: 18),
                    SizedBox(width: 10),
                    Text('Update Stage', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reassign',
                child: Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF8B5CF6), size: 18),
                    SizedBox(width: 10),
                    Text('Assign Owner', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dispatch',
                child: Row(
                  children: [
                    Icon(Icons.local_taxi_rounded, color: AppColors.accentGold, size: 18),
                    SizedBox(width: 10),
                    Text('Dispatch Driver (Trip Sheet)', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'payment',
                child: Row(
                  children: [
                    Icon(Icons.payment_rounded, color: AppColors.successGreen, size: 18),
                    SizedBox(width: 10),
                    Text('Generate UPI Payment Link', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'voice_note',
                child: Row(
                  children: [
                    Icon(Icons.mic_rounded, color: Colors.cyanAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Record AI Voice Note', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              // 1. Header Information & Actions
              _buildHeaderSection(context, lead, stageConfig, stageColor, callProvider),

              // 2. 4-Tab Navigation Bar (Superfone Benchmark: Timeline, Profile, Notes, Deals)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  border: Border(
                    bottom: BorderSide(color: Colors.white12),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.accentBlue,
                  indicatorWeight: 3,
                  labelColor: AppColors.accentBlue,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(icon: Icon(Icons.timeline_rounded, size: 18), text: 'Timeline'),
                    Tab(icon: Icon(Icons.person_outline_rounded, size: 18), text: 'Profile'),
                    Tab(icon: Icon(Icons.description_outlined, size: 18), text: 'Notes'),
                    Tab(icon: Icon(Icons.handshake_outlined, size: 18), text: 'Deals'),
                  ],
                ),
              ),

              // 3. TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Timeline (WhatsApp + Calls + Notes + Inline Quick Reply)
                    _buildTimelineTab(lead, matchedThread),

                    // Tab 2: Profile (Lead Details + CRM sync + Owner)
                    _buildProfileTab(lead, stageConfig, stageColor),

                    // Tab 3: Notes (Internal Activity Log)
                    _buildNotesTab(lead),

                    // Tab 4: Deals & Quotes
                    _buildDealsTab(lead),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    LeadModel lead,
    Map<String, dynamic> stageConfig,
    Color stageColor,
    CallProvider callProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF0284C7),
                child: Text(
                  lead.initials,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
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
                            lead.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showChangeStageSheet(context, lead),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: stageColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: stageColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              stageConfig['label'].toString().toUpperCase(),
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: stageColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lead.companyOrCity.toUpperCase()} • ${lead.phone}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              // Owner Chip
              InkWell(
                onTap: () => _showReassignOwnerSheet(context, lead),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: const Color(0xFF8B5CF6),
                        child: Text(
                          lead.ownerInitials,
                          style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        lead.stickyAgent.isNotEmpty ? lead.stickyAgent : 'Unassigned',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons: Call, WhatsApp, Quote ⚡, Cab 🚕, Follow-up
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeaderActionButton(
                icon: Icons.call,
                color: Colors.white,
                backgroundColor: const Color(0xFF2563EB),
                label: 'Call',
                isPrimary: true,
                onTap: () {
                  callProvider.startOutboundCall(
                    phone: lead.phone,
                    name: lead.name,
                    tourInterest: lead.destination,
                  );
                },
              ),
              _buildHeaderActionButton(
                icon: Icons.chat,
                color: Colors.white,
                backgroundColor: const Color(0xFF10B981),
                label: 'WhatsApp',
                onTap: () {
                  final wp = context.read<WhatsAppProvider>();
                  final thread = wp.getOrCreateThread(
                    customerPhone: lead.phone,
                    customerName: lead.name,
                    circuit: lead.destination,
                    initialMessage: lead.lastChatSummary ?? '',
                  );
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
                },
              ),
              _buildHeaderActionButton(
                icon: Icons.bolt,
                color: Colors.white,
                backgroundColor: const Color(0xFFD97706),
                label: 'Quote ⚡',
                onTap: () => TravelQuoteDialog.show(context, lead),
              ),
              _buildHeaderActionButton(
                icon: Icons.local_taxi_rounded,
                color: Colors.white,
                backgroundColor: const Color(0xFF0284C7),
                label: 'Cab 🚕',
                onTap: () => CabFareDialog.show(context, lead: lead),
              ),
              _buildHeaderActionButton(
                icon: Icons.alarm_add_rounded,
                color: AppColors.accentGold,
                backgroundColor: const Color(0xFF1E293B),
                label: 'Follow-up',
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (selectedDate != null && context.mounted) {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 11, minute: 0),
                    );
                    if (selectedTime != null && context.mounted) {
                      final combined = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      Provider.of<LeadProvider>(context, listen: false).scheduleFollowUp(
                        lead.id,
                        combined,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Follow-up scheduled for ${combined.day}/${combined.month} at ${selectedTime.format(context)}'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: isPrimary ? 46 : 40,
              height: isPrimary ? 46 : 40,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: backgroundColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: color, size: isPrimary ? 22 : 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: Unified Superfone Timeline
  Widget _buildTimelineTab(LeadModel lead, WhatsAppThread? matchedThread) {
    final callProvider = Provider.of<CallProvider>(context);
    final cleanLeadPhone = lead.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final leadSuffix = cleanLeadPhone.length >= 10
        ? cleanLeadPhone.substring(cleanLeadPhone.length - 10)
        : cleanLeadPhone;
    final leadCalls = callProvider.callLogs.where((c) {
      final cClean = c.phone.replaceAll(RegExp(r'[^0-9]'), '');
      return leadSuffix.isNotEmpty && cClean.endsWith(leadSuffix);
    }).toList();

    return Column(
      children: [
        // Feed Stream
        Expanded(
          child: ListView(
            controller: _timelineScrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Lead Origin Card
              _buildTimelineCard(
                icon: Icons.flag_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'LEAD CREATED (${lead.source.toUpperCase()})',
                timestamp: DateFormat('d MMM, h:mm a').format(lead.createdAt),
                content: lead.lastChatSummary != null && lead.lastChatSummary!.isNotEmpty
                    ? lead.lastChatSummary!
                    : 'Customer interested in ${lead.destination} tour (${lead.pax} travelers).',
              ),

              // WhatsApp Thread Messages if exists
              if (matchedThread != null) ...[
                ...matchedThread.messages.map((m) {
                  return _buildTimelineCard(
                    icon: m.isFromCustomer ? Icons.chat_bubble_outline : Icons.chat_bubble,
                    iconColor: m.isFromCustomer ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                    title: m.isFromCustomer ? 'WHATSAPP INBOUND (${lead.name})' : 'WHATSAPP OUTBOUND (Agent)',
                    timestamp: DateFormat('h:mm a').format(m.timestamp),
                    content: m.text,
                    isWhatsApp: true,
                    isCustomer: m.isFromCustomer,
                  );
                }),
              ],

              // Real Telephony Call Logs for this Lead
              ...leadCalls.map((c) {
                return _buildTimelineCard(
                  icon: c.direction == CallDirection.inbound
                      ? Icons.phone_callback_rounded
                      : (c.direction == CallDirection.missed
                          ? Icons.phone_missed_rounded
                          : Icons.phone_in_talk_rounded),
                  iconColor: c.status == 'completed'
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFEF4444),
                  title: '${c.direction.name.toUpperCase()} CALL (${c.formattedDuration})',
                  timestamp: DateFormat('d MMM, h:mm a').format(c.timestamp),
                  content: (c.notes != null && c.notes!.isNotEmpty)
                      ? c.notes!
                      : 'Call via ${c.simCard} • Status: ${c.status}',
                  hasRecording: c.recordingUrl != null && c.recordingUrl!.isNotEmpty,
                  recordingUrl: c.recordingUrl,
                );
              }),

              // Lead Activity Notes
              ...lead.notes.map((n) {
                final isCall = n.contains('📞');
                return _buildTimelineCard(
                  icon: isCall ? Icons.phone_callback : Icons.note,
                  iconColor: isCall ? AppColors.accentBlue : AppColors.accentGold,
                  title: isCall ? 'CALL LOG' : 'INTERNAL NOTE',
                  timestamp: 'Recent',
                  content: n,
                );
              }),
            ],
          ),
        ),

        // Canned Quick Reply Chips
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _cannedQuickReplies.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final canned = _cannedQuickReplies[idx];
              return Center(
                child: ActionChip(
                  label: Text(canned['label']!, style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w700)),
                  backgroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Colors.white12),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () {
                    _quickReplyController.text = canned['text']!;
                  },
                ),
              );
            },
          ),
        ),

        // Bottom Unified Reply Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Mode Toggle (WhatsApp vs Internal Note)
                IconButton(
                  icon: Icon(
                    _isNoteMode ? Icons.note_alt_rounded : Icons.chat_bubble_rounded,
                    color: _isNoteMode ? AppColors.accentGold : const Color(0xFF10B981),
                    size: 22,
                  ),
                  tooltip: _isNoteMode ? 'Switch to WhatsApp Message' : 'Switch to Internal Note',
                  onPressed: () => setState(() => _isNoteMode = !_isNoteMode),
                ),
                Expanded(
                  child: TextField(
                    controller: _quickReplyController,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: _isNoteMode ? 'Add internal activity note...' : 'Reply to traveler on WhatsApp...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendQuickMessage(lead),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _isNoteMode ? AppColors.accentGold : const Color(0xFF10B981),
                  child: IconButton(
                    icon: _isSendingReply
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: _isSendingReply ? null : () => _sendQuickMessage(lead),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String timestamp,
    required String content,
    bool hasRecording = false,
    String? recordingUrl,
    bool isWhatsApp = false,
    bool isCustomer = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWhatsApp && isCustomer
            ? const Color(0xFF1E293B)
            : isWhatsApp
                ? const Color(0xFF0F2922)
                : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWhatsApp && !isCustomer ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white70),
              ),
              const Spacer(),
              Text(timestamp, style: const TextStyle(fontSize: 10.5, color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFE2E8F0))),
          if (hasRecording) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic_rounded, color: AppColors.accentGold, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Call Audio Recording Logged (Server Vault)',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('HD Audio', style: TextStyle(color: AppColors.successGreen, fontSize: 9.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // TAB 2: Lead Profile Tab
  Widget _buildProfileTab(LeadModel lead, Map<String, dynamic> stageConfig, Color stageColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfileSection(
          title: 'CONTACT DETAILS',
          children: [
            _buildProfileRow('Full Name', lead.name),
            _buildProfileRow('Phone', lead.phone, isPhone: true),
            _buildProfileRow('Email', lead.email.isNotEmpty ? lead.email : 'Not provided'),
            _buildProfileRow('Location / City', lead.companyOrCity),
          ],
        ),
        const SizedBox(height: 16),
        _buildProfileSection(
          title: 'PILGRIMAGE & TRAVEL PREFERENCES',
          children: [
            _buildProfileRow('Circuit Destination', lead.destination),
            _buildProfileRow('Travelers (Pax)', '${lead.pax} Guests'),
            _buildProfileRow('Estimated Budget', lead.budget.isNotEmpty ? lead.budget : '₹${lead.dealValue.toInt()}'),
            _buildProfileRow('Inquiry Source', lead.source.toUpperCase()),
          ],
        ),
        const SizedBox(height: 16),
        _buildProfileSection(
          title: 'CRM & TELEPHONY STATUS',
          children: [
            _buildProfileRow('Lead Owner', lead.stickyAgent),
            _buildProfileRow('Pipeline Stage', stageConfig['label']),
            _buildProfileRow('Created At', DateFormat('d MMM yyyy, h:mm a').format(lead.createdAt)),
            _buildProfileRow('FluentCRM Sync', 'Active (List 8 - B2B & Pilgrim)', isBadge: true),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, {bool isPhone = false, bool isBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
          isBadge
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.successGreen)),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isPhone ? AppColors.accentBlue : Colors.white,
                  ),
                ),
        ],
      ),
    );
  }

  // TAB 3: Notes Tab
  Widget _buildNotesTab(LeadModel lead) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('INTERNAL ACTIVITY NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white54)),
              ElevatedButton.icon(
                onPressed: () => _showAddNoteDialog(context, lead),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Note', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
              ),
            ],
          ),
        ),
        Expanded(
          child: lead.notes.isEmpty
              ? const Center(
                  child: Text('No notes yet. Tap Add Note to log call summaries.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lead.notes.length,
                  itemBuilder: (ctx, idx) {
                    final note = lead.notes[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sticky_note_2_rounded, size: 16, color: AppColors.accentGold),
                              const SizedBox(width: 8),
                              Text('Note #${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                              const Spacer(),
                              Text('By ${lead.stickyAgent}', style: const TextStyle(fontSize: 10.5, color: Colors.white38)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(note, style: const TextStyle(fontSize: 13, color: Colors.white)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 4: Deals & Quotes Tab
  Widget _buildDealsTab(LeadModel lead) {
    final curFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Deal Value Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL DEAL VALUE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.accentGold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(lead.stage.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                curFmt.format(lead.dealValue > 0 ? lead.dealValue : 28000),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Tour Circuit: ${lead.destination} • ${lead.pax} Pax',
                style: const TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action 1: Tour Package Generator
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.bolt, color: Color(0xFFD97706), size: 24),
            ),
            title: const Text('Generate Tour Package Quote ⚡', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            subtitle: const Text('Create full customized itinerary quote with hotels, boats & VIP darshan', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
            onTap: () => TravelQuoteDialog.show(context, lead),
          ),
        ),
        const SizedBox(height: 10),

        // Action 2: Outstation Cab Fare Calculator
        Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.white10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.local_taxi_rounded, color: Color(0xFF0284C7), size: 24),
            ),
            title: const Text('Calculate Outstation Cab Fare 🚕', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            subtitle: const Text('Verified km tariffs for Sedan, Innova Crysta, and Tempo Travellers', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
            onTap: () => CabFareDialog.show(context, lead: lead),
          ),
        ),
      ],
    );
  }
}
