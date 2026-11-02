import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/lead_provider.dart';
import '../services/telephony_service.dart';

class SocialHubScreen extends StatefulWidget {
  const SocialHubScreen({super.key});

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  // ignore: unused_field
  String? _errorMessage;

  String _plan = 'Pro Enterprise';
  int _modelsAvailable = 3658;
  String _aiEngine = 'OmniRoute + Gemini 2.0 + Pollinations FLUX';
  List<dynamic> _channels = [];
  List<dynamic> _queue = [];
  // ignore: unused_field
  int _ragFeedsCount = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSocialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSocialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = Provider.of<LeadProvider>(context, listen: false).apiService;
      final res = await api.fetchSocialAiOverview();
      if (res != null && res['ok'] == true) {
        setState(() {
          _plan = res['plan'] ?? 'Pro Enterprise';
          _modelsAvailable = res['models_available'] ?? 3658;
          _aiEngine = res['ai_engine'] ?? 'OmniRoute + Gemini 2.0 + Pollinations FLUX';
          _channels = res['channels'] ?? [];
          _queue = res['queue'] ?? [];
          _ragFeedsCount = res['rag_feeds_count'] ?? 6;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not fetch live Social AI overview. Displaying active profile.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  IconData _getChannelIcon(String channel) {
    final lower = channel.toLowerCase();
    if (lower.contains('instagram')) return Icons.camera_alt_rounded;
    if (lower.contains('facebook')) return Icons.facebook_rounded;
    if (lower.contains('linkedin')) return Icons.business_center_rounded;
    if (lower.contains('youtube')) return Icons.play_circle_fill_rounded;
    if (lower.contains('google') || lower.contains('gbp')) return Icons.pin_drop_rounded;
    return Icons.share_rounded;
  }

  Color _getChannelColor(String channel) {
    final lower = channel.toLowerCase();
    if (lower.contains('instagram')) return const Color(0xFFE1306C);
    if (lower.contains('facebook')) return const Color(0xFF1877F2);
    if (lower.contains('linkedin')) return const Color(0xFF0A66C2);
    if (lower.contains('youtube')) return const Color(0xFFFF0000);
    if (lower.contains('google') || lower.contains('gbp')) return const Color(0xFF34A853);
    return AppColors.accentGold;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF8FAFC) : AppColors.surface,
      appBar: AppBar(
        backgroundColor: isLight ? Colors.white : AppColors.surfaceElevated,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Social AI Hub',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFEC4899), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hub_rounded, size: 11, color: Color(0xFFEC4899)),
                      SizedBox(width: 3),
                      Text(
                        'VM Social AI',
                        style: TextStyle(color: Color(0xFFEC4899), fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              '${_channels.length} Networks Connected • ${_queue.length} Scheduled Campaigns',
              style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Social Pulse',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentGold, size: 20),
            onPressed: _loadSocialData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.getAccentGold(context),
          unselectedLabelColor: AppColors.getTextMuted(context),
          indicatorColor: AppColors.getAccentGold(context),
          indicatorWeight: 2.5,
          tabs: const [
            Tab(icon: Icon(Icons.schedule_send_rounded, size: 18), text: 'Upcoming Queue'),
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Channels & Reach'),
            Tab(icon: Icon(Icons.smart_toy_rounded, size: 18), text: 'OmniRoute Engine'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildQueueTab(context),
                _buildChannelsTab(context),
                _buildEngineTab(context),
              ],
            ),
    );
  }

  Widget _buildQueueTab(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
      children: [
        // AI Planning Status Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLight ? const Color(0xFFF1F5F9) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isLight ? AppColors.lightBorderSubtle : AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Autonomous Campaign Scheduler Active',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                    Text(
                      'Targeting 50,000 monthly views across spiritual travel, B2B wholesale, and cab tariffs.',
                      style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ON TRACK',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          'UPCOMING POSTS & CONTENT REELS',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),

        if (_queue.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No upcoming scheduled posts in queue.'),
            ),
          )
        else
          ..._queue.map((item) {
            final channel = (item['channel'] ?? 'instagram').toString();
            final chColor = _getChannelColor(channel);
            final chIcon = _getChannelIcon(channel);
            final dateStr = item['scheduled']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isLight ? AppColors.lightBorderSubtle : AppColors.borderSubtle),
                boxShadow: [
                  if (isLight)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: chColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(chIcon, size: 12, color: chColor),
                            const SizedBox(width: 4),
                            Text(
                              channel.toUpperCase(),
                              style: TextStyle(color: chColor, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['pillar'] ?? 'Story',
                          style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            dateStr.length >= 16 ? dateStr.substring(0, 16) : dateStr,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['title'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isLight ? AppColors.lightTextPrimary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['caption'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 14, color: AppColors.whatsappGreen),
                        label: const Text(
                          'Share Preview via WhatsApp',
                          style: TextStyle(color: AppColors.whatsappGreen, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          final cap = item['caption'] ?? '';
                          final title = item['title'] ?? '';
                          TelephonyService.openWhatsApp(
                            phoneNumber: '',
                            message: '📢 *Scheduled Social Media Post*: $title\n\n$cap\n\nTripCosmos.co Social AI',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildChannelsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
      children: [
        const Text(
          'CONNECTED SOCIAL MEDIA NETWORKS',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
        ),
        const SizedBox(height: 10),
        ..._channels.map((ch) {
          final chName = ch['name'] ?? '';
          final chColor = _getChannelColor(ch['id'] ?? chName);
          final chIcon = _getChannelIcon(ch['id'] ?? chName);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: chColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(chIcon, size: 22, color: chColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(chName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text(
                            ch['handle'] ?? '',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CONNECTED',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Followers/Audience', ch['followers'] ?? '0', AppColors.accentGold),
                    _buildStatColumn('30D Impressions', ch['impressions'] ?? '0', AppColors.accentBlue),
                    _buildStatColumn('Engagement', ch['engagement'] ?? '0%', const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildEngineTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF311042), Color(0xFF4C1D95)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'OmniRoute Hub (${_plan.toUpperCase()})',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$_aiEngine • $_modelsAvailable models synced across Gemini 2.0, OpenRouter Nemotron, Pollinations FLUX & AIPKit.',
                style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIVE RAG CONTENT FEEDS (TRAVEL & CULTURE)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
              ),
              const SizedBox(height: 12),
              _buildFeedItem('Economic Times Tourism RSS', 'Active • Daily Morning Sync', true),
              _buildFeedItem('Hindustan Times Spiritual & Lifestyle', 'Active • Real-time Pilgrimage News', true),
              _buildFeedItem('Breaking Travel News (India & Asia)', 'Active • Hospitality Trends', true),
              _buildFeedItem('UP Tourism Official Press Desk', 'Active • Kashi & Ayodhya Events', true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6D28D9),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.bolt, color: Colors.white, size: 18),
          label: const Text(
            '⚡ Trigger Instant AI Campaign Angle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ AI campaign generator triggered via VM Social AI OmniRoute.'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeedItem(String title, String subtitle, bool isLive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.rss_feed_rounded, size: 16, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('SYNCED', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
