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
import '../widgets/website_radar_dialog.dart';
import '../widgets/whatsapp_team_chat_view.dart';
import '../providers/website_radar_provider.dart';
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
      body: SafeArea(
        child: _isB2bMode
            ? Column(
                children: [
                  _buildModeSwitcher(),
                  const Expanded(child: B2bPartnersView(embedded: true)),
                ],
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 0. Fluid Floating Header (Scrolls away, snaps back on scroll up)
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    pinned: false,
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    titleSpacing: 14,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isB2bMode ? 'B2B Travel Partners' : 'Leads & CRM Hub',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          _isB2bMode
                              ? 'Pan-India Agencies • 16% Net Rates'
                              : 'Multi-Source Pipeline • 10k CRM',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    actions: [
                      Consumer2<EventProvider, WebsiteRadarProvider>(
                        builder: (context, eventProvider, radarProvider, _) {
                          final visitorCount = radarProvider.activeCount > 0
                              ? radarProvider.activeCount
                              : eventProvider.liveVisitorCount;
                          return TextButton.icon(
                            onPressed: () => WebsiteRadarDialog.show(context),
                            icon: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            label: Text(
                              '$visitorCount Live Radar',
                              style: TextStyle(
                                color: AppColors.getTextPrimary(context),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.getCard(context),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
                        icon: const Icon(Icons.request_quote_rounded, color: AppColors.accentGold, size: 20),
                        tooltip: 'Quotation Desk',
                      ),
                      IconButton(
                        onPressed: () => LeadsScreen.showAddLeadDialog(context),
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentGold, size: 21),
                        tooltip: 'Capture New Lead (+)',
                      ),
                      IconButton(
                        onPressed: () => leadProvider.refreshLeadsFromServer(),
                        icon: const Icon(Icons.refresh, color: AppColors.accentGold, size: 19),
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
                        icon: const Icon(Icons.settings_outlined, color: AppColors.accentGold, size: 19),
                        tooltip: 'Server & Companion Settings',
                      ),
                    ],
                  ),

                  // 1. Ultra-Compact Command Strip (Mode Switcher + Search + Unified Filter Pills)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModeSwitcher(),
                          const SizedBox(height: 4),

                          // Compact Search Bar (34px)
                          SizedBox(
                            height: 34,
                            child: TextField(
                              onChanged: (val) => leadProvider.setSearchQuery(val),
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Search leads by name, phone or circuit...',
                                hintStyle: const TextStyle(fontSize: 11),
                                prefixIcon: const Icon(Icons.search, size: 16),
                                suffixIcon: leadProvider.searchQuery.isNotEmpty
                                    ? IconButton(
                                        onPressed: () => leadProvider.setSearchQuery(''),
                                        icon: const Icon(Icons.clear, size: 14),
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.getBorder(context)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Unified Filter Strip: Urgency + Ownership + Pipeline Stages
                          SizedBox(
                            height: 27,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildFilterChip(
                                  label: '⚡ SLA Urgent',
                                  count: leadProvider.urgentSlaCount,
                                  isSelected: leadProvider.ownerFilter == 'urgent',
                                  color: const Color(0xFFF59E0B),
                                  onTap: () => leadProvider.setOwnerFilter('urgent'),
                                ),
                                const SizedBox(width: 5),
                                _buildFilterChip(
                                  label: 'All Leads',
                                  count: leadProvider.leads.length,
                                  isSelected: leadProvider.ownerFilter == 'all',
                                  color: AppColors.accentGold,
                                  onTap: () => leadProvider.setOwnerFilter('all'),
                                ),
                                const SizedBox(width: 5),
                                _buildFilterChip(
                                  label: 'My Leads',
                                  count: leadProvider.myLeadsCount,
                                  isSelected: leadProvider.ownerFilter == 'my_leads',
                                  color: const Color(0xFF38BDF8),
                                  onTap: () => leadProvider.setOwnerFilter('my_leads'),
                                ),
                                const SizedBox(width: 5),
                                _buildFilterChip(
                                  label: 'Due Follow-Ups',
                                  count: leadProvider.followUpsDueCount,
                                  isSelected: leadProvider.ownerFilter == 'follow_ups',
                                  color: const Color(0xFFEC4899),
                                  onTap: () => leadProvider.setOwnerFilter('follow_ups'),
                                ),
                                const SizedBox(width: 5),
                                _buildFilterChip(
                                  label: 'Unassigned',
                                  count: leadProvider.unassignedLeadsCount,
                                  isSelected: leadProvider.ownerFilter == 'unassigned',
                                  color: const Color(0xFF34D399),
                                  onTap: () => leadProvider.setOwnerFilter('unassigned'),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  width: 1,
                                  color: AppColors.getBorder(context),
                                ),
                                ...AppConstants.pipelineStages.map((stage) {
                                  final isSelected = leadProvider.selectedStage == stage;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: ChoiceChip(
                                      label: Text(
                                        _formatStage(stage),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primaryDark
                                              : AppColors.getTextSecondary(context),
                                        ),
                                      ),
                                      selected: isSelected,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                      selectedColor: AppColors.accentGold,
                                      backgroundColor: AppColors.getCard(context),
                                      side: BorderSide(
                                        color: isSelected ? Colors.transparent : AppColors.getBorder(context),
                                      ),
                                      onSelected: (_) => leadProvider.setStageFilter(stage),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          _buildPowerDialerBanner(context, leadProvider),
                        ],
                      ),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_lead_screen',
        onPressed: () => LeadsScreen.showAddLeadDialog(context),
        backgroundColor: AppColors.accentGold,
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, size: 20, color: Colors.black),
        label: const Text(
          'New Lead',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black),
        ),
      ),
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
            // Top Row: Name, Urgency Badge, Stage Chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.name,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                ),
                if (lead.urgencyTag != null) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), width: 0.8),
                    ),
                    child: Text(
                      lead.urgencyTag!,
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
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
                      fontSize: 9.5,
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
            // Context-Aware Next-Best-Action Recommendation
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology_outlined, size: 12, color: AppColors.accentGold),
                  const SizedBox(width: 4),
                  Text(
                    'AI Next Action: ${lead.nextBestActionLabel}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentGold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
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

  Widget _buildModeSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.getElevated(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isB2bMode = false),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: !_isB2bMode ? AppColors.accentGold : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_pin_circle_rounded,
                        size: 14,
                        color: !_isB2bMode ? AppColors.primaryDark : AppColors.getTextMuted(context),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Direct Travelers (B2C)',
                        style: TextStyle(
                          fontSize: 11,
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
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: _isB2bMode ? const Color(0xFF8B5CF6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_rounded,
                        size: 14,
                        color: _isB2bMode ? Colors.white : AppColors.getTextMuted(context),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'B2B Partners (DMC)',
                        style: TextStyle(
                          fontSize: 11,
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

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white12 : AppColors.lightBorderSubtle),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? color : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color : (isDark ? Colors.white24 : Colors.black12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ],
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
