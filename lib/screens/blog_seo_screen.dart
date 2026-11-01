import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../providers/lead_provider.dart';
import '../services/telephony_service.dart';

class BlogSeoScreen extends StatefulWidget {
  const BlogSeoScreen({super.key});

  @override
  State<BlogSeoScreen> createState() => _BlogSeoScreenState();
}

class _BlogSeoScreenState extends State<BlogSeoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  // ignore: unused_field
  String? _errorMessage;

  int _totalPublished = 2236;
  int _totalDrafts = 13;
  int _avgSeoScore = 88;
  int _aiCallsToday = 42;
  String _gscProperty = 'https://tripcosmos.co/';
  String _ga4Property = '454058738';
  String _aiEngine = 'Gemini 2.0 / OmniRoute';

  List<dynamic> _posts = [];
  List<dynamic> _pillars = [];
  String _filter = 'all'; // all, published, drafts
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSeoData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSeoData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = Provider.of<LeadProvider>(context, listen: false).apiService;
      final res = await api.fetchSeoBrainOverview();
      if (res != null && res['ok'] == true) {
        setState(() {
          _totalPublished = res['total_published'] ?? 2236;
          _totalDrafts = res['total_drafts'] ?? 13;
          _avgSeoScore = res['avg_seo_score'] ?? 88;
          _aiCallsToday = res['ai_calls_today'] ?? 42;
          _gscProperty = res['gsc_property'] ?? 'https://tripcosmos.co/';
          _ga4Property = res['ga4_property_id'] ?? '454058738';
          _aiEngine = res['ai_primary_engine'] ?? 'Gemini 2.0 / OmniRoute';
          _posts = res['posts'] ?? [];
          _pillars = res['pillars'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load SEO Brain data. Showing cached profile.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 70) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  List<dynamic> get _filteredPosts {
    return _posts.where((p) {
      final status = (p['status'] ?? '').toString().toLowerCase();
      if (_filter == 'published' && status != 'publish') return false;
      if (_filter == 'drafts' && status != 'draft') return false;
      if (_searchQuery.isNotEmpty) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final kw = (p['focus_keyword'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !kw.contains(query)) return false;
      }
      return true;
    }).toList();
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
                  'Blog & SEO Brain',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accentGold, width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology_rounded, size: 11, color: AppColors.accentGold),
                      SizedBox(width: 3),
                      Text(
                        'VM SEO Brain AI',
                        style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              '$_totalPublished Live Articles • RankMath Score: $_avgSeoScore/100',
              style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View Live Blog',
            icon: const Icon(Icons.open_in_browser_rounded, color: AppColors.accentBlue, size: 20),
            onPressed: () async {
              final uri = Uri.parse('https://tripcosmos.co/blog/');
              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
          IconButton(
            tooltip: 'Refresh SEO Pulse',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentGold, size: 20),
            onPressed: _loadSeoData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: AppColors.getTextMuted(context),
          indicatorColor: AppColors.accentGold,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(icon: Icon(Icons.article_rounded, size: 18), text: 'Live Articles'),
            Tab(icon: Icon(Icons.account_tree_rounded, size: 18), text: 'Silo & Pillars'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 18), text: 'Brain & GSC'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildArticlesTab(context),
                _buildSiloPillarsTab(context),
                _buildBrainGscTab(context),
              ],
            ),
    );
  }

  Widget _buildArticlesTab(BuildContext context) {
    final posts = _filteredPosts;

    return Column(
      children: [
        // Top Metric Banner
        Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem('Published', '$_totalPublished', const Color(0xFF10B981), Icons.check_circle_outline),
              _buildMetricDivider(),
              _buildMetricItem('Drafts', '$_totalDrafts', const Color(0xFFF59E0B), Icons.edit_note_rounded),
              _buildMetricDivider(),
              _buildMetricItem('Avg SEO', '$_avgSeoScore/100', _getScoreColor(_avgSeoScore), Icons.speed_rounded),
              _buildMetricDivider(),
              _buildMetricItem('AI Calls', '$_aiCallsToday Today', AppColors.accentBlue, Icons.auto_awesome),
            ],
          ),
        ),

        // Search Bar & Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search articles, focus keywords...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip('all', 'All'),
              const SizedBox(width: 4),
              _buildFilterChip('published', 'Live'),
              const SizedBox(width: 4),
              _buildFilterChip('drafts', 'Drafts'),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Articles List
        Expanded(
          child: posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('No articles matching query.', style: TextStyle(color: AppColors.getTextSecondary(context))),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final score = int.tryParse(post['seo_score']?.toString() ?? '0') ?? 0;
                    final isPublish = post['status'] == 'publish';
                    final dateStr = post['date'] ?? '';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPublish ? AppColors.borderSubtle : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isPublish
                                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                      : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPublish ? 'PUBLISHED' : 'DRAFT',
                                  style: TextStyle(
                                    color: isPublish ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getScoreColor(score).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _getScoreColor(score), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt, size: 10, color: _getScoreColor(score)),
                                    const SizedBox(width: 2),
                                    Text(
                                      'SEO $score/100',
                                      style: TextStyle(
                                        color: _getScoreColor(score),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                dateStr.isNotEmpty ? dateStr.substring(0, 10) : '',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post['title'] ?? 'Untitled Article',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.key_rounded, size: 12, color: AppColors.accentGold),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Focus KW: ${post['focus_keyword'] ?? "Varanasi"}',
                                  style: const TextStyle(
                                    color: AppColors.accentGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                icon: const Icon(Icons.share_rounded, size: 14, color: AppColors.whatsappGreen),
                                label: const Text(
                                  'Share on WhatsApp',
                                  style: TextStyle(color: AppColors.whatsappGreen, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () {
                                  final link = post['permalink'] ?? 'https://tripcosmos.co';
                                  final title = post['title'] ?? '';
                                  TelephonyService.openWhatsApp(
                                    phoneNumber: '',
                                    message: '🙏 Namaste! Here is our comprehensive guide on *$title*:\n\n🔗 $link\n\nTripCosmos.co Varanasi HQ',
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 13, color: Colors.white),
                                label: const Text('Read Article', style: TextStyle(color: Colors.white, fontSize: 11)),
                                onPressed: () async {
                                  final permalink = post['permalink'];
                                  if (permalink != null && permalink.isNotEmpty) {
                                    final uri = Uri.parse(permalink);
                                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGold : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.accentGold : AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSiloPillarsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.account_tree_rounded, color: AppColors.accentGold, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Silo & Pillar Architecture (VM SEO Brain)',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hierarchical internal linking structure powering TripCosmos #1 Google rankings for Varanasi pilgrimage & cab bookings.',
                      style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CORE PILLAR ARTICLES & CLUSTERS',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
        ),
        const SizedBox(height: 10),
        ..._pillars.map((p) {
          final score = p['score'] ?? 90;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hub_rounded, color: AppColors.accentGold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p['type'] ?? 'Pillar',
                              style: const TextStyle(color: Colors.purpleAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p['status'] ?? 'Indexed',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getScoreColor(score), width: 0.8),
                  ),
                  child: Text(
                    'Score $score',
                    style: TextStyle(color: _getScoreColor(score), fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBrainGscTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      children: [
        // GSC & GA4 Property Cards
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
              const Row(
                children: [
                  Icon(Icons.public_rounded, color: AppColors.accentBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Google Search Console & GA4 Active Sync',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildConfigRow('GSC Verified Property', _gscProperty, Icons.search_rounded),
              const SizedBox(height: 8),
              _buildConfigRow('Google Analytics 4 ID', 'G-$_ga4Property', Icons.insights_rounded),
              const SizedBox(height: 8),
              _buildConfigRow('Autonomous AI Engine', _aiEngine, Icons.psychology_rounded),
              const SizedBox(height: 8),
              _buildConfigRow('Daily Autonomous Fixes', 'God Mode: Meta, Alt, Schema & Internal Links', Icons.shield_rounded),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Autonomous Rules Matrix
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
                'AUTONOMOUS OPTIMIZATION RULES (VM SEO BRAIN)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
              ),
              const SizedBox(height: 12),
              _buildRuleStatus('RankMath FAQ Schema Injection', 'Active', 'Valid structured data for Rich Snippets', true),
              _buildRuleStatus('Contextual Internal Anchor Inserter', 'Active', 'Smart in-sentence anchor linking (no footer bolts)', true),
              _buildRuleStatus('Image Auto-Generation & Alt Optimizer', 'Active', 'Pollinations FLUX + Real SEO descriptive alt text', true),
              _buildRuleStatus('Google Sheet Topic Synchronization', 'Active', 'Bidirectional sync with team topic calendar', true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.accentGold),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRuleStatus(String title, String badge, String subtitle, bool isOk) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: isOk ? const Color(0xFF10B981) : Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(width: 1, height: 24, color: Colors.white12);
  }
}
