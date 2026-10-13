import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../services/telephony_service.dart';
import 'glass_card.dart';
import 'whatsapp_live_chat_sheet.dart';

class CallerIdOverlaySheet extends StatelessWidget {
  final String phone;
  final String customerName;
  final String destination;
  final String source;
  final String budget;
  final int pax;
  final String? lastNote;
  final VoidCallback? onCallPressed;

  const CallerIdOverlaySheet({
    super.key,
    required this.phone,
    required this.customerName,
    this.destination = 'Varanasi 3D2N Spiritual Circuit',
    this.source = 'website_chat',
    this.budget = '₹25,000 - ₹35,000',
    this.pax = 4,
    this.lastNote,
    this.onCallPressed,
  });

  factory CallerIdOverlaySheet.fromLead(
    LeadModel lead, {
    VoidCallback? onCallPressed,
  }) {
    return CallerIdOverlaySheet(
      phone: lead.phone,
      customerName: lead.name,
      destination: lead.destination,
      source: lead.source,
      budget: lead.budget.isNotEmpty ? lead.budget : '₹25,000',
      pax: lead.pax,
      lastNote: lead.notes.isNotEmpty ? lead.notes.first : lead.lastChatSummary,
      onCallPressed: onCallPressed,
    );
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header: Smart Caller-ID Badge & SIM
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentGold.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: AppColors.accentGold, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'SMART CALLER-ID',
                      style: TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.jioBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Jio 5G Primary SIM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Traveler Name & Phone
          Text(
            customerName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.accentGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // High-Intent Lead Profile Card
          GlassCard(
            padding: const EdgeInsets.all(14),
            backgroundColor: AppColors.surfaceElevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.temple_hindu,
                      color: AppColors.accentGold,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        destination,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildPill(Icons.people, '$pax Travelers'),
                    const SizedBox(width: 8),
                    _buildPill(Icons.currency_rupee, budget),
                    const SizedBox(width: 8),
                    _buildPill(Icons.campaign, source.toUpperCase()),
                  ],
                ),
                if (lastNote != null && lastNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 8),
                  Text(
                    'Recent Context: $lastNote',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Call & WhatsApp
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      onCallPressed ?? () => TelephonyService.dialNumber(phone),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    WhatsAppLiveChatSheet.show(
                      context,
                      leadId: 'incoming_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
                      customerName: customerName,
                      phone: phone,
                      destination: destination,
                      initialMessage:
                          'Namaste $customerName ji! This is Santosh from TripCosmos.co regarding your $destination inquiry.',
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Live Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsappGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
