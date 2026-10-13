import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/call_provider.dart';
import '../providers/event_provider.dart';
import '../providers/lead_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/whatsapp_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  final ApiService apiService;

  const SettingsScreen({super.key, required this.apiService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _tokenController;
  bool _obscureToken = true;

  bool _isTesting = false;
  Map<String, dynamic>? _testResult;

  bool _isSaving = false;

  bool _securityLockEnabled = false;
  String _savedPin = '1234';

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.apiService.baseUrl);
    _tokenController = TextEditingController(text: widget.apiService.apiToken ?? '');
    _loadSecurityPreferences();
  }

  Future<void> _loadSecurityPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _securityLockEnabled = prefs.getBool('tc_security_lock_enabled') ?? false;
        _savedPin = prefs.getString('tc_security_lock_pin') ?? '1234';
      });
    }
  }

  Future<void> _toggleSecurityLock(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tc_security_lock_enabled', val);
    setState(() {
      _securityLockEnabled = val;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val ? '✓ In-app privacy lock activated!' : 'Privacy lock disabled.'),
        ),
      );
    }
  }

  void _showChangePinDialog() {
    final pinController = TextEditingController(text: _savedPin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Change Security PIN', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a 4-digit PIN to secure your leads & app:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              style: const TextStyle(color: AppColors.accentGold, fontSize: 20, letterSpacing: 8),
              decoration: const InputDecoration(hintText: '••••'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
            onPressed: () async {
              final newPin = pinController.text.trim();
              if (newPin.length == 4) {
                final messenger = ScaffoldMessenger.of(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('tc_security_lock_pin', newPin);
                if (mounted) {
                  setState(() => _savedPin = newPin);
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                messenger.showSnackBar(
                  const SnackBar(content: Text('✓ 4-Digit Security PIN updated!')),
                );
              }
            },
            child: const Text('Save PIN', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final result = await widget.apiService.testConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = result;
      });
    }
  }

  Future<void> _saveSettings() async {
    final newUrl = _urlController.text.trim();
    final newToken = _tokenController.text.trim();

    if (newUrl.isEmpty || newToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Server URL and API Token.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = await widget.apiService.saveConfig(
      newBaseUrl: newUrl,
      newApiToken: newToken,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        // Refresh providers with updated connection
        context.read<LeadProvider>().refreshLeadsFromServer();
        context.read<CallProvider>().checkCallQueue();
        context.read<EventProvider>().refresh();
        context.read<WhatsAppProvider>().fetchThreadsFromServer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Server configuration saved successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save configuration.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Companion & Server Settings',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'Pair Android App with TripCosmos WordPress CRM',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: AppColors.accentGold,
                ),
                tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Appearance Selector Card
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.palette_outlined, color: AppColors.accentGold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Appearance & Theme Mode',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildThemeOption(
                                title: 'Dark Mode',
                                icon: Icons.dark_mode_rounded,
                                isSelected: themeProvider.themeMode == ThemeMode.dark,
                                onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildThemeOption(
                                title: 'Light Mode',
                                icon: Icons.light_mode_rounded,
                                isSelected: themeProvider.themeMode == ThemeMode.light,
                                onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildThemeOption(
                                title: 'System',
                                icon: Icons.brightness_auto_rounded,
                                isSelected: themeProvider.themeMode == ThemeMode.system,
                                onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // App Privacy & Security Gate Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.shield_outlined, color: AppColors.accentGold, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'App Privacy & Security Lock',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Require 4-digit PIN to open X-Agents',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _securityLockEnabled,
                          activeTrackColor: AppColors.accentGold,
                          onChanged: _toggleSecurityLock,
                        ),
                      ],
                    ),
                    if (_securityLockEnabled) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.borderSubtle),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pin_rounded, size: 16, color: AppColors.textMuted),
                              SizedBox(width: 8),
                              Text(
                                'Passcode: • • • •',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: _showChangePinDialog,
                            icon: const Icon(Icons.edit_rounded, size: 13, color: AppColors.accentGold),
                            label: const Text('Change PIN', style: TextStyle(fontSize: 11, color: AppColors.accentGold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.accentGold, width: 0.8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Hardware & Bridge Status Banner
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sim_card_rounded, color: AppColors.accentGold, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.officeJioDisplay,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Active Zero-Cost Jio SIM Calling Bridge & Lead Listener',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: REST API Configuration
              const Text(
                'WORDPRESS REST API CONFIGURATION',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Base URL Input
                    const Text(
                      'API Base URL',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'https://your-domain.com/wp-json/tc-agents/v1',
                        prefixIcon: const Icon(Icons.link_rounded, size: 18, color: AppColors.accentGold),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.replay_rounded, size: 18),
                          tooltip: 'Reset to default',
                          onPressed: () {
                            _urlController.text = AppConstants.defaultApiBaseUrl;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Mobile Token Input
                    const Text(
                      'Mobile Companion Secret Token (X-Mobile-Token)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tokenController,
                      obscureText: _obscureToken,
                      style: const TextStyle(fontSize: 13, letterSpacing: 0.8),
                      decoration: InputDecoration(
                        hintText: 'Paste or enter 32-character API token',
                        prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18, color: AppColors.accentGold),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.content_paste_rounded, size: 18, color: AppColors.accentGold),
                              tooltip: 'Paste from clipboard',
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null && data!.text!.isNotEmpty) {
                                  setState(() {
                                    _tokenController.text = data.text!.trim();
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Token pasted from clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _obscureToken ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureToken = !_obscureToken;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'How to connect: In your WordPress Admin, go to TripCosmos Agents > Settings > Mobile App Pairing to copy your personal API token and paste it here.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),

                    const SizedBox(height: 18),

                    // Test Result Display
                    if (_testResult != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testResult!['success'] == true
                              ? const Color(0xFF0F2E1E)
                              : const Color(0xFF2E1212),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _testResult!['success'] == true
                                ? AppColors.successGreen
                                : AppColors.errorRed,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _testResult!['success'] == true
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color: _testResult!['success'] == true
                                  ? AppColors.successGreen
                                  : AppColors.errorRed,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _testResult!['message']?.toString() ?? '',
                                style: TextStyle(
                                  color: _testResult!['success'] == true
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFFFCA5A5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isTesting ? null : _testConnection,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.bolt_rounded, size: 16),
                            label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accentGold,
                              side: const BorderSide(color: AppColors.accentGold),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveSettings,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                                  )
                                : const Icon(Icons.save_rounded, size: 16, color: AppColors.surface),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Settings',
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGold,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (widget.apiService.isAuthenticated) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Disconnect Workspace?'),
                                content: const Text(
                                  'This will clear your saved API token. You will need to enter a new token to sync leads.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Disconnect'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await widget.apiService.clearConfig();
                              if (mounted) {
                                setState(() {
                                  _tokenController.clear();
                                  _testResult = null;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Workspace disconnected.')),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.link_off_rounded, color: AppColors.errorRed, size: 16),
                          label: const Text('Disconnect Workspace', style: TextStyle(color: AppColors.errorRed, fontSize: 12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Server Features & Architecture Details
              const Text(
                'ACTIVE ENTERPRISE CAPABILITIES',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              _buildFeatureTile(
                Icons.mark_chat_unread_rounded,
                'Real-Time Visitor Presence & Lead Alerts',
                'Polls live events every 10s for instant banner alerts when travelers browse packages.',
                AppColors.successGreen,
              ),
              const SizedBox(height: 8),
              _buildFeatureTile(
                Icons.phone_in_talk_rounded,
                'Zero-Cost Outbound Telephony',
                'Pulls queued requests from web visitors and dials instantly through local Jio SIM.',
                AppColors.outboundCall,
              ),
              const SizedBox(height: 8),
              _buildFeatureTile(
                Icons.sync_alt_rounded,
                'Multi-CRM Bi-Directional Synchronization',
                'Synchronizes leads with WordPress CRM table, FluentCRM tags, and TwentyCRM.',
                AppColors.accentGold,
              ),

              const SizedBox(height: 28),

              // App Version
              Center(
                child: Text(
                  '${AppConstants.appFullName} • Version ${AppConstants.appVersion}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
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
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.accentGold
                : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accentGold : AppColors.textMuted,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accentGold : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
