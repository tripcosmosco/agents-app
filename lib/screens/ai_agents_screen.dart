import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/ai_agent_model.dart';
import '../providers/ai_agent_provider.dart';
import '../widgets/glass_card.dart';

class AiAgentsScreen extends StatefulWidget {
  const AiAgentsScreen({super.key});

  @override
  State<AiAgentsScreen> createState() => _AiAgentsScreenState();
}

class _AiAgentsScreenState extends State<AiAgentsScreen> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendQuestion(AiAgentProvider provider) {
    final text = _chatController.text.trim();
    if (text.isNotEmpty) {
      provider.testRagQuery(text);
      _chatController.clear();
    }
  }

  void _openCreateOrEditPersonaSheet(BuildContext context, AiAgentProvider provider, [AiAgentPersona? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final toneCtrl = TextEditingController(text: existing?.tone ?? 'Devotional, Respectful & Prompt (Bilingual)');
    final voiceCtrl = TextEditingController(text: existing?.voiceName ?? 'Aarav (Warm Hindi/English)');
    final circuitsCtrl = TextEditingController(text: existing?.circuits.join(', ') ?? 'Varanasi, Ayodhya, Prayagraj');
    final promptCtrl = TextEditingController(
      text: existing?.systemPrompt ??
          'You are an expert travel sales specialist at TripCosmos.co. Assist travelers with authentic itinerary advice, transparent pricing, and courteous hospitality.',
    );

    bool canWa = existing?.canChatWhatsapp ?? true;
    bool canVoice = existing?.canMakeVoiceCalls ?? true;
    bool canInbound = existing?.canTakeInbound ?? true;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: AppColors.accentGold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existing == null ? 'Create AI Sales Persona' : 'Edit Persona: ${existing.name}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          'Configure autonomous travel skills, tone & voice',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Agent Name',
                    hintText: 'e.g. Aarav Sharma',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Designation / Department',
                    hintText: 'e.g. Kashi Pilgrimage & VIP Desk Specialist',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: circuitsCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Specialist Tour Circuits (comma separated)',
                    hintText: 'Varanasi, Ayodhya, Prayagraj, Bodh Gaya',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: toneCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tone & Persona Style',
                    hintText: 'Devotional & Respectful / Fast B2B Commercial',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: promptCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Agent System Instructions (Prompt)',
                    hintText: 'Define knowledge, greeting style, discount limits, and rules...',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AUTONOMOUS EXECUTION CHANNELS',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Official WhatsApp Auto-Chat', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('Answers inbound WhatsApp leads autonomously', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  value: canWa,
                  activeTrackColor: AppColors.whatsappGreen,
                  onChanged: (val) => setSheetState(() => canWa = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Autonomous Voice Calling', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('Makes outbound follow-up calls via GSM/LiveKit bridge', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  value: canVoice,
                  activeTrackColor: AppColors.accentBlue,
                  onChanged: (val) => setSheetState(() => canVoice = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('24/7 Inbound Telephony Receptionist', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('Picks up traveler calls and answers inquiries', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  value: canInbound,
                  activeTrackColor: AppColors.accentGold,
                  onChanged: (val) => setSheetState(() => canInbound = val),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final circuits = circuitsCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final persona = (existing ?? AiAgentPersona(
                        id: 'agent_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim(),
                        title: titleCtrl.text.trim(),
                        voiceName: voiceCtrl.text.trim(),
                        tone: toneCtrl.text.trim(),
                        circuits: circuits,
                        canChatWhatsapp: canWa,
                        canMakeVoiceCalls: canVoice,
                        canTakeInbound: canInbound,
                        systemPrompt: promptCtrl.text.trim(),
                        skills: const [
                          AgentSkill(
                            id: 'skill_vip_darshan',
                            name: 'VIP Sugam Darshan Guidance',
                            description: 'Pass quotas and temple timings',
                            category: 'darshan',
                            isEnabled: true,
                          ),
                          AgentSkill(
                            id: 'skill_itinerary_customizer',
                            name: 'Dynamic Tour Quote & Itinerary',
                            description: 'Generates pricing and day-wise plans',
                            category: 'sales',
                            isEnabled: true,
                          ),
                        ],
                      )).copyWith(
                        name: nameCtrl.text.trim(),
                        title: titleCtrl.text.trim(),
                        circuits: circuits,
                        tone: toneCtrl.text.trim(),
                        voiceName: voiceCtrl.text.trim(),
                        systemPrompt: promptCtrl.text.trim(),
                        canChatWhatsapp: canWa,
                        canMakeVoiceCalls: canVoice,
                        canTakeInbound: canInbound,
                      );

                      if (existing == null) {
                        provider.addPersona(persona);
                      } else {
                        provider.updatePersona(persona);
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ AI Agent ${persona.name} saved!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    },
                    child: Text(
                      existing == null ? 'Deploy AI Agent to Team' : 'Update AI Agent',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AiAgentProvider>(context);
    final selectedPersona = aiProvider.selectedPersona;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Sales Team Command Center',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Multi-Agent Personas • Custom Skills • WhatsApp & Spoken Voice AI',
              style: TextStyle(fontSize: 11, color: AppColors.accentGold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Deploy New AI Agent',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.accentGold),
            onPressed: () => _openCreateOrEditPersonaSheet(context, aiProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Team Persona Carousel
              Row(
                children: [
                  const Text(
                    'AI SALES AGENT PERSONAS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${aiProvider.personas.length} Active Digital Reps',
                    style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: aiProvider.personas.length + 1,
                  itemBuilder: (context, index) {
                    if (index == aiProvider.personas.length) {
                      return InkWell(
                        onTap: () => _openCreateOrEditPersonaSheet(context, aiProvider),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withValues(alpha: 0.03),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, color: AppColors.accentGold, size: 30),
                              SizedBox(height: 8),
                              Text(
                                'Add AI Agent',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Custom Skills',
                                style: TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final p = aiProvider.personas[index];
                    final isSelected = p.id == aiProvider.selectedPersonaId;

                    return InkWell(
                      onTap: () => aiProvider.selectPersona(p.id),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.surfaceCard
                              : const Color(0xFF1E293B).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.accentGold : Colors.white12,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.accentGold.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSelected ? AppColors.accentGold : Colors.white24,
                                  child: Text(
                                    p.name.substring(0, 1),
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        p.circuits.firstOrNull ?? 'Spiritual Desk',
                                        style: const TextStyle(
                                          color: AppColors.accentGold,
                                          fontSize: 10,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              p.title,
                              style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (p.canChatWhatsapp)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.chat_bubble_rounded, size: 12, color: AppColors.whatsappGreen),
                                  ),
                                if (p.canMakeVoiceCalls)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.phone_in_talk_rounded, size: 12, color: AppColors.accentBlue),
                                  ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${p.skills.where((s) => s.isEnabled).length} Skills',
                                    style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 2. Selected Persona Profile & Skills Inspector Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.accentGold,
                          child: Text(
                            selectedPersona.name.substring(0, 1),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    selectedPersona.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'ONLINE • READY',
                                      style: TextStyle(color: AppColors.successGreen, fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                selectedPersona.title,
                                style: const TextStyle(color: AppColors.accentGold, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tone: ${selectedPersona.tone} • Voice: ${selectedPersona.voiceName}',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit Persona Settings',
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.white70),
                          onPressed: () => _openCreateOrEditPersonaSheet(context, aiProvider, selectedPersona),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 14),

                    // Metrics Row
                    Row(
                      children: [
                        _buildMetricPill('Conversations', '${selectedPersona.conversationsCount}', Icons.chat_rounded),
                        const SizedBox(width: 10),
                        _buildMetricPill('Deals Closed', '${selectedPersona.dealsClosed}', Icons.verified_rounded),
                        const SizedBox(width: 10),
                        _buildMetricPill('Win Rate', '${selectedPersona.conversionRate.toStringAsFixed(1)}%', Icons.trending_up_rounded),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Skills Matrix Switchboard
                    Row(
                      children: [
                        const Text(
                          'CONFIGURED TRAVEL AGENT SKILLS',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${selectedPersona.skills.where((s) => s.isEnabled).length}/${selectedPersona.skills.length} Enabled',
                          style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedPersona.skills.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final skill = selectedPersona.skills[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: skill.isEnabled ? AppColors.accentGold.withValues(alpha: 0.3) : Colors.white10,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getSkillIcon(skill.category),
                                color: skill.isEnabled ? AppColors.accentGold : Colors.white38,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      skill.name,
                                      style: TextStyle(
                                        color: skill.isEnabled ? Colors.white : Colors.white54,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      skill.description,
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: skill.isEnabled,
                                activeTrackColor: AppColors.accentGold,
                                onChanged: (val) {
                                  aiProvider.toggleSkill(selectedPersona.id, skill.id, val);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Live AI Voice & Chat Playground
              Row(
                children: [
                  Text(
                    'PLAYGROUND: TEST ${selectedPersona.name.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => aiProvider.clearPlayground(),
                    icon: const Icon(Icons.refresh, size: 14, color: AppColors.textMuted),
                    label: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: aiProvider.playgroundMessages.length,
                        itemBuilder: (context, index) {
                          final msg = aiProvider.playgroundMessages[index];
                          return _buildChatBubble(msg);
                        },
                      ),
                    ),

                    if (aiProvider.isQueryingRag) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${selectedPersona.name} formulating response using active skills...',
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Ask ${selectedPersona.name} (e.g. 3-day Kashi package for 4 adults)...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _sendQuestion(aiProvider),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _sendQuestion(aiProvider),
                          icon: const Icon(Icons.send_rounded, color: AppColors.accentGold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: AppColors.accentGold),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSkillIcon(String category) {
    switch (category) {
      case 'darshan':
        return Icons.temple_hindu_rounded;
      case 'pricing':
        return Icons.currency_rupee_rounded;
      case 'logistics':
        return Icons.local_taxi_rounded;
      case 'guardrail':
        return Icons.shield_rounded;
      case 'sales':
      default:
        return Icons.travel_explore_rounded;
    }
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.accentBlue.withValues(alpha: 0.8)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: msg.isUser ? Colors.transparent : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser && msg.provider != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  msg.provider!,
                  style: const TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
