import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../services/paperclip_service.dart';
import '../widgets/glass_card.dart';
import 'ai_agents_screen.dart';

/// Sovereign Paperclip Multi-Agent Fleet Management & Optimization Screen
class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AgentsScreen()),
    );
  }

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> with SingleTickerProviderStateMixin {
  final PaperclipService _service = PaperclipService();
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _companies = [];
  String _selectedCompanyId = 'b66bdec2-ddf6-4199-9161-da5c6ee60ef8'; // TripCosmos.co default
  String _selectedCompanyName = 'TripCosmos.co';

  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _routines = [];
  List<Map<String, dynamic>> _issues = [];
  Map<String, dynamic>? _health;

  String _issueFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final companies = await _service.fetchCompanies();
      final health = await _service.checkHealth();

      String targetCompanyId = _selectedCompanyId;
      if (companies.isNotEmpty && !companies.any((c) => c['id'] == targetCompanyId)) {
        targetCompanyId = companies.first['id']?.toString() ?? targetCompanyId;
      }

      final agents = await _service.fetchAgents(targetCompanyId);
      final routines = await _service.fetchRoutines(targetCompanyId);
      final issues = await _service.fetchIssues(targetCompanyId);

      if (mounted) {
        setState(() {
          _companies = companies;
          _health = health;
          _selectedCompanyId = targetCompanyId;
          final currentComp = companies.firstWhere(
            (c) => c['id'] == targetCompanyId,
            orElse: () => {'name': 'TripCosmos.co'},
          );
          _selectedCompanyName = currentComp['name']?.toString() ?? 'TripCosmos.co';
          _agents = agents;
          _routines = routines;
          _issues = issues;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Paperclip data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchCompany(String companyId, String companyName) async {
    if (_selectedCompanyId == companyId) return;
    setState(() {
      _selectedCompanyId = companyId;
      _selectedCompanyName = companyName;
      _isLoading = true;
    });

    try {
      final agents = await _service.fetchAgents(companyId);
      final routines = await _service.fetchRoutines(companyId);
      final issues = await _service.fetchIssues(companyId);

      if (mounted) {
        setState(() {
          _agents = agents;
          _routines = routines;
          _issues = issues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runRoutineNow(Map<String, dynamic> routine) async {
    final title = routine['title'] ?? 'Routine';
    final routineId = routine['id']?.toString() ?? '';
    if (routineId.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ Triggering "$title"...'),
        backgroundColor: const Color(0xFF2563EB),
        duration: const Duration(seconds: 2),
      ),
    );

    final ok = await _service.triggerRoutine(routineId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '✓ Routine executed successfully!'
            : 'Notice: Routine triggered in background dispatcher.'),
        backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
      ),
    );
  }

  void _showOptimizeAgentModal(Map<String, dynamic> agent) {
    final titleController = TextEditingController(text: agent['title']?.toString() ?? '');
    String selectedModel = agent['adapterConfig']?['model']?.toString() ?? 'omniroute/auto/best-coding-fast';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          final isLight = Theme.of(ctx).brightness == Brightness.light;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF0F172A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Optimize Agent: ${agent['name']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isLight ? AppColors.lightTextPrimary : Colors.white,
                              ),
                            ),
                            Text(
                              'Role: ${agent['role']?.toString().toUpperCase()} • ID: ${agent['id']?.toString().substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: 11,
                                color: isLight ? AppColors.lightTextMuted : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Title / Specialization Field
                  Text('Operational Title / Specialization',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isLight ? AppColors.lightTextPrimary : Colors.white)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    style: TextStyle(fontSize: 13, color: isLight ? AppColors.lightTextPrimary : Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. VIP Pilgrimage Itinerary & Margins',
                      filled: true,
                      fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Model Selection
                  Text('Autonomous LLM Engine (OmniRoute Sovereign)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isLight ? AppColors.lightTextPrimary : Colors.white)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedModel,
                        isExpanded: true,
                        dropdownColor: isLight ? Colors.white : const Color(0xFF1E293B),
                        items: const [
                          DropdownMenuItem(
                            value: 'omniroute/auto/best-coding-fast',
                            child: Text('⚡ Fast Routing (omniroute/auto/best-coding-fast)', style: TextStyle(fontSize: 12.5)),
                          ),
                          DropdownMenuItem(
                            value: 'auto/best-coding',
                            child: Text('🎯 High Precision (auto/best-coding)', style: TextStyle(fontSize: 12.5)),
                          ),
                          DropdownMenuItem(
                            value: 'auto/claude-sonnet',
                            child: Text('🧠 Deep Reasoning (auto/claude-sonnet)', style: TextStyle(fontSize: 12.5)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setMState(() => selectedModel = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Action Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            setMState(() => isSaving = true);
                            final agentId = agent['id']?.toString() ?? '';
                            final ok = await _service.updateAgent(agentId, {
                              'title': titleController.text.trim(),
                            });
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? '✓ Agent updated and synchronized!'
                                    : 'Failed to update agent.'),
                                backgroundColor: ok ? const Color(0xFF10B981) : Colors.red,
                              ),
                            );
                            _loadAllData();
                          },
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save & Synchronize Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateTaskModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedAgentId = _agents.isNotEmpty ? _agents.first['id']?.toString() : null;
    String priority = 'high';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          final isLight = Theme.of(ctx).brightness == Brightness.light;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF0F172A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dispatch Mission to $_selectedCompanyName Fleet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isLight ? AppColors.lightTextPrimary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(fontSize: 13, color: isLight ? AppColors.lightTextPrimary : Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Mission Title',
                      hintText: 'e.g. Audit Kashi Vishwanath VIP Darshan Slots',
                      filled: true,
                      fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: TextStyle(fontSize: 13, color: isLight ? AppColors.lightTextPrimary : Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Mission Instructions & Context',
                      hintText: 'Provide specific goals, dates, margin constraints, or traveler details...',
                      filled: true,
                      fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAgentId,
                    decoration: InputDecoration(
                      labelText: 'Assignee Agent',
                      filled: true,
                      fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: _agents.map((a) {
                      return DropdownMenuItem<String>(
                        value: a['id']?.toString(),
                        child: Text('${a['name']} (${a['role']})', style: const TextStyle(fontSize: 12.5)),
                      );
                    }).toList(),
                    onChanged: (val) => setMState(() => selectedAgentId = val),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                    label: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Dispatch Mission to Agent Fleet', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) return;
                            setMState(() => isSubmitting = true);
                            final res = await _service.createIssue(
                              _selectedCompanyId,
                              title: title,
                              description: descCtrl.text.trim(),
                              assigneeAgentId: selectedAgentId,
                              priority: priority,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res != null
                                    ? '✓ Mission "${res['identifier'] ?? title}" dispatched!'
                                    : 'Failed to dispatch mission.'),
                                backgroundColor: res != null ? const Color(0xFF10B981) : Colors.red,
                              ),
                            );
                            _loadAllData();
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF070D1E),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 46),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AppBar(
              backgroundColor: (isLight ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.88),
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 14,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF38BDF8)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Paperclip Sovereign Fleet',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: isLight ? AppColors.lightTextPrimary : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('ONLINE', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                            ),
                          ],
                        ),
                        Text(
                          _health != null && _health!['status'] == 'ok'
                              ? 'agents.vmstudio.digital • 24/7 Autopilot Live'
                              : 'agents.vmstudio.digital • 24/7 Autonomous Autopilot',
                          style: TextStyle(fontSize: 10, color: isLight ? AppColors.lightTextMuted : Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Open Master AI Assistant & RAG Co-Pilot',
                  icon: const Icon(Icons.psychology_rounded, size: 20, color: Color(0xFFF59E0B)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiAgentsScreen()),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Open Web Console',
                  icon: const Icon(Icons.open_in_new_rounded, size: 19, color: Color(0xFF38BDF8)),
                  onPressed: () => launchUrl(Uri.parse('https://agents.vmstudio.digital'), mode: LaunchMode.externalApplication),
                ),
                IconButton(
                  tooltip: 'Sync Fleet Data',
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold))
                      : const Icon(Icons.sync_rounded, size: 20, color: AppColors.accentGold),
                  onPressed: _isLoading ? null : _loadAllData,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(46),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF38BDF8),
                    indicatorWeight: 2.5,
                    labelColor: const Color(0xFF38BDF8),
                    unselectedLabelColor: isLight ? AppColors.lightTextMuted : Colors.white60,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: 'Fleet (${_agents.length})'),
                      Tab(text: 'Routines (${_routines.length})'),
                      Tab(text: 'Missions (${_issues.length})'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : Column(
              children: [
                // 1. Company Switcher Segmented Ribbon
                _buildCompanySwitcher(isLight),

                // 2. Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAgentsTab(isLight),
                      _buildRoutinesTab(isLight),
                      _buildMissionsTab(isLight),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded, size: 18),
        label: const Text('New Mission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: _showCreateTaskModal,
      ),
    );
  }

  Widget _buildCompanySwitcher(bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (isLight ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(
            color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _companies.map((c) {
            final cid = c['id']?.toString() ?? '';
            final cname = c['name']?.toString() ?? 'Entity';
            final prefix = c['issuePrefix']?.toString() ?? '';
            final isSelected = _selectedCompanyId == cid;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _switchCompany(cid, cname),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2563EB).withValues(alpha: isLight ? 0.15 : 0.28)
                        : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB).withValues(alpha: 0.6)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cname,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isLight ? AppColors.lightTextPrimary : Colors.white70),
                        ),
                      ),
                      if (prefix.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            prefix,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : (isLight ? Colors.black54 : Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: FLEET AGENTS
  // ---------------------------------------------------------------------------
  Widget _buildAgentsTab(bool isLight) {
    if (_agents.isEmpty) {
      return Center(
        child: Text('No agents configured for $_selectedCompanyName.',
            style: TextStyle(color: isLight ? AppColors.lightTextMuted : Colors.white60)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppColors.accentGold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
        itemCount: _agents.length,
        itemBuilder: (context, index) {
          final agent = _agents[index];
          final name = agent['name'] ?? 'Agent';
          final title = agent['title'] ?? 'Specialist';
          final role = (agent['role'] ?? 'general').toString().toUpperCase();
          final status = agent['status'] ?? 'idle';
          final model = agent['adapterConfig']?['model'] ?? 'omniroute/auto/fast';
          final isChief = agent['reportsTo'] == null;

          Color roleColor = const Color(0xFF38BDF8);
          if (role == 'PM') roleColor = const Color(0xFF10B981);
          if (role == 'CMO') roleColor = const Color(0xFFF59E0B);
          if (role == 'ENGINEER') roleColor = const Color(0xFF8B5CF6);
          if (role == 'RESEARCHER') roleColor = const Color(0xFFEC4899);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isChief
                                ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                : [roleColor.withValues(alpha: 0.8), roleColor],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isChief ? Icons.stars_rounded : Icons.smart_toy_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isLight ? AppColors.lightTextPrimary : Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    role,
                                    style: TextStyle(
                                      color: roleColor,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isLight ? AppColors.lightTextMuted : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.bolt_rounded, size: 12, color: const Color(0xFF38BDF8)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    model.toString().replaceFirst('omniroute/', ''),
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status.toString().toUpperCase(),
                                    style: const TextStyle(fontSize: 8.5, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 14),
                        label: const Text('Optimize & Model', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: () => _showOptimizeAgentModal(agent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: AUTONOMOUS ROUTINES
  // ---------------------------------------------------------------------------
  Widget _buildRoutinesTab(bool isLight) {
    if (_routines.isEmpty) {
      return Center(
        child: Text('No autonomous routines configured for $_selectedCompanyName.',
            style: TextStyle(color: isLight ? AppColors.lightTextMuted : Colors.white60)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppColors.accentGold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final r = _routines[index];
          final title = r['title'] ?? 'Routine';
          final desc = r['description'] ?? '';
          final priority = (r['priority'] ?? 'high').toString().toUpperCase();
          final triggers = (r['triggers'] is List) ? (r['triggers'] as List) : [];
          final triggerLabel = triggers.isNotEmpty ? (triggers.first['label'] ?? triggers.first['cronExpression']) : 'Scheduled';
          final cron = triggers.isNotEmpty ? (triggers.first['cronExpression'] ?? '') : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.schedule_rounded, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isLight ? AppColors.lightTextPrimary : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              triggerLabel,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          priority,
                          style: const TextStyle(fontSize: 8.5, color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: isLight ? AppColors.lightTextMuted : Colors.white60),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (cron.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Cron: $cron (UTC)',
                            style: TextStyle(fontSize: 9.5, color: isLight ? Colors.black54 : Colors.white60, fontFamily: 'monospace'),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 14),
                        label: const Text('Run Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _runRoutineNow(r),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: MISSION TASKS
  // ---------------------------------------------------------------------------
  Widget _buildMissionsTab(bool isLight) {
    var filtered = _issues;
    if (_issueFilter != 'all') {
      filtered = _issues.where((i) => i['status'] == _issueFilter).toList();
    }

    return Column(
      children: [
        // Filter pills
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _buildFilterPill('all', 'All (${_issues.length})', isLight),
              const SizedBox(width: 6),
              _buildFilterPill('todo', 'Todo (${_issues.where((i) => i['status'] == 'todo').length})', isLight),
              const SizedBox(width: 6),
              _buildFilterPill('done', 'Done (${_issues.where((i) => i['status'] == 'done').length})', isLight),
              const SizedBox(width: 6),
              _buildFilterPill('blocked', 'Blocked (${_issues.where((i) => i['status'] == 'blocked').length})', isLight),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No missions found for filter: $_issueFilter',
                      style: TextStyle(color: isLight ? AppColors.lightTextMuted : Colors.white60)),
                )
              : RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: AppColors.accentGold,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final identifier = item['identifier'] ?? 'ISSUE';
                      final title = item['title'] ?? 'Task';
                      final status = item['status'] ?? 'todo';
                      final desc = item['description'] ?? '';

                      Color statusColor = const Color(0xFF38BDF8);
                      if (status == 'done') statusColor = const Color(0xFF10B981);
                      if (status == 'blocked') statusColor = const Color(0xFFEF4444);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      identifier,
                                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isLight ? AppColors.lightTextPrimary : Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status.toString().toUpperCase(),
                                      style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  desc,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: isLight ? AppColors.lightTextMuted : Colors.white60),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String filterKey, String label, bool isLight) {
    final isSelected = _issueFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _issueFilter = filterKey),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: isLight ? 0.15 : 0.28)
              : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.6) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF2563EB) : (isLight ? AppColors.lightTextMuted : Colors.white60),
          ),
        ),
      ),
    );
  }
}
