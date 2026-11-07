import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/ai_agent_provider.dart';
import 'glass_card.dart';
import 'voice_copilot_sheet.dart';

class MasterAiAssistantView extends StatefulWidget {
  final bool isBottomSheet;
  final VoidCallback? onClose;

  const MasterAiAssistantView({
    super.key,
    this.isBottomSheet = false,
    this.onClose,
  });

  @override
  State<MasterAiAssistantView> createState() => _MasterAiAssistantViewState();
}

class _MasterAiAssistantViewState extends State<MasterAiAssistantView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickActionPrompts = const [
    '🌅 Daily Operations Briefing',
    '🔥 Show hot leads needing immediate callback',
    '💰 What is our staff payroll and financial status?',
    '🚗 Calculate cab tariffs for Kashi to Ayodhya',
    '🤝 Overview of our wholesale B2B travel partners',
    '✍️ Draft high-conversion WhatsApp follow-up quote',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(AiAgentProvider provider, [String? overrideText]) {
    final text = overrideText ?? _inputController.text.trim();
    if (text.isNotEmpty) {
      if (overrideText == null) {
        _inputController.clear();
      }
      provider.sendMasterAiQuery(text);
      _scrollToBottom();
    }
  }

  void _showVoiceCommandModal(BuildContext context, AiAgentProvider provider) {
    VoiceCopilotSheet.show(context, apiService: provider.apiService);
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AiAgentProvider>(context);
    final messages = aiProvider.masterAssistantMessages;
    final isQuerying = aiProvider.isQueryingMasterAi;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: widget.isBottomSheet ? const BorderRadius.vertical(top: Radius.circular(24)) : null,
      ),
      child: Column(
        children: [
          // 1. Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.getElevated(context),
              border: Border(bottom: BorderSide(color: AppColors.getBorder(context))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Garuda Master AI',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextPrimary(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: Colors.green, size: 6),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE OPS',
                                  style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chief Operations, Sales & Intelligence Co-Pilot',
                        style: TextStyle(fontSize: 10.5, color: AppColors.getTextSecondary(context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 1-Click Briefing Button
                IconButton(
                  icon: const Icon(Icons.wb_sunny_rounded, color: AppColors.accentGold, size: 20),
                  tooltip: 'Morning Operations Briefing',
                  onPressed: isQuerying
                      ? null
                      : () {
                          aiProvider.requestMasterBriefing();
                          _scrollToBottom();
                        },
                ),
                // Clear History Button
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  tooltip: 'Reset Conversation',
                  onPressed: () => aiProvider.clearMasterAssistant(),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),

          // 2. Quick Action Chips Carousel
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              border: Border(bottom: BorderSide(color: AppColors.getBorder(context).withValues(alpha: 0.5))),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickActionPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final prompt = _quickActionPrompts[i];
                return ActionChip(
                  backgroundColor: AppColors.getElevated(context),
                  side: BorderSide(color: AppColors.getBorder(context)),
                  label: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  onPressed: isQuerying ? null : () => _handleSend(aiProvider, prompt),
                );
              },
            ),
          ),

          // 3. Conversation Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isQuerying ? 1 : 0),
              itemBuilder: (ctx, idx) {
                if (idx == messages.length) {
                  // Thinking indicator
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.getElevated(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Garuda Master AI is analyzing operations...',
                                  style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context), fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final msg = messages[idx];
                final isUser = msg.isUser;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      child: isUser
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2E2A1C), Color(0xFF1E1E1E)],
                                ),
                                borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(0)),
                                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                msg.text,
                                style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                              ),
                            )
                          : GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // AI Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accentGold),
                                            const SizedBox(width: 4),
                                            Text(
                                              msg.provider ?? 'Garuda Master AI',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 14),
                                          color: AppColors.getTextMuted(context),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Copy Response',
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: msg.text));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(duration: Duration(seconds: 2), content: Text('Response copied to clipboard')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Rich Markdown AI Output
                                    MarkdownBody(
                                      data: msg.text,
                                      selectable: true,
                                      styleSheet: MarkdownStyleSheet(
                                        p: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.getTextPrimary(context),
                                          height: 1.5,
                                        ),
                                        h1: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accentGold,
                                          letterSpacing: -0.2,
                                          height: 1.4,
                                        ),
                                        h2: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accentGold,
                                          height: 1.35,
                                        ),
                                        h3: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.getTextPrimary(context),
                                          height: 1.3,
                                        ),
                                        strong: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.getTextPrimary(context),
                                        ),
                                        em: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.getTextSecondary(context),
                                        ),
                                        listBullet: const TextStyle(
                                          color: AppColors.accentGold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        code: TextStyle(
                                          backgroundColor: Theme.of(context).brightness == Brightness.light
                                              ? const Color(0xFFF1F5F9)
                                              : const Color(0xFF1E293B),
                                          color: AppColors.accentGold,
                                          fontSize: 11.5,
                                          fontFamily: 'monospace',
                                        ),
                                        codeblockDecoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.light
                                              ? const Color(0xFFF8FAFC)
                                              : const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.getBorder(context)),
                                        ),
                                        horizontalRuleDecoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: AppColors.getBorder(context).withValues(alpha: 0.6),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Dynamic Suggestions Chips if present
                                    if (msg.suggestions != null && msg.suggestions!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      Text(
                                        'SUGGESTED ACTIONS:',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.getTextMuted(context),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: msg.suggestions!.map((sug) {
                                          return InkWell(
                                            onTap: isQuerying ? null : () => _handleSend(aiProvider, sug),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.getElevated(context),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.arrow_forward_rounded, size: 10, color: AppColors.accentGold),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    sug,
                                                    style: const TextStyle(fontSize: 10.5, color: AppColors.accentGold, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Input Area
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.getElevated(context),
              border: Border(top: BorderSide(color: AppColors.getBorder(context))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.getCard(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Ask Garuda about leads, quotes, fleet, payroll...',
                              hintStyle: TextStyle(color: AppColors.getTextMuted(context), fontSize: 12),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            maxLines: 4,
                            minLines: 1,
                            onSubmitted: isQuerying ? null : (_) => _handleSend(aiProvider),
                          ),
                        ),
                        // Voice trigger simulation / quick dictation
                        IconButton(
                          icon: const Icon(Icons.mic_rounded, size: 20),
                          color: AppColors.accentGold,
                          tooltip: 'Voice Commands & Quick Dictation',
                          onPressed: isQuerying ? null : () => _showVoiceCommandModal(context, aiProvider),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF59E0B)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: isQuerying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 20),
                    onPressed: isQuerying ? null : () => _handleSend(aiProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
