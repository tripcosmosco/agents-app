import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/call_log_model.dart';
import '../providers/call_provider.dart';
import '../providers/lead_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/cab_fare_dialog.dart';
import '../widgets/live_activity_sheet.dart';
import '../widgets/post_call_action_sheet.dart';
import 'settings_screen.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  String _enteredNumber = '';
  bool _showKeypad = false;

  void _onDigitPressed(String digit) {
    if (_enteredNumber.length < 15) {
      setState(() {
        _enteredNumber += digit;
      });
    }
  }

  void _onBackspacePressed() {
    if (_enteredNumber.isNotEmpty) {
      setState(() {
        _enteredNumber = _enteredNumber.substring(0, _enteredNumber.length - 1);
      });
    }
  }

  void _onLongBackspacePressed() {
    setState(() {
      _enteredNumber = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: AppColors.accentGold,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Consumer<LeadProvider>(
                      builder: (context, lp, _) {
                        final agentName = lp.currentAgent.isNotEmpty ? lp.currentAgent : 'Sales Agent';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle, size: 6, color: AppColors.successGreen),
                              const SizedBox(width: 4),
                              Text(
                                '$agentName (Online)',
                                style: const TextStyle(
                                  color: AppColors.successGreen,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Text(
                  'TripCosmos.co Office Bridge',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 3-Way Switchable Telephony Engine Selector Pill
          PopupMenuButton<TelephonyMode>(
            tooltip: 'Switch Telephony Mode',
            onSelected: (mode) => callProvider.setTelephonyMode(mode),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TelephonyMode.livekitWebRtc,
                child: Row(
                  children: [
                    Icon(Icons.wifi_calling_3, color: AppColors.successGreen, size: 18),
                    SizedBox(width: 8),
                    Text('Option 1: LiveKit WebRTC (₹0 Free)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TelephonyMode.gsmBridge,
                child: Row(
                  children: [
                    Icon(Icons.sim_card, color: Colors.blueAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Option 2: GSM Bridge (+91 93361 16210)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TelephonyMode.airtelIq,
                child: Row(
                  children: [
                    Icon(Icons.phone_in_talk, color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 8),
                    Text('Option 4: Airtel IQ (Masked Call)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TelephonyMode.sipTrunk,
                child: Row(
                  children: [
                    Icon(Icons.cloud_sync, color: AppColors.accentGold, size: 18),
                    SizedBox(width: 8),
                    Text('Option 3: Enterprise SIP Trunk'),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: callProvider.telephonyMode == TelephonyMode.airtelIq
                    ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                    : callProvider.telephonyMode == TelephonyMode.livekitWebRtc
                        ? AppColors.successGreen.withValues(alpha: 0.18)
                        : callProvider.telephonyMode == TelephonyMode.gsmBridge
                            ? AppColors.jioBlue.withValues(alpha: 0.18)
                            : AppColors.accentGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: callProvider.telephonyMode == TelephonyMode.airtelIq
                      ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                      : callProvider.telephonyMode == TelephonyMode.livekitWebRtc
                          ? AppColors.successGreen.withValues(alpha: 0.6)
                          : callProvider.telephonyMode == TelephonyMode.gsmBridge
                              ? AppColors.jioBlue.withValues(alpha: 0.6)
                              : AppColors.accentGold.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    callProvider.telephonyMode == TelephonyMode.airtelIq
                        ? Icons.phone_in_talk
                        : callProvider.telephonyMode == TelephonyMode.livekitWebRtc
                            ? Icons.wifi_calling_3
                            : callProvider.telephonyMode == TelephonyMode.gsmBridge
                                ? Icons.sim_card
                                : Icons.cloud_sync,
                    color: callProvider.telephonyMode == TelephonyMode.airtelIq
                        ? const Color(0xFFEF4444)
                        : callProvider.telephonyMode == TelephonyMode.livekitWebRtc
                            ? AppColors.successGreen
                            : callProvider.telephonyMode == TelephonyMode.gsmBridge
                                ? Colors.blueAccent
                                : AppColors.accentGold,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    callProvider.telephonyMode == TelephonyMode.airtelIq
                        ? 'Airtel IQ (Masked)'
                        : callProvider.telephonyMode == TelephonyMode.livekitWebRtc
                            ? 'WebRTC (₹0)'
                            : callProvider.telephonyMode == TelephonyMode.gsmBridge
                                ? 'GSM (+91 93361)'
                                : 'SIP Trunk',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Live Website Visitor Radar',
            icon: const Icon(Icons.radar_rounded, color: AppColors.successGreen),
            onPressed: () => LiveActivitySheet.show(context),
          ),
          IconButton(
            tooltip: 'Cab Fare Calculator',
            icon: const Icon(Icons.local_taxi_rounded, color: Color(0xFFF59E0B)),
            onPressed: () => CabFareDialog.show(context),
          ),
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(apiService: callProvider.apiService),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: AppColors.accentGold),
            tooltip: 'Server & Companion Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Pending Website Queue Banner
            if (callProvider.pendingQueue.isNotEmpty) ...[
              _buildQueueBanner(context, callProvider),
            ],

            // 2. Active Call In-Progress Widget
            if (callProvider.callState != CallState.idle) ...[
              _buildActiveCallWidget(context, callProvider),
            ],

            // 3. Dialpad / Recent Calls Section
            Expanded(
              child: _showKeypad
                  ? _buildKeypadView(context, callProvider)
                  : _buildRecentCallsList(context, callProvider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryDark,
        onPressed: () {
          setState(() {
            _showKeypad = !_showKeypad;
          });
        },
        icon: Icon(_showKeypad ? Icons.history : Icons.dialpad),
        label: Text(_showKeypad ? 'Recent Calls' : 'Dialpad'),
      ),
    );
  }

  Widget _buildQueueBanner(BuildContext context, CallProvider provider) {
    final firstJob = provider.pendingQueue.first;
    final phone = firstJob['phone'] ?? '';
    final name = firstJob['customer_name'] ?? 'Traveler';
    final reason = firstJob['reason'] ?? 'Tour Consultation';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold.withValues(alpha: 0.25),
            AppColors.accentOrange.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.accentGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt,
              color: AppColors.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WEBSITE CALL REQUEST (LIVE)',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$name • $reason',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  phone,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.startOutboundCall(
                phone: phone,
                name: name,
                tourInterest: reason,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Dial ₹0'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCallWidget(BuildContext context, CallProvider provider) {
    final minutes = (provider.callDurationSeconds ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final seconds = (provider.callDurationSeconds % 60).toString().padLeft(
      2,
      '0',
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.successGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.successGreen.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                provider.callState == CallState.dialing
                    ? 'DIALING (${provider.telephonyMode == TelephonyMode.livekitWebRtc ? "WEBRTC ₹0" : provider.telephonyMode == TelephonyMode.airtelIq ? "AIRTEL IQ" : provider.telephonyMode == TelephonyMode.sipTrunk ? "SIP TRUNK" : "JIO SIM"})...'
                    : 'CALL CONNECTED',
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$minutes:$seconds',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            provider.activeCallerName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            provider.activePhoneNumber,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.accentGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (provider.activeTourInterest != null) ...[
            const SizedBox(height: 6),
            Text(
              provider.activeTourInterest!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: provider.toggleMute,
                icon: Icon(
                  provider.isMuted ? Icons.mic_off : Icons.mic,
                  color: provider.isMuted
                      ? AppColors.errorRed
                      : AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: provider.toggleSpeaker,
                icon: Icon(
                  provider.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  color: provider.isSpeakerOn
                      ? AppColors.accentGold
                      : AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => provider.endCall(),
                icon: const Icon(Icons.call_end, size: 18),
                label: const Text('End Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadView(BuildContext context, CallProvider provider) {
    return Column(
      children: [
        // Entered Number Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _enteredNumber.isEmpty ? 'Enter Phone Number' : _enteredNumber,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _enteredNumber.isEmpty
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              if (_enteredNumber.isNotEmpty) ...[
                InkWell(
                  onTap: _onBackspacePressed,
                  onLongPress: _onLongBackspacePressed,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.backspace_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Dialpad Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1.35,
              mainAxisSpacing: 12,
              crossAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDigitButton('1', ''),
                _buildDigitButton('2', 'ABC'),
                _buildDigitButton('3', 'DEF'),
                _buildDigitButton('4', 'GHI'),
                _buildDigitButton('5', 'JKL'),
                _buildDigitButton('6', 'MNO'),
                _buildDigitButton('7', 'PQRS'),
                _buildDigitButton('8', 'TUV'),
                _buildDigitButton('9', 'WXYZ'),
                _buildDigitButton('*', ''),
                _buildDigitButton('0', '+'),
                _buildDigitButton('#', ''),
              ],
            ),
          ),
        ),

        // Call Action Button
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: FloatingActionButton.large(
            backgroundColor: AppColors.successGreen,
            foregroundColor: Colors.white,
            onPressed: _enteredNumber.isEmpty
                ? null
                : () {
                    provider.startOutboundCall(phone: _enteredNumber);
                  },
            child: const Icon(Icons.call, size: 36),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitButton(String digit, String sub) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (sub.isNotEmpty)
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCallsList(BuildContext context, CallProvider provider) {
    if (provider.callLogs.isEmpty) {
      return const Center(
        child: Text(
          'No recent calls',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.callLogs.length,
      itemBuilder: (context, index) {
        final log = provider.callLogs[index];
        return _buildCallLogTile(context, log, provider);
      },
    );
  }

  Widget _buildCallLogTile(
    BuildContext context,
    CallLogModel log,
    CallProvider provider,
  ) {
    IconData icon;
    Color iconColor;

    switch (log.direction) {
      case CallDirection.inbound:
        icon = Icons.call_received;
        iconColor = AppColors.incomingCall;
        break;
      case CallDirection.outbound:
        icon = Icons.call_made;
        iconColor = AppColors.outboundCall;
        break;
      case CallDirection.missed:
        icon = Icons.call_missed;
        iconColor = AppColors.missedCall;
        break;
    }

    final timeStr = DateFormat('h:mm a').format(log.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () {
          // Open Caller-ID Overlay details
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => PostCallActionSheet(
              callLog: log,
              onDismiss: () => Navigator.pop(context),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.customerName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${log.phone} • $timeStr',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  if (log.tourInterest != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      log.tourInterest!,
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Duration pill
            if (log.durationSeconds > 0)
              Text(
                log.formattedDuration,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                provider.startOutboundCall(
                  phone: log.phone,
                  name: log.customerName,
                  tourInterest: log.tourInterest,
                );
              },
              icon: const Icon(
                Icons.call,
                color: AppColors.successGreen,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
