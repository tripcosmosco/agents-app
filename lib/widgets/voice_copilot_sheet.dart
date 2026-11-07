import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../providers/ai_agent_provider.dart';
import '../services/api_service.dart';

class VoiceCopilotSheet extends StatefulWidget {
  final ApiService? apiService;

  const VoiceCopilotSheet({super.key, this.apiService});

  static Future<void> show(BuildContext context, {ApiService? apiService}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceCopilotSheet(apiService: apiService),
    );
  }

  @override
  State<VoiceCopilotSheet> createState() => _VoiceCopilotSheetState();
}

class _VoiceCopilotSheetState extends State<VoiceCopilotSheet> with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  bool _isProcessing = false;
  // String? _lastQuery;
  String? _responseText;
  String? _detectedCorridor;
  String? _indicativePrice;
  String? _providerName;
  int? _latencyMs;
  List<String> _dynamicSuggestions = [];

  final List<String> _presetVoicePrompts = const [
    '🌅 Morning Operations & Pipeline Briefing',
    '🔥 Show hot leads needing immediate callback',
    '🚗 Calculate Innova Crysta rate: Kashi to Ayodhya',
    '🤝 Overview of our 727 B2B Wholesale Partners',
    '💰 Check staff payroll & financial status',
    '⚡ Dev Deepawali Bajra boat charters & luxury VIP passes',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _executeVoiceQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    setState(() {
      _isProcessing = true;
      // _lastQuery = clean;
      _responseText = null;
      _detectedCorridor = null;
      _indicativePrice = null;
      _dynamicSuggestions = [];
    });

    final aiProvider = Provider.of<AiAgentProvider>(context, listen: false);
    final api = widget.apiService ?? aiProvider.apiService;

    try {
      // 1. Query Master Assistant (Powered by live Gemini 2.5 on backend)
      final res = await api.queryMasterAssistant(message: clean);

      if (mounted) {
        if (res != null && (res['ok'] == true || res['success'] == true)) {
          setState(() {
            _responseText = res['reply']?.toString() ?? 'Operations query processed successfully.';
            _providerName = res['provider']?.toString() ?? 'gemini';
            _latencyMs = res['latency_ms'] is int ? res['latency_ms'] as int : 0;
            if (res['suggestions'] is List) {
              _dynamicSuggestions = (res['suggestions'] as List).map((e) => e.toString()).toList();
            }
          });

          // Also record in Master AI Assistant history for seamless continuity
          aiProvider.sendMasterAiQuery(clean);
        } else {
          // Fallback to Voice Brain endpoint
          final voiceRes = await api.askVoiceBrain(query: clean);
          if (voiceRes != null && mounted) {
            setState(() {
              _responseText = voiceRes['reply']?.toString() ?? voiceRes['speech_text']?.toString() ?? 'Tariff retrieved.';
              _detectedCorridor = voiceRes['detected_corridor']?.toString();
              _indicativePrice = voiceRes['indicative_price']?.toString();
              _providerName = 'voice-brain';
            });
          } else {
            setState(() {
              _responseText = 'Garuda AI Co-Pilot is currently updating live tariffs. Please retry in a few moments.';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _responseText = 'Connection error: Could not reach TripCosmos Brain. Please check network.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
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
    }
  }

  void _shareViaWhatsApp(String text) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedBg = AppColors.getElevated(context);
    final cardBg = AppColors.getCard(context);
    final goldAccent = AppColors.getAccentGold(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: elevatedBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: goldAccent.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: goldAccent.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // 2. Executive Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                            color: goldAccent.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.black, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Garuda Voice Copilot',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'GEMINI 2.5 LIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF10B981),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'AI Spoken Intelligence Desk • Instant Tariffs & Operations Triaging',
                            style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(context)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppColors.getTextMuted(context),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 3. Scrollable Conversation & Response Area
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    children: [
                      // Animated Voice Wave Radar
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (ctx, child) {
                          return Transform.scale(
                            scale: _isProcessing ? _pulseAnimation.value : 1.0,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _isProcessing
                                      ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
                                      : [const Color(0xFFD4AF37), const Color(0xFFF59E0B)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isProcessing ? Colors.orange : goldAccent).withValues(alpha: 0.4),
                                    blurRadius: _isProcessing ? 24 : 14,
                                    spreadRadius: _isProcessing ? 6 : 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isProcessing ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                                color: Colors.black,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isProcessing
                            ? 'Garuda Brain is querying live operations...'
                            : 'Tap a prompt below or dictate any inquiry',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _isProcessing ? Colors.orange : AppColors.getTextMuted(context),
                        ),
                      ),

                      // Corridor & Price Pill if present
                      if (_detectedCorridor != null && _detectedCorridor != 'General Pilgrimage') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: goldAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: goldAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_taxi_rounded, size: 15, color: AppColors.accentGold),
                              const SizedBox(width: 8),
                              Text(
                                '$_detectedCorridor • ${_indicativePrice ?? 'Official Tariff'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Response Container
                      if (_responseText != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.getBorder(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.bolt_rounded, size: 16, color: AppColors.accentGold),
                                      const SizedBox(width: 6),
                                      Text(
                                        'CO-PILOT INTELLIGENCE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: goldAccent,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_latencyMs != null && _latencyMs! > 0)
                                    Text(
                                      '${_latencyMs}ms • ${_providerName ?? 'gemini'}',
                                      style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(context)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              MarkdownBody(
                                data: _responseText!,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13, height: 1.45),
                                  strong: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold),
                                  listBullet: TextStyle(color: goldAccent),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 18),
                                    color: goldAccent,
                                    tooltip: 'Copy to Clipboard',
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: _responseText!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✓ Copied to clipboard!')),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.share_rounded, size: 18),
                                    color: const Color(0xFF25D366),
                                    tooltip: 'Share via WhatsApp',
                                    onPressed: () => _shareViaWhatsApp(_responseText!),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                                    label: const Text('Add to Chat', style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(foregroundColor: goldAccent),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Dynamic Follow-up Suggestions
                      if (_dynamicSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'NEXT LOGICAL STEPS:',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _dynamicSuggestions.map((sug) {
                            return ActionChip(
                              avatar: const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.accentGold),
                              label: Text(sug, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                              backgroundColor: cardBg,
                              side: BorderSide(color: goldAccent.withValues(alpha: 0.35)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              onPressed: _isProcessing ? null : () => _executeVoiceQuery(sug),
                            );
                          }).toList(),
                        ),
                      ],

                      // Preset Voice Commands
                      const SizedBox(height: 18),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'FREQUENT VOICE COMMANDS:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._presetVoicePrompts.map((cmd) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isProcessing ? null : () => _executeVoiceQuery(cmd),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.getBorder(context)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.play_circle_filled_rounded, color: AppColors.accentGold, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          cmd,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.getTextPrimary(context),
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              // 4. Dictation Input Bar
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(top: BorderSide(color: AppColors.getBorder(context))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: elevatedBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: TextField(
                          controller: _queryController,
                          style: TextStyle(fontSize: 13, color: AppColors.getTextPrimary(context)),
                          decoration: InputDecoration(
                            hintText: 'Speak or type any operations inquiry...',
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.getTextMuted(context)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: _isProcessing ? null : (val) {
                            _queryController.clear();
                            _executeVoiceQuery(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFF59E0B)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 20),
                        onPressed: _isProcessing
                            ? null
                            : () {
                                final text = _queryController.text;
                                _queryController.clear();
                                _executeVoiceQuery(text);
                              },
                      ),
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
}
