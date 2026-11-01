import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../providers/auth_provider.dart';
import '../providers/call_provider.dart';
import '../providers/event_provider.dart';
import '../providers/lead_provider.dart';
import '../widgets/b2b_partners_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/live_activity_sheet.dart';
import '../widgets/whatsapp_team_chat_view.dart';
import '../providers/whatsapp_provider.dart';
import '../services/telephony_service.dart';
import 'lead_detail_screen.dart';
import 'quotation_desk_screen.dart';
import 'settings_screen.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  static void showAddLeadDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final destController = TextEditingController(
      text: 'Varanasi 3D Spiritual Circuit',
    );
    final budgetController = TextEditingController(text: '₹25,000');
    final noteController = TextEditingController();
    String selectedOwner = 'Nishkarsh AI';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Capture New Lead',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Traveler Name',
                  hintText: 'e.g. Ramesh Chandra',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone / WhatsApp',
                  hintText: '+91 98765 43210',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (Auto-syncs to FluentCRM)',
                  hintText: 'e.g. ramesh@gmail.com (Optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destController,
                decoration: const InputDecoration(
                  labelText: 'Tour / Cab Circuit',
                  hintText: 'e.g. Ayodhya - Kashi',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Budget',
                  hintText: '₹25,000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Lead Context / Notes',
                  hintText: 'e.g. 4 pax, needs Innova',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedOwner,
                decoration: const InputDecoration(
                  labelText: 'Assign Lead Owner (Auto-Assign Default: Nishkarsh AI)',
                  prefixIcon: Icon(Icons.support_agent_rounded, size: 20),
                ),
                dropdownColor: Theme.of(context).cardColor,
                items: Provider.of<LeadProvider>(context, listen: false).teamMembers.map((member) {
                  final name = member['name'] ?? '';
                  final role = member['role'] ?? 'Staff';
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(
                      '$name (${role.contains('AI') ? 'AI Co-Pilot' : 'Human'})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedOwner = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.getTextMuted(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                Provider.of<LeadProvider>(context, listen: false).createNewLead(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  destination: destController.text.trim(),
                  budget: budgetController.text.trim(),
                  note: noteController.text.trim(),
                  owner: selectedOwner,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save & Sync Lead'),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      destController.dispose();
      budgetController.dispose();
      noteController.dispose();
    });
  }

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  bool _isB2bMode = false;

  void _showReassignOwnerSheet(BuildContext context, LeadModel lead) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCard(context),
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
                Text(
                  'Assign Lead Owner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Assign this lead to an AI Specialist or Team Rep:',
                  style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context)),
                ),
                const SizedBox(height: 16),
                ...Provider.of<LeadProvider>(context, listen: false).teamMembers.map((member) {
                  final isCurrent = lead.stickyAgent == member['name'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isCurrent ? AppColors.accentBlue : AppColors.getElevated(context),
                      child: Text(
                        member['initials'] ?? 'AG',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                      ),
                    ),
                    title: Text(
                      member['name'] ?? '',
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.getTextPrimary(context),
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      member['role'] ?? 'Sales Agent',
                      style: TextStyle(color: AppColors.getTextMuted(context), fontSize: 11),
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
                          content: Text('✓ Lead #${lead.id} assigned to ${member['name']}'),
                          backgroundColor: AppColors.getCard(context),
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

  @override
  Widget build(BuildContext context) {
    final leadProvider = Provider.of<LeadProvider>(context);
    final callProvider = Provider.of<CallProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isB2bMode ? 'B2B Travel Partners (DMC)' : 'Leads & CRM Hub',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              _isB2bMode
                  ? 'Pan-India Agencies • 16% Net Rates'
                  : 'Multi-Source Pipeline • 10k CRM',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              final visitorCount = eventProvider.liveVisitorCount;
              return TextButton.icon(
                onPressed: () => LiveActivitySheet.show(context),
                icon: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                label: Text(
                  '$visitorCount Live',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.getCard(context),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.successGreen.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => QuotationDeskScreen.open(context),
            icon: const Icon(Icons.request_quote_rounded, color: AppColors.accentGold, size: 21),
            tooltip: 'Quotation Desk',
          ),
          IconButton(
            onPressed: () => LeadsScreen.showAddLeadDialog(context),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentGold, size: 22),
            tooltip: 'Capture New Lead (+)',
          ),
          IconButton(
            onPressed: () => leadProvider.refreshLeadsFromServer(),
            icon: const Icon(Icons.refresh, color: AppColors.accentGold, size: 20),
            tooltip: 'Sync with Server',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(apiService: leadProvider.apiService),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: AppColors.accentGold, size: 20),
            tooltip: 'Server & Companion Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: _isB2bMode
            ? Column(
                children: [
                  _buildModeSwitcher(),
                  const Expanded(child: B2bPartnersView()),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModeSwitcher(),
                        _buildSegmentBar(context, leadProvider),
                        _buildSearchBar(leadProvider),
                        _buildPowerDialerBanner(context, leadProvider),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StageFilterHeaderDelegate(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: AppConstants.pipelineStages.length,
                            itemBuilder: (context, index) {
                              final stage = AppConstants.pipelineStages[index];
                              final isSelected = leadProvider.selectedStage == stage;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(_formatStage(stage)),
                                  selected: isSelected,
                                  onSelected: (_) => leadProvider.setStageFilter(stage),
                                  selectedColor: AppColors.accentGold,
                                  backgroundColor: AppColors.getCard(context),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.getTextSecondary(context),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 11.5,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      height: 46.0,
                    ),
                  ),
                  if (leadProvider.filteredLeads.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 54,
                              color: AppColors.textMuted.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No leads match your active filters',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 96,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final lead = leadProvider.filteredLeads[index];
                            return _buildLeadCard(context, lead, callProvider);
                          },
                          childCount: leadProvider.filteredLeads.length,
                        ),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: null,
    );
  }

  String _formatStage(String stage) {
    switch (stage.toLowerCase()) {
      case 'all':
        return 'All Leads';
      case 'quote_sent':
        return 'Quote Sent';
      case 'requirement_pending':
        return 'Req. Pending';
      case 'advance_paid':
        return 'Advance Paid';
      default:
        final formatted = stage.replaceAll('_', ' ');
        return formatted.isEmpty ? stage : formatted[0].toUpperCase() + formatted.substring(1);
    }
  }

  Widget _buildLeadCard(
    BuildContext context,
    LeadModel lead,
    CallProvider callProvider,
  ) {
    Color stageColor;
    switch (lead.stage) {
      case 'new':
        stageColor = AppColors.accentGold;
        break;
      case 'contacted':
        stageColor = AppColors.outboundCall;
        break;
      case 'qualified':
        stageColor = Colors.purpleAccent;
        break;
      case 'quote_sent':
        stageColor = Colors.orangeAccent;
        break;
      case 'won':
        stageColor = AppColors.successGreen;
        break;
      default:
        stageColor = AppColors.textMuted;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final canViewFullPhone = auth.isAdmin || auth.hasPermission('view_full_contact');
    final maskedPhone = canViewFullPhone
        ? lead.phone
        : (lead.phone.length > 7
            ? '${lead.phone.substring(0, lead.phone.length - 4)}••••'
            : lead.phone);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Name, Stage Chip, Source Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: stageColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _formatStage(lead.stage).toUpperCase(),
                    style: TextStyle(
                      color: stageColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Circuit & Phone
            Row(
              children: [
                Icon(
                  lead.destination.trim().isEmpty ? Icons.explore : Icons.temple_hindu,
                  size: 14,
                  color: AppColors.accentGold,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lead.destination.trim().isEmpty ? 'General Pilgrimage Inquiry' : lead.destination,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ),
                Text(
                  maskedPhone,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextMuted(context),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Source & Sticky Agent
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getElevated(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SRC: ${lead.source.toUpperCase()}',
                    style: TextStyle(
                      color: AppColors.getTextMuted(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showReassignOwnerSheet(context, lead),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                       horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getElevated(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lead.stickyAgent.isEmpty ? Colors.amber.withValues(alpha: 0.5) : AppColors.getBorder(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: const Color(0xFF8B5CF6),
                          child: Text(
                            lead.ownerInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lead.stickyAgent.isNotEmpty ? lead.stickyAgent : 'Unassigned',
                          style: TextStyle(
                            color: lead.stickyAgent.isNotEmpty ? AppColors.getTextPrimary(context) : Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_drop_down, color: AppColors.getTextMuted(context), size: 14),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  (lead.budget.isEmpty || lead.budget == '₹0' || lead.budget == '0')
                      ? 'Exploring'
                      : lead.budget,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: (lead.budget.isEmpty || lead.budget == '₹0' || lead.budget == '0')
                        ? AppColors.getTextMuted(context)
                        : AppColors.successGreen,
                  ),
                ),
              ],
            ),

            if (lead.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                lead.notes.first,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.getTextMuted(context),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 8),

            // Quick Call & WhatsApp Action Buttons (Ergonomic 50/50 Split)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final wp = context.read<WhatsAppProvider>();
                      final thread = wp.getOrCreateThread(
                        customerPhone: lead.phone,
                        customerName: lead.name,
                        circuit: lead.destination,
                        initialMessage: '',
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
                    onLongPress: () {
                      TelephonyService.openWhatsApp(
                        phoneNumber: lead.phone,
                        message: 'Hello ${lead.name}, this is regarding your ${lead.destination} tour with TripCosmos...',
                      );
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 14,
                      color: AppColors.whatsappGreen,
                    ),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.whatsappGreen.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Build Quote for ${lead.name}',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accentGold.withValues(alpha: 0.15),
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.4)),
                    ),
                  ),
                  icon: const Icon(Icons.request_quote_rounded, color: AppColors.accentGold, size: 18),
                  onPressed: () => QuotationDeskScreen.open(context, lead),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      callProvider.startOutboundCall(
                        phone: lead.phone,
                        name: lead.name,
                        tourInterest: lead.destination,
                      );
                    },
                    icon: const Icon(Icons.call, size: 14),
                    label: const Text(
                      'Call Jio ₹0',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
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

  Widget _buildSegmentButton({
    required BuildContext context,
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.28)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.getElevated(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isB2bMode = false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: !_isB2bMode ? AppColors.accentGold : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_pin_circle_rounded,
                        size: 15,
                        color: !_isB2bMode ? AppColors.primaryDark : AppColors.getTextMuted(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Direct Travelers (B2C)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: !_isB2bMode ? AppColors.primaryDark : AppColors.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isB2bMode = true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _isB2bMode ? const Color(0xFF8B5CF6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_rounded,
                        size: 15,
                        color: _isB2bMode ? Colors.white : AppColors.getTextMuted(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'B2B Partners (DMC)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _isB2bMode ? Colors.white : AppColors.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentBar(BuildContext context, LeadProvider leadProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.getCard(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Row(
          children: [
            _buildSegmentButton(
              context: context,
              title: 'All',
              count: leadProvider.leads.length,
              isSelected: leadProvider.ownerFilter == 'all',
              onTap: () => leadProvider.setOwnerFilter('all'),
            ),
            _buildSegmentButton(
              context: context,
              title: 'Mine',
              count: leadProvider.myLeadsCount,
              isSelected: leadProvider.ownerFilter == 'my_leads',
              onTap: () => leadProvider.setOwnerFilter('my_leads'),
            ),
            _buildSegmentButton(
              context: context,
              title: 'Due',
              count: leadProvider.followUpsDueCount,
              isSelected: leadProvider.ownerFilter == 'follow_ups',
              onTap: () => leadProvider.setOwnerFilter('follow_ups'),
            ),
            _buildSegmentButton(
              context: context,
              title: 'Open',
              count: leadProvider.unassignedLeadsCount,
              isSelected: leadProvider.ownerFilter == 'unassigned',
              onTap: () => leadProvider.setOwnerFilter('unassigned'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(LeadProvider leadProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: TextField(
        onChanged: (val) => leadProvider.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search leads by name, phone or circuit...',
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: leadProvider.searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => leadProvider.setSearchQuery(''),
                  icon: const Icon(Icons.clear, size: 18),
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildPowerDialerBanner(BuildContext context, LeadProvider leadProvider) {
    return Consumer<CallProvider>(
      builder: (context, cp, _) {
        if (cp.isPowerDialerActive) {
          final current = cp.currentPowerDialerLead;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B1E08), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentGold, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.accentGold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Power Dialer: ${cp.powerDialerIndex + 1}/${cp.powerDialerTotal}',
                          style: const TextStyle(
                            color: AppColors.accentGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          current?['name']?.toString() ?? 'Calling...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => cp.skipPowerDialerLead(),
                    child: const Text('Skip', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => cp.stopPowerDialer(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Stop', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final leadsToDial = leadProvider.filteredLeads.map((l) => {
                'phone': l.phone,
                'name': l.name,
                'destination': l.destination,
              }).toList();

              if (leadsToDial.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No leads available in current view to dial.')),
                );
                return;
              }
              cp.startPowerDialer(leadsToDial);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, color: AppColors.accentGold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚡ Power Dialer (${leadProvider.filteredLeads.length} leads in queue)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Text(
                    'Start Auto-Call',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.play_arrow_rounded, color: AppColors.accentGold, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StageFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StageFilterHeaderDelegate({required this.child, this.height = 48.0});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StageFilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
