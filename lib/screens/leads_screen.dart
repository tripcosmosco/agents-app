import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../providers/call_provider.dart';
import '../providers/event_provider.dart';
import '../providers/lead_provider.dart';
import '../widgets/b2b_partners_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/live_activity_sheet.dart';
import '../widgets/whatsapp_team_chat_view.dart';
import '../providers/whatsapp_provider.dart';
import 'lead_detail_screen.dart';
import 'settings_screen.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  bool _isB2bMode = false;

  void _showAddLeadDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final destController = TextEditingController(
      text: 'Varanasi 3D Spiritual Circuit',
    );
    final budgetController = TextEditingController(text: '₹25,000');
    final noteController = TextEditingController();

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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
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
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save & Sync Lead'),
          ),
        ],
      ),
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
                  ? 'Pan-India Travel Agencies • 16% Net Rates • White-Label'
                  : 'TripCosmos.co Multi-Source Pipeline (10,000+ Storage)',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceCard,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            onPressed: () => leadProvider.refreshLeadsFromServer(),
            icon: const Icon(Icons.refresh, color: AppColors.accentGold),
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
            icon: const Icon(Icons.settings_outlined, color: AppColors.accentGold),
            tooltip: 'Server & Companion Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // B2C vs B2B DMC Hub Top Switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
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
                            color: !_isB2bMode
                                ? AppColors.accentGold
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_pin_circle_rounded,
                                size: 15,
                                color: !_isB2bMode
                                    ? AppColors.primaryDark
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Direct Travelers (B2C)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: !_isB2bMode
                                      ? AppColors.primaryDark
                                      : AppColors.textMuted,
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
                            color: _isB2bMode
                                ? const Color(0xFF8B5CF6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business_rounded,
                                size: 15,
                                color: _isB2bMode
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'B2B Partners (DMC)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _isB2bMode
                                      ? Colors.white
                                      : AppColors.textMuted,
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
            ),

            if (_isB2bMode)
              const Expanded(child: B2bPartnersView())
            else ...[
              // Team Assignment & Roster Filter Bar (Superfone Benchmark)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton(
                      context: context,
                      title: 'All Leads',
                      count: leadProvider.leads.length,
                      isSelected: leadProvider.ownerFilter == 'all',
                      onTap: () => leadProvider.setOwnerFilter('all'),
                    ),
                    _buildSegmentButton(
                      context: context,
                      title: 'My Leads',
                      count: leadProvider.myLeadsCount,
                      isSelected: leadProvider.ownerFilter == 'my_leads',
                      onTap: () => leadProvider.setOwnerFilter('my_leads'),
                    ),
                    _buildSegmentButton(
                      context: context,
                      title: 'Follow-ups',
                      count: leadProvider.followUpsDueCount,
                      isSelected: leadProvider.ownerFilter == 'follow_ups',
                      onTap: () => leadProvider.setOwnerFilter('follow_ups'),
                    ),
                    _buildSegmentButton(
                      context: context,
                      title: 'Unassigned',
                      count: leadProvider.unassignedLeadsCount,
                      isSelected: leadProvider.ownerFilter == 'unassigned',
                      onTap: () => leadProvider.setOwnerFilter('unassigned'),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
                ),
              ),
            ),

            // Power Dialer Auto-Queue Banner & Controller
            Consumer<CallProvider>(
              builder: (context, cp, _) {
                if (cp.isPowerDialerActive) {
                  final current = cp.currentPowerDialerLead;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
            ),

            // Stage Filter Chips
            SizedBox(
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
                      backgroundColor: AppColors.surfaceCard,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Leads List
            Expanded(
              child: leadProvider.filteredLeads.isEmpty
                  ? Center(
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
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 10,
                        bottom: 84,
                      ),
                      itemCount: leadProvider.filteredLeads.length,
                      itemBuilder: (context, index) {
                        final lead = leadProvider.filteredLeads[index];
                        return _buildLeadCard(context, lead, callProvider);
                      },
                    ),
            ),
            ],
          ],
        ),
      ),
      floatingActionButton: _isB2bMode
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              onPressed: () => _showAddLeadDialog(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Lead'),
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
                    style: const TextStyle(
                      fontSize: 16,
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  lead.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
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
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SRC: ${lead.source.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
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
                        lead.stickyAgent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                        ? AppColors.textMuted
                        : AppColors.successGreen,
                  ),
                ),
              ],
            ),

            if (lead.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                lead.notes.first,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 8),

            // Quick Call & WhatsApp Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
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
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 14,
                    color: AppColors.whatsappGreen,
                  ),
                  label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
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
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
