import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/call_provider.dart';
import '../providers/whatsapp_provider.dart';
import 'ai_agents_screen.dart';
import 'dialer_screen.dart';
import 'leads_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'whatsapp_hub_screen.dart';
import '../services/api_service.dart';
import '../widgets/active_call_hud.dart';
import '../widgets/live_activity_banner.dart';
import '../widgets/post_call_action_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  final ApiService? apiService;

  const MainNavigationScreen({super.key, this.apiService});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DialerScreen(),
    LeadsScreen(),
    AiAgentsScreen(),
    WhatsAppHubScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final pendingCount = callProvider.pendingQueue.length;
    final wpProvider = Provider.of<WhatsAppProvider>(context);
    final wpUnread = wpProvider.totalUnreadCount;

    // Trigger Post-Call Action Sheet whenever a call ends anywhere across screens
    if (callProvider.lastCompletedCall != null) {
      final completedCall = callProvider.lastCompletedCall!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || callProvider.lastCompletedCall == null) return;
        callProvider.clearLastCompletedCall();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => PostCallActionSheet(
            callLog: completedCall,
            onDismiss: () => Navigator.pop(ctx),
          ),
        );
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
      ],
    );



    return Scaffold(
      body: mainContent,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light ? Colors.white : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.light ? AppColors.lightBorderSubtle : AppColors.borderSubtle,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.white : AppColors.surface,
          selectedItemColor: AppColors.accentGold,
          unselectedItemColor: Theme.of(context).brightness == Brightness.light ? AppColors.lightTextMuted : AppColors.textMuted,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.phone_rounded),
                  if (pendingCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.errorRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Dialer',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Leads CRM',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_rounded),
              label: 'AI Agents',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_rounded),
                  if (wpUnread > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$wpUnread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'WhatsApp',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart_rounded),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}
