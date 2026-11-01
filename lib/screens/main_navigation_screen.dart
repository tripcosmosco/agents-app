import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/call_provider.dart';
import '../providers/whatsapp_provider.dart';
import 'ai_agents_screen.dart';
import 'b2b_network_screen.dart';
import 'blog_seo_screen.dart';
import 'dialer_screen.dart';
import 'finance_hub_screen.dart';
import 'leads_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'social_hub_screen.dart';
import 'whatsapp_hub_screen.dart';
import '../services/api_service.dart';
import '../widgets/active_call_hud.dart';
import '../widgets/live_activity_banner.dart';
import '../widgets/master_ai_assistant_view.dart';
import '../widgets/post_call_action_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  final ApiService? apiService;

  const MainNavigationScreen({super.key, this.apiService});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isPostCallSheetOpen = false;
  final ScrollController _sliderNavScrollController = ScrollController();

  void _openMasterAiModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.90,
        child: MasterAiAssistantView(
          isBottomSheet: true,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  // Audited & Well-Structured 9-Screen Super-App Menu
  // 1. Dialer, 2. Leads, 3. WhatsApp, 4. AI Agents, 5. B2B Hub, 6. Finance Hub, 7. Blog & SEO, 8. Social AI, 9. Reports
  final List<Widget> _screens = const [
    DialerScreen(),         // 0: 📞 Frontline Voice & Telephony
    LeadsScreen(),          // 1: 👥 CRM Pipeline & Inbound Leads
    WhatsAppHubScreen(),    // 2: 💬 Live WhatsApp Multi-Desk & Escalation
    AiAgentsScreen(),       // 3: 🤖 AI Personas & Master Co-Pilot
    B2bNetworkScreen(),     // 4: 🏢 B2B Hub (Wholesale DMC Partners - Pos 5)
    FinanceHubScreen(),     // 5: 💳 Finance Hub (Zoho, Margins, SBI, Payroll - Pos 6)
    BlogSeoScreen(),        // 6: 📝 Blog & VM SEO Brain Intelligence
    SocialHubScreen(),      // 7: 📱 VM Social AI & Campaign Channels
    ReportsScreen(),        // 8: 📊 CRM Analytics & Telephony ROI
  ];

  @override
  void dispose() {
    _sliderNavScrollController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Ergonomic auto-centering for slider dock
    if (_sliderNavScrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      const itemWidth = 82.0;
      final targetOffset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      _sliderNavScrollController.animateTo(
        targetOffset.clamp(0.0, _sliderNavScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final pendingCount = callProvider.pendingQueue.length;
    final wpProvider = Provider.of<WhatsAppProvider>(context);
    final wpUnread = wpProvider.totalUnreadCount;
    final slaBreached = wpProvider.slaBreachedCount;

    // Trigger Post-Call Action Sheet safely whenever a call ends anywhere across screens
    if (callProvider.lastCompletedCall != null && !_isPostCallSheetOpen) {
      final completedCall = callProvider.lastCompletedCall!;
      _isPostCallSheetOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _isPostCallSheetOpen = false;
          return;
        }
        callProvider.clearLastCompletedCall();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => PostCallActionSheet(
            callLog: completedCall,
            onDismiss: () {
              if (Navigator.of(ctx).canPop()) {
                Navigator.pop(ctx);
              }
            },
          ),
        ).whenComplete(() {
          if (mounted) {
            setState(() {
              _isPostCallSheetOpen = false;
            });
          }
        });
      });
    }

    final mainContent = Stack(
      children: [
        IndexedStack(index: _currentIndex, children: _screens),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.apiService != null && !widget.apiService!.isAuthenticated)
                SafeArea(
                  bottom: false,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(apiService: widget.apiService!),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.vpn_key_rounded, color: AppColors.accentGold, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Connect Your Workspace',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    Text(
                                      'Tap to enter your API Token & sync live CRM',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: AppColors.accentGold, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              LiveActivityBanner(
                onOpenLeadCrm: () {
                  setState(() {
                    _currentIndex = 1; // Switch to Leads CRM tab
                  });
                },
              ),
              ActiveCallHud(
                onOpenLeadCrm: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: GestureDetector(
            onLongPress: () => _openMasterAiModal(context),
            child: FloatingActionButton(
              heroTag: 'fab_add_lead_global',
              backgroundColor: AppColors.accentGold,
              foregroundColor: Colors.black,
              elevation: 6,
              shape: const CircleBorder(),
              tooltip: 'Add Lead (Tap) | Master AI (Hold)',
              onPressed: () => LeadsScreen.showAddLeadDialog(context),
              child: const Icon(Icons.add_rounded, size: 32, color: Colors.black),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: mainContent,
      bottomNavigationBar: _buildFooterSliderBar(
        context,
        pendingCount: pendingCount,
        wpUnread: wpUnread,
        slaBreached: slaBreached,
      ),
    );
  }

  /// Modern Horizontal Footer Slider Navigation Bar
  Widget _buildFooterSliderBar(
    BuildContext context, {
    required int pendingCount,
    required int wpUnread,
    required int slaBreached,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final navItems = [
      _NavItem(
        label: 'Dialer',
        icon: Icons.phone_outlined,
        activeIcon: Icons.phone_rounded,
        badgeCount: pendingCount > 0 ? pendingCount : null,
        badgeColor: AppColors.errorRed,
      ),
      const _NavItem(
        label: 'Leads',
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_alt_rounded,
      ),
      _NavItem(
        label: 'WhatsApp',
        icon: Icons.chat_outlined,
        activeIcon: Icons.chat_rounded,
        badgeCount: wpUnread > 0 ? wpUnread : null,
        badgeColor: slaBreached > 0 ? Colors.redAccent : AppColors.whatsappGreen,
        isAlertBadge: slaBreached > 0,
      ),
      const _NavItem(
        label: 'AI Agents',
        icon: Icons.smart_toy_outlined,
        activeIcon: Icons.smart_toy_rounded,
      ),
      const _NavItem(
        label: 'B2B Hub',
        icon: Icons.hub_outlined,
        activeIcon: Icons.hub_rounded,
      ),
      const _NavItem(
        label: 'Finance Hub',
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
      ),
      const _NavItem(
        label: 'Blog & SEO',
        icon: Icons.article_outlined,
        activeIcon: Icons.article_rounded,
      ),
      const _NavItem(
        label: 'Social AI',
        icon: Icons.share_outlined,
        activeIcon: Icons.share_rounded,
      ),
      const _NavItem(
        label: 'Reports',
        icon: Icons.insert_chart_outlined_rounded,
        activeIcon: Icons.insert_chart_rounded,
      ),
    ];

    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isLight ? AppColors.lightBorderSubtle : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ListView.separated(
          controller: _sliderNavScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          itemCount: navItems.length,
          separatorBuilder: (_, _) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final item = navItems[index];
            final isSelected = _currentIndex == index;

            return InkWell(
              onTap: () => _onTabSelected(index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 78,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentGold.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentGold.withValues(alpha: 0.45)
                        : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? AppColors.accentGold
                              : AppColors.getTextMuted(context),
                          size: isSelected ? 21 : 20,
                        ),
                        if (item.badgeCount != null && item.badgeCount! > 0)
                          Positioned(
                            right: -8,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: item.badgeColor ?? AppColors.accentGold,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white, width: 0.8),
                              ),
                              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                              child: Text(
                                '${item.badgeCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accentGold
                            : AppColors.getTextSecondary(context),
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int? badgeCount;
  final Color? badgeColor;
  final bool isAlertBadge;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeCount,
    this.badgeColor,
    this.isAlertBadge = false,
  });
}
