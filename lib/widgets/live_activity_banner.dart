import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/call_provider.dart';
import '../providers/event_provider.dart';
import '../providers/lead_provider.dart';
import 'caller_id_overlay_sheet.dart';

class LiveActivityBanner extends StatelessWidget {
  final VoidCallback? onOpenLeadCrm;

  const LiveActivityBanner({super.key, this.onOpenLeadCrm});

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final alert = eventProvider.activeAlert;

    if (alert == null) {
      return const SizedBox.shrink();
    }

    final isLead = alert.isLeadCapture;
    final isCall = alert.isCallQueued;

    final bannerBg = isLead
        ? const Color(0xFF0F2E1E)
        : isCall
            ? const Color(0xFF2E1A0F)
            : const Color(0xFF131D3B);

    final borderColor = isLead
        ? AppColors.successGreen
        : isCall
            ? AppColors.accentGold
            : const Color(0xFF3B82F6);

    final icon = isLead
        ? Icons.person_add_alt_1_rounded
        : isCall
            ? Icons.phone_forwarded_rounded
            : Icons.visibility_rounded;

    final phone = alert.details['phone']?.toString() ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              eventProvider.dismissAlert();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => CallerIdOverlaySheet(
                  phone: phone.isNotEmpty ? phone : '+91 93361 16210',
                  customerName: alert.details['name']?.toString() ?? alert.title,
                  destination: alert.details['destination']?.toString() ?? 'Varanasi Pilgrimage',
                  source: alert.details['source']?.toString() ?? 'live_event',
                  budget: alert.details['budget']?.toString() ?? '₹25,000',
                  pax: int.tryParse(alert.details['pax']?.toString() ?? '2') ?? 2,
                  lastNote: alert.subtitle,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bannerBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor.withValues(alpha: 0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Glowing Icon Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: borderColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Event Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              alert.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: borderColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alert.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Action Button (Call or View Lead)
                if (isLead && phone.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      eventProvider.dismissAlert();
                      final callProvider = Provider.of<CallProvider>(context, listen: false);
                      callProvider.startOutboundCall(
                        phone: phone,
                        name: alert.details['name']?.toString() ?? 'Traveler',
                        tourInterest: alert.details['destination']?.toString(),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, size: 13, color: AppColors.surface),
                          SizedBox(width: 4),
                          Text(
                            'Jio Call',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else if (isLead) ...[
                  InkWell(
                    onTap: () {
                      eventProvider.dismissAlert();
                      final leadProvider = Provider.of<LeadProvider>(context, listen: false);
                      leadProvider.refreshLeadsFromServer();
                      onOpenLeadCrm?.call();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'View Lead',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Close Button
                IconButton(
                  onPressed: () => eventProvider.dismissAlert(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Dismiss',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
