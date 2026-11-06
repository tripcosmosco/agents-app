import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/website_visitor_model.dart';
import '../providers/website_radar_provider.dart';
import '../screens/agents_screen.dart';
import '../services/paperclip_service.dart';
import 'glass_card.dart';
import 'live_activity_sheet.dart';

class WebsiteRadarDialog extends StatelessWidget {
  const WebsiteRadarDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const WebsiteRadarDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radar = context.watch<WebsiteRadarProvider>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final visitors = radar.visitors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 650),
            decoration: BoxDecoration(
              color: (isLight ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.radar_rounded, size: 20, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Live Website Visitor Radar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isLight ? AppColors.lightTextPrimary : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${radar.activeCount} Online',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Real-time traffic & high-intent visitor telemetry • tripcosmos.co',
                              style: TextStyle(
                                fontSize: 11,
                                color: isLight ? AppColors.lightTextMuted : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.history_rounded, size: 20),
                        tooltip: 'View Full Visitor Activity Stream',
                        onPressed: () {
                          Navigator.pop(context);
                          LiveActivitySheet.show(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),

                // Visitor List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: visitors.length,
                    itemBuilder: (context, index) {
                      final v = visitors[index];
                      return _buildVisitorCard(context, v, isLight, radar);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorCard(
    BuildContext context,
    WebsiteVisitor v,
    bool isLight,
    WebsiteRadarProvider radar,
  ) {
    Color intentColor = const Color(0xFF10B981);
    if (v.intentScore < 60) intentColor = Colors.grey;
    if (v.intentScore >= 60 && v.intentScore < 80) intentColor = const Color(0xFF38BDF8);
    if (v.intentScore >= 80) intentColor = const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(v.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${v.city}, ${v.country}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isLight ? AppColors.lightTextPrimary : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: intentColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${v.intentScore}% ${v.intentLabel.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: intentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        v.pageTitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isLight ? AppColors.lightTextMuted : Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.psychology_rounded, size: 14),
                  label: const Text('TRI-LEAD', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  onPressed: () => _dispatchTriLead(context, v),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    minimumSize: const Size(0, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 14),
                  label: const Text('Ping', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  onPressed: () => _showPingDialog(context, v, radar),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.link_rounded, size: 12, color: isLight ? Colors.black45 : Colors.white38),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    v.currentPage,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      color: isLight ? Colors.blue.shade700 : const Color(0xFF38BDF8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${v.durationSeconds}s duration • ${v.scrollDepth}% scrolled',
                  style: TextStyle(
                    fontSize: 10,
                    color: isLight ? Colors.black45 : Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _dispatchTriLead(BuildContext context, WebsiteVisitor v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AgentChatSheet(
        agent: const {
          'id': '1a753736-faf4-4fbb-872d-b2fa1d57eaf0',
          'name': 'TRI-LEAD',
          'role': 'cmo',
          'title': 'Traveler Intake & VIP Triage',
          'capabilities': ['inbound_triage', 'whatsapp_dispatch', 'itinerary_routing', 'radar_intercept'],
        },
        companyId: 'b66bdec2-ddf6-4199-9161-da5c6ee60ef8',
        service: PaperclipService(),
      ),
    );
  }

  void _showPingDialog(BuildContext context, WebsiteVisitor v, WebsiteRadarProvider radar) {
    final promptController = TextEditingController(
      text: 'Namaste! 🙏 Noticed you are exploring our ${v.pageTitle}. Would you like instant dates, Sugam Darshan assistance, or luxury cab tariffs?',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(v.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Proactive Chat Ping to ${v.city}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: promptController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  hintText: 'Enter proactive greeting message...',
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Dispatch Proactive Ping', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final text = promptController.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);
                  final ok = await radar.proactivePing(visitor: v, promptMessage: text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? '✓ Proactive ping sent to ${v.city} traveler!'
                            : 'Proactive ping dispatched via website telemetry.'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
