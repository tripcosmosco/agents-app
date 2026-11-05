import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/website_radar_provider.dart';
import '../screens/ai_agents_screen.dart';
import '../screens/catalog_screen.dart';
import '../screens/google_ads_cockpit_screen.dart';
import '../screens/settings_screen.dart';
import 'website_radar_dialog.dart';

class WorkspaceDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelectTab;

  const WorkspaceDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final radar = context.watch<WebsiteRadarProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF070D1E) : const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('TC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'TripCosmos Agent',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? 'tripcosmos.co',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : AppColors.lightTextMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Live Website Radar Action Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  WebsiteRadarDialog.show(context);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Live Website Radar (${radar.activeCount} Online)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF10B981)),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation Hub Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                children: [
                  _buildDrawerItem(context, 0, Icons.phone_rounded, 'Dialer', isDark),
                  _buildDrawerItem(context, 1, Icons.people_alt_rounded, 'Leads CRM', isDark),
                  _buildDrawerItem(context, 2, Icons.chat_rounded, 'WhatsApp Hub', isDark),
                  _buildDrawerItem(context, 3, Icons.hub_rounded, 'Sovereign Agents (Paperclip)', isDark),
                  _buildDrawerItem(context, 4, Icons.business_center_rounded, 'B2B Network Hub', isDark),
                  _buildDrawerItem(context, 5, Icons.account_balance_wallet_rounded, 'Finance & Margins Hub', isDark),
                  _buildDrawerItem(context, 6, Icons.article_rounded, 'Blog & SEO Brain', isDark),
                  _buildDrawerItem(context, 7, Icons.share_rounded, 'VM Social AI', isDark),
                  _buildDrawerItem(context, 8, Icons.insert_chart_rounded, 'Reports & Analytics', isDark),

                  const Divider(height: 20, color: Colors.white12),

                  // Power Tool Shortcuts
                  _buildShortcutTile(
                    context,
                    Icons.ads_click_rounded,
                    'Google Ads Cockpit (Shown.io)',
                    const Color(0xFF2563EB),
                    () {
                      Navigator.pop(context);
                      GoogleAdsCockpitScreen.open(context);
                    },
                    isDark,
                  ),
                  _buildShortcutTile(
                    context,
                    Icons.menu_book_rounded,
                    'Tour & Package Catalog',
                    const Color(0xFFF59E0B),
                    () {
                      Navigator.pop(context);
                      CatalogScreen.open(context);
                    },
                    isDark,
                  ),
                  _buildShortcutTile(
                    context,
                    Icons.psychology_rounded,
                    'Master AI Co-Pilot',
                    const Color(0xFF8B5CF6),
                    () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAgentsScreen()));
                    },
                    isDark,
                  ),
                  _buildShortcutTile(
                    context,
                    Icons.open_in_new_rounded,
                    'Paperclip Console Web',
                    const Color(0xFF38BDF8),
                    () {
                      Navigator.pop(context);
                      launchUrl(Uri.parse('https://agents.vmstudio.digital'), mode: LaunchMode.externalApplication);
                    },
                    isDark,
                  ),
                ],
              ),
            ),

            // Drawer Footer: Settings
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black87,
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text('Settings', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SettingsScreen(apiService: auth.apiService)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    bool isDark,
  ) {
    final isSelected = currentIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.22 : 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: Icon(
          icon,
          size: 19,
          color: isSelected ? const Color(0xFF38BDF8) : (isDark ? Colors.white60 : Colors.black54),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? const Color(0xFF38BDF8) : (isDark ? Colors.white : AppColors.lightTextPrimary),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          onSelectTab(index);
        },
      ),
    );
  }

  Widget _buildShortcutTile(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: Icon(icon, size: 18, color: color),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
