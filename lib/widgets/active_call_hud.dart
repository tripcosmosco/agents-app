import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/call_provider.dart';

class ActiveCallHud extends StatelessWidget {
  final VoidCallback? onOpenLeadCrm;

  const ActiveCallHud({super.key, this.onOpenLeadCrm});

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);

    if (callProvider.callState == CallState.idle) {
      return const SizedBox.shrink();
    }

    final isConnecting = callProvider.callState == CallState.dialing ||
        callProvider.callState == CallState.ringing;
    final minutes = (callProvider.callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (callProvider.callDurationSeconds % 60).toString().padLeft(2, '0');

    final modeBadge = callProvider.telephonyMode == TelephonyMode.livekitWebRtc
        ? 'WEBRTC (₹0)'
        : callProvider.telephonyMode == TelephonyMode.gsmBridge
            ? 'GSM (+91 93361)'
            : callProvider.telephonyMode == TelephonyMode.airtelIq
                ? 'AIRTEL IQ'
                : 'SIP TRUNK';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2E1E), Color(0xFF131D3B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnecting ? AppColors.accentGold : AppColors.successGreen,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isConnecting ? AppColors.accentGold : AppColors.successGreen)
                      .withValues(alpha: 0.3),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
              children: [
                // Pulsing Call Indicator Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isConnecting ? AppColors.accentGold : AppColors.successGreen)
                        .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isConnecting ? Icons.ring_volume : Icons.phone_in_talk,
                    color: isConnecting ? AppColors.accentGold : AppColors.successGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),

                // Caller Info & Timer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              callProvider.activeCallerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              modeBadge,
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            callProvider.activePhoneNumber,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isConnecting ? 'Connecting...' : '$minutes:$seconds',
                            style: TextStyle(
                              color: isConnecting ? AppColors.accentGold : AppColors.successGreen,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Mute Mic Button
                IconButton(
                  onPressed: callProvider.toggleMute,
                  icon: Icon(
                    callProvider.isMuted ? Icons.mic_off : Icons.mic,
                    color: callProvider.isMuted ? AppColors.errorRed : Colors.white,
                    size: 20,
                  ),
                  tooltip: callProvider.isMuted ? 'Unmute' : 'Mute',
                ),

                // Speaker Button
                IconButton(
                  onPressed: callProvider.toggleSpeaker,
                  icon: Icon(
                    callProvider.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    color: callProvider.isSpeakerOn ? AppColors.accentGold : Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Speaker',
                ),

                // Hang Up Button
                InkWell(
                  onTap: () => callProvider.endCall(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            if (!isConnecting) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '💡 AI Co-Pilot (${callProvider.activeTourInterest ?? "Varanasi"}): Pitch customized itinerary & ₹1,500 token lock on WhatsApp',
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  ),
);
  }
}
