import 'dart:math';
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

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _financialData;
  bool _isLoadingFinancials = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinancials();
    });
  }

  Future<void> _loadFinancials() async {
    if (!mounted) return;
    setState(() => _isLoadingFinancials = true);
    try {
      final leadProvider = Provider.of<LeadProvider>(context, listen: false);
      final data = await leadProvider.apiService.fetchFinancials();
      if (mounted) {
        setState(() {
          _financialData = data;
          _isLoadingFinancials = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFinancials = false);
      }
    }
  }

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

    final localPipelineVal = leads.fold(0.0, (sum, l) => sum + l.dealValue);
    final localWonVal = wonLeads.fold(0.0, (sum, l) => sum + l.dealValue);

    // Financial summary from server
    final summary = _financialData?['summary'] as Map<String, dynamic>?;
    final gmv = (summary?['gmv'] as num?)?.toDouble() ?? localWonVal;
    final collected = (summary?['total_collected'] as num?)?.toDouble() ?? 0.0;
    final pendingReceivables = (summary?['pending_receivables'] as num?)?.toDouble() ?? max(0.0, gmv - collected);
    final pipelineVal = (summary?['pipeline_value'] as num?)?.toDouble() ?? localPipelineVal;
    final collectionRate = (summary?['collection_rate'] as num?)?.toDouble() ?? (gmv > 0 ? (collected / gmv * 100) : 0.0);

    final methodSplit = _financialData?['method_split'] as Map<String, dynamic>? ?? {};
    final recentTx = (_financialData?['recent_transactions'] as List<dynamic>?) ?? [];
    final serverLeaderboard = (_financialData?['sales_leaderboard'] as List<dynamic>?) ?? [];

    final winRate = totalLeads > 0 ? ((wonLeads.length / totalLeads) * 100).toStringAsFixed(1) : '0.0';

    final totalCalls = callProvider.callLogs.length;
    final liveVisitors = eventProvider.visitors24hCount;
    final activeNow = eventProvider.activeNowCount;

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
              'Financials & CRM Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Real-Time Live Revenue, Cashflow & Pipeline',
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
              _loadFinancials();
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
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              leadProvider.refreshLeadsFromServer(),
              _loadFinancials(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. FINANCIAL REVENUE & CASHFLOW AUDIT (Featured Card)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'REAL-TIME FINANCIAL AUDIT & CASHFLOW',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (_isLoadingFinancials)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildFinancialMetric(
                              title: 'Gross Merchandise (GMV)',
                              amount: '₹${NumberFormat('#,##,###').format(gmv > 0 ? gmv : localWonVal)}',
                              subtitle: '${wonLeads.length} Confirmed Bookings',
                              color: const Color(0xFF10B981),
                              icon: Icons.account_balance_wallet_rounded,
                            ),
                          ),
                          Container(width: 1, height: 48, color: AppColors.borderSubtle),
                          Expanded(
                            child: _buildFinancialMetric(
                              title: 'Advance Collected',
                              amount: '₹${NumberFormat('#,##,###').format(collected)}',
                              subtitle: '${collectionRate.toStringAsFixed(1)}% collected',
                              color: AppColors.accentGold,
                              icon: Icons.check_circle_rounded,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFinancialMetric(
                              title: 'Balance Receivables',
                              amount: '₹${NumberFormat('#,##,###').format(pendingReceivables)}',
                              subtitle: 'Payable on Destination',
                              color: const Color(0xFFF59E0B),
                              icon: Icons.pending_actions_rounded,
                            ),
                          ),
                          Container(width: 1, height: 48, color: AppColors.borderSubtle),
                          Expanded(
                            child: _buildFinancialMetric(
                              title: 'Active Pipeline Value',
                              amount: '₹${NumberFormat('#,##,###').format(pipelineVal)}',
                              subtitle: '$totalLeads Total Inquiries',
                              color: const Color(0xFF38BDF8),
                              icon: Icons.trending_up_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. PAYMENT METHODS SPLIT
                const Text(
                  'PAYMENT CHANNELS & GATEWAY SETTLEMENT',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildMethodBadge(
                        label: 'Cashfree PG',
                        amount: '₹${NumberFormat('#,##,###').format((methodSplit['cashfree'] as num?)?.toDouble() ?? 0.0)}',
                        icon: Icons.credit_card_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMethodBadge(
                        label: 'Direct UPI',
                        amount: '₹${NumberFormat('#,##,###').format((methodSplit['upi'] as num?)?.toDouble() ?? 0.0)}',
                        icon: Icons.qr_code_scanner_rounded,
                        color: const Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMethodBadge(
                        label: 'Cash / Bank',
                        amount: '₹${NumberFormat('#,##,###').format(((methodSplit['cash'] as num?)?.toDouble() ?? 0.0) + ((methodSplit['bank'] as num?)?.toDouble() ?? 0.0))}',
                        icon: Icons.payments_rounded,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. RECENT TRANSACTIONS FEED
                if (recentTx.isNotEmpty) ...[
                  const Text(
                    'RECENT TRANSACTIONS & RECEIPTS',
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
                      children: recentTx.take(5).map((tx) {
                        final txMap = tx as Map<String, dynamic>;
                        final amt = (txMap['amount'] as num?)?.toDouble() ?? 0.0;
                        final status = (txMap['status'] as String?) ?? 'created';
                        final method = (txMap['method'] as String?) ?? 'upi';
                        final isPaid = status == 'paid';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isPaid ? AppColors.successGreen.withValues(alpha: 0.15) : Colors.orangeAccent.withValues(alpha: 0.15),
                                child: Icon(
                                  isPaid ? Icons.check_circle_outline : Icons.receipt_long_rounded,
                                  size: 16,
                                  color: isPaid ? AppColors.successGreen : Colors.orangeAccent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      txMap['customer_name'] ?? 'Traveler',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                    Text(
                                      '${txMap['booking_ref'] ?? 'Ref'} • ${method.toUpperCase()}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${NumberFormat('#,##,###').format(amt)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isPaid ? AppColors.successGreen : Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: (isPaid ? AppColors.successGreen : Colors.orangeAccent).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: isPaid ? AppColors.successGreen : Colors.orangeAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. TELEPHONY & ZERO-COST KPI GRID
                const Text(
                  'TELEPHONY SAVINGS & PERFORMANCE',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

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
                        'Telephony Savings',
                        '₹$savedRupees',
                        '₹0 Free Calling',
                        AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Conversion Rate',
                        '$winRate%',
                        '${wonLeads.length} Won Deals',
                        Colors.purpleAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        'Live Visitors (24h)',
                        '$liveVisitors',
                        '$activeNow Active Now',
                        const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. CONVERSION PIPELINE FUNNEL
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
                        '${wonLeads.length} Bookings (₹${NumberFormat.compact().format(gmv > 0 ? gmv : localWonVal)})',
                        totalLeads > 0 ? (wonLeads.length / totalLeads) : 0.0,
                        AppColors.successGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. SALES LEADERBOARD
                const Text(
                  'SALES TEAM & OMNICHANNEL REVENUE LEADERBOARD',
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
                    if (serverLeaderboard.isNotEmpty) {
                      return GlassCard(
                        child: Column(
                          children: serverLeaderboard.take(5).toList().asMap().entries.map((entry) {
                            final idx = entry.key;
                            final agent = entry.value as Map<String, dynamic>;
                            final name = (agent['agent_name'] as String?) ?? 'Agent';
                            final wonCount = (agent['deals_won'] as num?)?.toInt() ?? 0;
                            final rev = (agent['revenue'] as num?)?.toDouble() ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: _buildLeaderboardRow(
                                '#${idx + 1}',
                                name,
                                '$wonCount Won Deals',
                                '₹${NumberFormat.compact().format(rev)}',
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }

                    // Fallback to local leads aggregation
                    final ownerMap = <String, int>{};
                    final ownerWonMap = <String, double>{};
                    for (final l in leads) {
                      final owner = l.stickyAgent.isNotEmpty ? l.stickyAgent : 'Unassigned';
                      ownerMap[owner] = (ownerMap[owner] ?? 0) + 1;
                      if (['advance_received', 'won', 'traveling', 'completed'].contains(l.stage.toLowerCase())) {
                        ownerWonMap[owner] = (ownerWonMap[owner] ?? 0.0) + l.dealValue;
                      }
                    }

                    final sortedOwners = ownerMap.keys.toList()
                      ..sort((a, b) => (ownerWonMap[b] ?? 0.0).compareTo(ownerWonMap[a] ?? 0.0));

                    return GlassCard(
                      child: Column(
                        children: sortedOwners.take(5).toList().asMap().entries.map((entry) {
                          final idx = entry.key;
                          final owner = entry.value;
                          final count = ownerMap[owner] ?? 0;
                          final wonRev = ownerWonMap[owner] ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: _buildLeaderboardRow(
                              '#${idx + 1}',
                              owner,
                              '$count Assigned Leads',
                              '₹${NumberFormat.compact().format(wonRev)}',
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialMetric({
    required String title,
    required String amount,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBadge({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(String stage, String count, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stage,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 13,
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
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(String rank, String name, String calls, String bookings) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank == '#1' ? AppColors.accentGold.withValues(alpha: 0.2) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: rank == '#1' ? AppColors.accentGold : AppColors.borderSubtle,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                calls,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
