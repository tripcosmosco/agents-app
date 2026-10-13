import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/event_model.dart';
import '../providers/call_provider.dart';
import '../providers/event_provider.dart';

class LiveActivitySheet extends StatefulWidget {
  const LiveActivitySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const LiveActivitySheet(),
    );
  }

  @override
  State<LiveActivitySheet> createState() => _LiveActivitySheetState();
}

class _LiveActivitySheetState extends State<LiveActivitySheet> {
  int _selectedTab = 0; // 0 = Website Visitors, 1 = All Activity & Leads

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<EventProvider>(context, listen: false).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final allEvents = eventProvider.events;
    final visitorEvents = allEvents.where((e) => e.isVisitorLanding).toList();
    final displayedEvents = _selectedTab == 0 ? visitorEvents : allEvents;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.radar_rounded, color: AppColors.successGreen, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Website Visitor & Lead Radar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Real-time telemetry from tripcosmos.co (Page, Device, IP & Leads)',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => eventProvider.refresh(),
                  icon: eventProvider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold),
                        )
                      : const Icon(Icons.refresh, color: AppColors.accentGold, size: 20),
                  tooltip: 'Refresh Live Feed',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4-Card Live Server Telemetry KPI Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildKpiMiniCard(
                  label: 'Active (15m)',
                  value: '${eventProvider.activeNowCount}',
                  color: AppColors.successGreen,
                  icon: Icons.circle,
                ),
                const SizedBox(width: 8),
                _buildKpiMiniCard(
                  label: '24h Visitors',
                  value: '${eventProvider.visitors24hCount}',
                  color: const Color(0xFF38BDF8),
                  icon: Icons.visibility_rounded,
                ),
                const SizedBox(width: 8),
                _buildKpiMiniCard(
                  label: 'Total Tracked',
                  value: '${eventProvider.totalVisitorsAll}',
                  color: AppColors.accentGold,
                  icon: Icons.public_rounded,
                ),
                const SizedBox(width: 8),
                _buildKpiMiniCard(
                  label: '24h Leads',
                  value: '${eventProvider.leadsCapturedToday}',
                  color: const Color(0xFFA855F7),
                  icon: Icons.person_add_alt_1_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Filter Tabs: Website Visitors vs All Activity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    label: '👁️ Website Visitors (${visitorEvents.length})',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    label: '⚡ All Events & Leads (${allEvents.length})',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(color: AppColors.borderSubtle, height: 1),

          // Event Stream List
          Expanded(
            child: displayedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          size: 48,
                          color: AppColors.textMuted.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          eventProvider.isLoading
                              ? 'Loading live telemetry from tripcosmos.co...'
                              : 'No recent events in this view',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: () => eventProvider.refresh(),
                          icon: const Icon(Icons.refresh, size: 16, color: AppColors.accentGold),
                          label: const Text(
                            'Tap to Refresh Now',
                            style: TextStyle(color: AppColors.accentGold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: displayedEvents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ev = displayedEvents[index];
                      return _buildEventTile(context, ev);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMiniCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold.withValues(alpha: 0.18)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : AppColors.borderSubtle,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accentGold : AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, EventModel ev) {
    final isLead = ev.isLeadCapture;
    final isCall = ev.isCallQueued;
    final isVisitor = ev.isVisitorLanding;
    final isOnlineNow = ev.details['is_online_now'] == true;

    final tileColor = isLead
        ? const Color(0xFF0F2E1E)
        : isCall
            ? const Color(0xFF2E1A0F)
            : AppColors.surfaceCard;

    final accentColor = isLead
        ? AppColors.successGreen
        : isCall
            ? AppColors.accentGold
            : isOnlineNow
                ? AppColors.successGreen
                : const Color(0xFF38BDF8);

    final icon = isLead
        ? Icons.person_add_alt_1_rounded
        : isCall
            ? Icons.phone_forwarded_rounded
            : Icons.public_rounded;

    final timeStr = ev.details['time_ago']?.toString().isNotEmpty == true
        ? ev.details['time_ago'].toString()
        : DateFormat('hh:mm a').format(ev.createdAt);

    final phone = (ev.details['phone'] ?? ev.details['visitor_phone'] ?? '').toString();
    final pageUrl = (ev.details['page_url'] ?? '').toString();
    final pageTitle = (ev.details['page_title'] ?? '').toString();
    final device = (ev.details['device'] ?? '').toString();
    final ip = (ev.details['ip'] ?? '').toString();
    final country = (ev.details['country'] ?? '').toString();
    final city = (ev.details['city'] ?? '').toString();
    final referrer = (ev.details['referrer'] ?? '').toString();
    final sessionId = (ev.details['session_id'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: isLead || isCall || isOnlineNow ? 0.65 : 0.22),
          width: isOnlineNow ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isOnlineNow) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.successGreen, width: 0.8),
                            ),
                            child: const Text(
                              '🟢 ONLINE NOW',
                              style: TextStyle(
                                color: AppColors.successGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            isVisitor && pageTitle.isNotEmpty ? pageTitle : ev.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isVisitor && pageUrl.isNotEmpty)
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: pageUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied URL: $pageUrl'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 13, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pageUrl,
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 11, color: AppColors.textMuted),
                          ],
                        ),
                      )
                    else
                      Text(
                        ev.subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontSize: 11.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Visitor Telemetry Chips (Device, IP, Location, Referrer, Session)
          if (isVisitor) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (device.isNotEmpty)
                  _buildMetaChip(Icons.devices_rounded, device, AppColors.accentGold),
                if (ip.isNotEmpty)
                  _buildMetaChip(
                    Icons.router_rounded,
                    [
                      'IP: $ip',
                      if (city.isNotEmpty) city,
                      if (country.isNotEmpty) country,
                    ].join(' • '),
                    AppColors.textSecondary,
                  ),
                if (referrer.isNotEmpty)
                  _buildMetaChip(Icons.ads_click_rounded, 'Ref: $referrer', const Color(0xFFA855F7)),
                if (sessionId.isNotEmpty)
                  _buildMetaChip(
                    Icons.fingerprint_rounded,
                    'ID: ${sessionId.length > 12 ? sessionId.substring(0, 12) : sessionId}',
                    AppColors.textMuted,
                  ),
              ],
            ),
          ],

          // Action Row if Phone is known
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    final callProvider = Provider.of<CallProvider>(context, listen: false);
                    callProvider.startOutboundCall(
                      phone: phone,
                      name: (ev.details['name'] ?? ev.details['visitor_name'] ?? 'Traveler').toString(),
                      tourInterest: (ev.details['destination'] ?? pageTitle).toString(),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 12, color: AppColors.surface),
                        const SizedBox(width: 4),
                        Text(
                          'Dial $phone via Jio SIM',
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
