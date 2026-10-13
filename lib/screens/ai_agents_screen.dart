import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/ai_agent_provider.dart';
import '../providers/call_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AiAgentProvider>(context);
    final callProvider = Provider.of<CallProvider>(context);
    final leadProvider = Provider.of<LeadProvider>(context);

    final autoCallsCount = callProvider.callLogs.length;
    final qualifiedLeadsCount = leadProvider.leads.where((l) => ['qualified', 'quote_sent', 'advance_received', 'won'].contains(l.stage.toLowerCase())).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Agents Command Center',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Powered by Local AI Puffer RAG Bot 155464 (₹0 Telephony)',
              style: TextStyle(fontSize: 11, color: AppColors.accentGold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. AI Outbound Sales Agent Card
              _buildOutboundAgentCard(aiProvider, autoCallsCount, qualifiedLeadsCount),
              const SizedBox(height: 14),

              // 2. 24x7 AI Voice Receptionist Card
              _buildReceptionistCard(aiProvider),
              const SizedBox(height: 20),

              // 3. Live AI Voice Playground
              Row(
                children: [
                  const Text(
                    'LIVE AI VOICE & RAG PLAYGROUND',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => aiProvider.clearPlayground(),
                    icon: const Icon(
                      Icons.refresh,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    label: const Text(
                      'Reset',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Playground Card
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    // Chat Messages Stream
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentGold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'AI Puffer Bot 155464 generating 2-sentence response...',
                              style: TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: 10),

                    // Quick Prompt Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickPrompt(
                            aiProvider,
                            'Ganga Aarti timings at Dashashwamedh?',
                          ),
                          const SizedBox(width: 6),
                          _buildQuickPrompt(
                            aiProvider,
                            'Varanasi to Ayodhya Innova fare?',
                          ),
                          const SizedBox(width: 6),
                          _buildQuickPrompt(
                            aiProvider,
                            'How to get VIP Sugam Darshan?',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Input Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            onSubmitted: (_) => _sendQuestion(aiProvider),
                            decoration: const InputDecoration(
                              hintText: 'Test speak question (e.g. cab fare, darshan)...',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _sendQuestion(aiProvider),
                          icon: const Icon(
                            Icons.send_rounded,
                            color: AppColors.accentGold,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceElevated,
                            padding: const EdgeInsets.all(12),
                          ),
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

  Widget _buildOutboundAgentCard(AiAgentProvider provider, int autoCalls, int qualifiedLeads) {
    return GlassCard(
      borderColor: provider.isOutboundAgentActive
          ? AppColors.accentGold.withValues(alpha: 0.5)
          : AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_in_talk,
                  color: AppColors.accentGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Outbound Sales Agent',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Auto-dials website & ad leads via Jio SIM for ₹0',
                      style: TextStyle(
                        fontSize: 12,
                        color: provider.isOutboundAgentActive
                            ? AppColors.successGreen
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.isOutboundAgentActive,
                onChanged: (val) => provider.toggleOutboundAgent(val),
                activeThumbColor: AppColors.accentGold,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '$autoCalls',
                'Calls Logged',
              ),
              _buildStatItem(
                '$qualifiedLeads',
                'Leads Qualified',
              ),
              _buildStatItem('₹0.00', 'Telephony Bill'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceptionistCard(AiAgentProvider provider) {
    return GlassCard(
      borderColor: provider.isReceptionistActive
          ? AppColors.successGreen.withValues(alpha: 0.5)
          : AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: AppColors.successGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '24x7 AI Voice Receptionist',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Answers inbound calls using TripCosmos RAG Brain',
                      style: TextStyle(
                        fontSize: 12,
                        color: provider.isReceptionistActive
                            ? AppColors.successGreen
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.isReceptionistActive,
                onChanged: (val) => provider.toggleReceptionist(val),
                activeThumbColor: AppColors.successGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: AppColors.accentGold, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connected: Bot 155464 ("TripCosmos AI") • Concise 2-sentence sales protocol',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildQuickPrompt(AiAgentProvider provider, String text) {
    return InkWell(
      onTap: () => provider.testRagQuery(text),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: msg.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.accentGold,
              child: Icon(
                Icons.smart_toy,
                size: 14,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? AppColors.accentGold
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: msg.isUser
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: msg.isUser ? FontWeight.w600 : FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
