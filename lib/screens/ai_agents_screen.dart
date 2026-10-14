import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/ai_agent_model.dart';
import '../providers/ai_agent_provider.dart';
import '../providers/lead_provider.dart';
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

  void _showTrainingCatalogDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppColors.accentGold, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Agent Knowledge Base',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tour Packages, Pricing Rules & Fleet Tariffs',
                        style: TextStyle(color: Colors.white54, fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '🎪 TRAINED TOUR CIRCUITS & PACKAGES',
              style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            _buildPackageItem(
              'Varanasi (Kashi) 3D/2N Complete Pilgrimage',
              '₹14,500 Retail • ₹12,200 B2B DMC Net',
              'Includes: Kashi Vishwanath Sugam Pass (no lines), Subah-e-Banaras sunrise boat, Dashashwamedh evening Aarti Bajra seat, Sarnath, Kaal Bhairav, AC Sedan & Deluxe Ghat hotel.',
            ),
            _buildPackageItem(
              'Ayodhya Ram Janmabhoomi 2D/1N Sacred Tour',
              '₹9,800 Retail • ₹8,100 B2B DMC Net',
              'Includes: Ram Mandir VIP pass, Hanumangarhi, Kanak Bhavan, Saryu Maha Aarti, Surya Kund Light show, AC cab transfer & 3-Star hotel stay.',
            ),
            _buildPackageItem(
              'Kashi - Ayodhya - Prayagraj 4D/3N Golden Circuit',
              '₹22,500 Retail • ₹18,900 B2B DMC Net',
              'Includes: All 3 holy cities, dedicated Toyota Innova Crysta, Sugam Darshan passes, Sangam holy dip boat, Deluxe hotels with breakfast.',
            ),
            _buildPackageItem(
              'Prayagraj Triveni Sangam 1-Day Excursion',
              '₹4,800 Retail • ₹3,900 B2B DMC Net',
              'Includes: Private AC cab from Varanasi (round-trip), Triveni Sangam boat, Bade Hanuman Ji temple, Alopi Devi, all toll & parking.',
            ),
            _buildPackageItem(
              'Bodhgaya & Gaya 2D/1N Enlightenment Tour',
              '₹13,200 Retail • ₹11,000 B2B DMC Net',
              'Includes: Mahabodhi Temple UNESCO site, 80ft Buddha statue, Vishnupad temple Pind Daan assistance, AC cab & hotel stay.',
            ),
            const SizedBox(height: 16),
            const Text(
              '🚗 DYNAMIC FLEET & OUTSTATION TARIFFS',
              style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            _buildTariffRow('Swift Dzire / Etios AC (1-4 Pax)', '₹11 / km', 'Airport: ₹950 • City 8h: ₹2,200'),
            _buildTariffRow('Maruti Ertiga (4-6 Pax)', '₹14 / km', 'Airport: ₹1,400 • City 8h: ₹2,800'),
            _buildTariffRow('Toyota Innova Crysta (4-7 Pax)', '₹17 / km', 'Airport: ₹1,800 • City 8h: ₹3,600'),
            _buildTariffRow('Tempo Traveller (12-26 Seater)', '₹24 / km', 'Airport: ₹2,800 • City 8h: ₹5,200'),
            const SizedBox(height: 16),
            const Text(
              '🛡️ MARGINS & ESCALATION GUARDRAILS',
              style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• B2C Target Margin: 18% - 22% built into quotes', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('• B2B Wholesale Net Margin: Protected 10% agency discount', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('• Max Autonomous Discount: 10% (requires human escalation above 10%)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('• Human Escalation: Instantly triggers notification when customer asks for manager', style: TextStyle(color: AppColors.accentGold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPackageItem(String title, String pricing, String details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              Text(pricing, style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w700, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(details, style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3)),
        ],
      ),
    );
  }

  static Widget _buildTariffRow(String vehicle, String perKm, String extras) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(extras, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Text(perKm, style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
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
    final humanAgent = context.watch<LeadProvider>().currentAgent;
    final pairedAiName = 'Aditi AI';

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
              // 0. Human + AI Co-Pilot Team Duo Card
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.handshake_rounded, size: 13, color: AppColors.accentGold),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'HUMAN + AI DUO',
                                    style: TextStyle(
                                      color: AppColors.accentGold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: AppColors.successGreen, size: 7),
                              SizedBox(width: 4),
                              Text(
                                'Active Co-Pilot',
                                style: TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Human Specialist Avatar
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: const Color(0xFF334155),
                          child: Text(
                            humanAgent.isNotEmpty ? humanAgent.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join() : 'SY',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                humanAgent.isNotEmpty ? humanAgent : 'Santosh Yadav',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Human Rep',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.compare_arrows_rounded, color: AppColors.accentGold, size: 20),
                        ),
                        // AI Agent Avatar
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accentGold, width: 1.5),
                          ),
                          child: const CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.accentGold,
                            child: Icon(Icons.smart_toy_rounded, color: Colors.black, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pairedAiName,
                                style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'AI Co-Pilot',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, color: Colors.white60, size: 14),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Trained on: Varanasi 3D/2N, Ayodhya, Sangam, Bodhgaya & Fleet Rates',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => _showTrainingCatalogDialog(context),
                          child: const Text(
                            'View Training ›',
                            style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
