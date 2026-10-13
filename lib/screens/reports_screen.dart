import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/call_provider.dart';
import '../providers/event_provider.dart';
import '../providers/lead_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/live_activity_sheet.dart';
import 'settings_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leadProvider = Provider.of<LeadProvider>(context);
    final callProvider = Provider.of<CallProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);

    final leads = leadProvider.leads;
    final totalLeads = leads.length;
    final wonLeads = leads.where((l) => ['advance_received', 'won', 'traveling', 'completed'].contains(l.stage.toLowerCase())).toList();
    final quoteSentLeads = leads.where((l) => ['quote_sent', 'follow_up', 'advance_received', 'won', 'traveling', 'completed'].contains(l.stage.toLowerCase())).toList();
    final qualifiedLeads = leads.where((l) => ['qualified', 'quote_sent', 'follow_up', 'advance_received', 'won', 'traveling', 'completed'].contains(l.stage.toLowerCase())).toList();

    final pipelineVal = leads.fold(0.0, (sum, l) => sum + l.dealValue);
    final wonVal = wonLeads.fold(0.0, (sum, l) => sum + l.dealValue);

    final winRate = totalLeads > 0 ? ((wonLeads.length / totalLeads) * 100).toStringAsFixed(1) : '0.0';

    final totalCalls = callProvider.callLogs.length;
    final liveVisitors = eventProvider.visitors24hCount;
    final activeNow = eventProvider.activeNowCount;
    final totalTracked = eventProvider.totalVisitorsAll;

    // Genuine zero-cost telephony saving:
    // Real call minutes logged * standard cloud telephony rate (₹1.80/min Exotel/Knowlarity benchmark)
    final totalDurationSecs = callProvider.callLogs.fold<int>(0, (sum, c) => sum + c.durationSeconds);
    final totalCallMinutes = (totalDurationSecs / 60).ceil();
    final savedRupees = (totalCallMinutes * 1.80).round();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Telephony & CRM Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Real-Time Live Analytics & Telephony Pipeline',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => LiveActivitySheet.show(context),
            icon: const Icon(Icons.radar_rounded, color: AppColors.successGreen),
            tooltip: 'Open Live Visitor Radar',
          ),
          IconButton(
            onPressed: () {
              leadProvider.refreshLeadsFromServer();
              callProvider.checkCallQueue();
              eventProvider.refresh();
            },
            icon: const Icon(Icons.refresh, color: AppColors.accentGold),
            tooltip: 'Refresh Reports',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(apiService: callProvider.apiService),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: AppColors.accentGold),
            tooltip: 'Companion Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KPI Metric Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Calls',
                      '$totalCalls',
                      'WebRTC & Jio Bridge',
                      AppColors.outboundCall,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      'Pipeline Value',
                      '₹${NumberFormat.compact().format(pipelineVal)}',
                      '$totalLeads Leads',
                      AppColors.accentGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Telephony Savings',
                      '₹$savedRupees',
                      '₹0 Free Calling',
                      AppColors.successGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      'Conversion Rate',
                      '$winRate%',
                      '${wonLeads.length} Won Deals',
                      Colors.purpleAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Conversion Pipeline Funnel
              const Text(
                'LIVE CONVERSION FUNNEL',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              GlassCard(
                child: Column(
                  children: [
                    _buildFunnelRow(
                      'Total Captured Leads',
                      '$totalLeads Leads',
                      1.0,
                      AppColors.accentGold,
                    ),
                    _buildFunnelRow(
                      'Connected & Qualified',
                      '${qualifiedLeads.length} Leads',
                      totalLeads > 0 ? (qualifiedLeads.length / totalLeads) : 0.0,
                      AppColors.outboundCall,
                    ),
                    _buildFunnelRow(
                      '1-Tap Quotes Sent',
                      '${quoteSentLeads.length} Quotes',
                      totalLeads > 0 ? (quoteSentLeads.length / totalLeads) : 0.0,
                      Colors.orangeAccent,
                    ),
                    _buildFunnelRow(
                      'Won Pilgrimage Bookings',
                      '${wonLeads.length} Bookings (₹${NumberFormat.compact().format(wonVal)})',
                      totalLeads > 0 ? (wonLeads.length / totalLeads) : 0.0,
                      AppColors.successGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Live Presence & Website Telemetry
              const Text(
                'WEBSITE & TELEPHONY RADAR (TAP TO INSPECT)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              GlassCard(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => LiveActivitySheet.show(context),
                      borderRadius: BorderRadius.circular(10),
                      child: _buildRadarRow(
                        icon: Icons.radar_rounded,
                        title: 'Live Website Visitors ($activeNow Active Now)',
                        subtitle: 'Tap to inspect pages, devices & IPs ($totalTracked total tracked)',
                        value: '$liveVisitors (24h)',
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    _buildRadarRow(
                      icon: Icons.phone_callback_rounded,
                      title: 'Pending Jio SIM Calls',
                      subtitle: 'Web callers waiting for callback',
                      value: '${callProvider.pendingQueue.length} Waiting',
                      color: callProvider.pendingQueue.isNotEmpty
                          ? AppColors.errorRed
                          : AppColors.successGreen,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    _buildRadarRow(
                      icon: Icons.hub_rounded,
                      title: 'Multi-CRM Gateway',
                      subtitle: 'WordPress DB, FluentCRM, TwentyCRM',
                      value: 'Active',
                      color: AppColors.successGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Sales Leaderboard (Dynamic Aggregation from Live CRM & WhatsApp Hub)
              const Text(
                'SALES TEAM & OMNICHANNEL LEADERBOARD',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              Builder(
                builder: (context) {
                  final ownerMap = <String, int>{};
                  final ownerWonMap = <String, double>{};
                  for (final l in leads) {
                    final owner = l.stickyAgent.trim().isNotEmpty ? l.stickyAgent.trim() : 'Santosh Yadav';
                    ownerMap[owner] = (ownerMap[owner] ?? 0) + 1;
                    if (['advance_received', 'won', 'traveling', 'completed'].contains(l.stage.toLowerCase())) {
                      ownerWonMap[owner] = (ownerWonMap[owner] ?? 0.0) + l.dealValue;
                    }
                  }
                  if (ownerMap.isEmpty) {
                    ownerMap['Santosh Yadav'] = 0;
                  }
                  final sortedOwners = ownerMap.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return GlassCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < sortedOwners.length; i++) ...[
                          if (i > 0) const Divider(color: AppColors.borderSubtle, height: 16),
                          _buildLeaderboardRow(
                            '#${i + 1}',
                            sortedOwners[i].key,
                            i == 0
                                ? '${sortedOwners[i].value} leads • $totalCalls calls (${(totalDurationSecs ~/ 60)}m)'
                                : '${sortedOwners[i].value} active CRM threads assigned',
                            (ownerWonMap[sortedOwners[i].key] ?? 0) > 0
                                ? '₹${NumberFormat.compact().format(ownerWonMap[sortedOwners[i].key])} won'
                                : '${sortedOwners[i].value} Active',
                          ),
                        ],
                        const Divider(color: AppColors.borderSubtle, height: 16),
                        _buildLeaderboardRow(
                          '🤖',
                          'AI Sales Concierge (Bot 155464)',
                          '$liveVisitors visitors (24h) • $activeNow active now',
                          '24/7 Live RAG',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String badge,
    Color badgeColor,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(
    String label,
    String count,
    double progress,
    Color color,
  ) {
    final validProgress = progress.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: validProgress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(
    String rank,
    String name,
    String calls,
    String bookings,
  ) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank == '#1'
                ? AppColors.accentGold.withValues(alpha: 0.2)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: rank == '#1'
                  ? AppColors.accentGold
                  : AppColors.borderSubtle,
            ),
          ),
          child: Text(
            rank,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: rank == '#1' ? AppColors.accentGold : AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                calls,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(
          bookings,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.successGreen,
          ),
        ),
      ],
    );
  }
}
