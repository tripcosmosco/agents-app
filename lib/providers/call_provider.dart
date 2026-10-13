import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/call_log_model.dart';
import '../services/api_service.dart';
import '../services/telephony_service.dart';

enum CallState { idle, ringing, dialing, connected, ended }
enum TelephonyMode { livekitWebRtc, gsmBridge, airtelIq, sipTrunk }

class CallProvider extends ChangeNotifier {
  final ApiService apiService;

  CallState _callState = CallState.idle;
  CallState get callState => _callState;

  TelephonyMode _telephonyMode = TelephonyMode.livekitWebRtc;
  TelephonyMode get telephonyMode => _telephonyMode;

  String? _activeCallUrl;
  String? get activeCallUrl => _activeCallUrl;

  String? _activeRoomName;
  String? get activeRoomName => _activeRoomName;

  String? _activeCallId;
  String? get activeCallId => _activeCallId;

  String _activePhoneNumber = '';
  String get activePhoneNumber => _activePhoneNumber;

  String _activeCallerName = '';
  String get activeCallerName => _activeCallerName;

  String? _activeTourInterest;
  String? get activeTourInterest => _activeTourInterest;

  int _callDurationSeconds = 0;
  int get callDurationSeconds => _callDurationSeconds;

  Timer? _durationTimer;
  Timer? _queuePollTimer;

  List<CallLogModel> _callLogs = [];
  List<CallLogModel> get callLogs => _callLogs;

  List<Map<String, dynamic>> _pendingQueue = [];
  List<Map<String, dynamic>> get pendingQueue => _pendingQueue;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _isSpeakerOn = false;
  bool get isSpeakerOn => _isSpeakerOn;

  CallLogModel? _lastCompletedCall;
  CallLogModel? get lastCompletedCall => _lastCompletedCall;

  // Power Dialer Engine
  List<Map<String, dynamic>> _powerDialerQueue = [];
  int _powerDialerIndex = 0;
  bool _isPowerDialerActive = false;
  bool get isPowerDialerActive => _isPowerDialerActive;
  int get powerDialerIndex => _powerDialerIndex;
  int get powerDialerTotal => _powerDialerQueue.length;
  Map<String, dynamic>? get currentPowerDialerLead =>
      _powerDialerQueue.isNotEmpty && _powerDialerIndex < _powerDialerQueue.length
          ? _powerDialerQueue[_powerDialerIndex]
          : null;

  void startPowerDialer(List<Map<String, dynamic>> leads) {
    if (leads.isEmpty) return;
    _powerDialerQueue = List.from(leads);
    _powerDialerIndex = 0;
    _isPowerDialerActive = true;
    notifyListeners();
    _dialCurrentPowerLead();
  }

  void _dialCurrentPowerLead() {
    final lead = currentPowerDialerLead;
    if (lead == null) {
      stopPowerDialer();
      return;
    }
    startOutboundCall(
      phone: lead['phone']?.toString() ?? '',
      name: lead['name']?.toString() ?? 'Traveler',
      tourInterest: lead['destination']?.toString() ?? 'Spiritual Pilgrimage',
    );
  }

  void nextPowerDialerLead() {
    if (!_isPowerDialerActive) return;
    if (_powerDialerIndex + 1 < _powerDialerQueue.length) {
      _powerDialerIndex++;
      notifyListeners();
      _dialCurrentPowerLead();
    } else {
      stopPowerDialer();
    }
  }

  void skipPowerDialerLead() {
    if (!_isPowerDialerActive) return;
    if (_powerDialerIndex + 1 < _powerDialerQueue.length) {
      _powerDialerIndex++;
      notifyListeners();
      _dialCurrentPowerLead();
    } else {
      stopPowerDialer();
    }
  }

  void stopPowerDialer() {
    _isPowerDialerActive = false;
    _powerDialerQueue = [];
    _powerDialerIndex = 0;
    notifyListeners();
  }

  CallProvider({required this.apiService}) {
    fetchCallLogsFromServer();
    startQueuePolling();
  }

  Future<void> fetchCallLogsFromServer() async {
    final logs = await apiService.fetchCallLogs();
    if (logs.isNotEmpty) {
      _callLogs = logs;
      notifyListeners();
    }
  }

  void startQueuePolling() {
    _queuePollTimer?.cancel();
    _queuePollTimer = Timer.periodic(const Duration(seconds: 12), (
      timer,
    ) async {
      await checkCallQueue();
    });
    checkCallQueue();
  }

  bool _isCheckingQueue = false;
  Future<void> checkCallQueue() async {
    if (_isCheckingQueue) return;
    _isCheckingQueue = true;
    try {
      final queue = await apiService.fetchCallQueue();
      _pendingQueue = queue;
      notifyListeners();
    } catch (e) {
      debugPrint('Queue poll error: $e');
    } finally {
      _isCheckingQueue = false;
    }
  }

  void setTelephonyMode(TelephonyMode mode) {
    _telephonyMode = mode;
    notifyListeners();
  }

  /// Start an Outbound Call using the active Telephony Engine
  Future<void> startOutboundCall({
    required String phone,
    String name = 'Traveler',
    String? tourInterest,
    bool launchNativeDialer = true,
    TelephonyMode? specificMode,
  }) async {
    final mode = specificMode ?? _telephonyMode;
    _activeCallId = 'tc_${DateTime.now().millisecondsSinceEpoch}';
    _activePhoneNumber = phone;
    _activeCallerName = name;
    _activeTourInterest = tourInterest ?? 'Varanasi Pilgrimage & Tour';
    _callState = CallState.dialing;
    _callDurationSeconds = 0;
    _isMuted = false;
    _isSpeakerOn = false;
    notifyListeners();

    // Option 1: LiveKit WebRTC (100% Free + WhatsApp 1-tap call invite from Evolution API)
    if (mode == TelephonyMode.livekitWebRtc) {
      final res = await apiService.initiateTelephonyCall(
        phone: phone,
        customerName: name,
        reason: tourInterest ?? 'Pilgrimage Consultation',
        modeOverride: 'livekit_webrtc',
      );
      if (res != null) {
        _activeRoomName = res['room_name']?.toString();
        _activeCallUrl = res['call_url']?.toString();
        if (res['call_id'] != null) {
          _activeCallId = res['call_id'].toString();
        }
      }
    } else if (mode == TelephonyMode.airtelIq) {
      // Option 4: Airtel IQ Business Connect (Dual-Leg Click-to-Call + Number Masking)
      final res = await apiService.initiateTelephonyCall(
        phone: phone,
        customerName: name,
        reason: tourInterest ?? 'Pilgrimage Consultation',
        modeOverride: 'airtel_iq',
      );
      if (res != null && res['call_id'] != null) {
        _activeCallId = res['call_id'].toString();
      }
    } else if (mode == TelephonyMode.sipTrunk) {
      // Option 3: Enterprise Cloud SIP Trunk
      final res = await apiService.initiateTelephonyCall(
        phone: phone,
        customerName: name,
        reason: tourInterest ?? 'Pilgrimage Consultation',
        modeOverride: 'sip_trunk',
      );
      if (res != null && res['call_id'] != null) {
        _activeCallId = res['call_id'].toString();
      }
    } else {
      // Option 2: Android GSM Bridge (uses office SIM phone or local dialer)
      if (launchNativeDialer) {
        await TelephonyService.dialNumber(phone);
      }
      await apiService.initiateTelephonyCall(
        phone: phone,
        customerName: name,
        reason: tourInterest ?? 'Pilgrimage Consultation',
        modeOverride: 'jio_sim',
      );
    }

    // Report dialing to server
    await apiService.reportCallDispatch(
      callId: _activeCallId!,
      status: 'dialing',
      phone: phone,
    );

    // Start elapsed timer while call session is active
    _callState = CallState.connected;
    _startTimer();
    notifyListeners();

    await apiService.reportCallDispatch(
      callId: _activeCallId!,
      status: 'connected',
      phone: phone,
    );
  }

  void markCallConnected() {
    if (_callState != CallState.connected) {
      _callState = CallState.connected;
      _startTimer();
      notifyListeners();
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDurationSeconds++;
      notifyListeners();
    });
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  /// End active call and prepare post-call quick action sheet
  Future<void> endCall({String notes = ''}) async {
    _durationTimer?.cancel();
    final completedId = _activeCallId ?? const Uuid().v4();
    final duration = _callDurationSeconds;

    _callState = CallState.ended;

    final newLog = CallLogModel(
      id: completedId,
      phone: _activePhoneNumber,
      customerName: _activeCallerName.isNotEmpty
          ? _activeCallerName
          : 'Traveler',
      direction: CallDirection.outbound,
      status: 'completed',
      timestamp: DateTime.now(),
      durationSeconds: duration,
      tourInterest: _activeTourInterest,
      notes: notes.isNotEmpty ? notes : 'Call completed via Jio 5G SIM.',
      aiQualified: true,
    );

    _callLogs.insert(0, newLog);
    _lastCompletedCall = newLog;
    notifyListeners();

    // Report completion to WordPress
    await apiService.reportCallDispatch(
      callId: completedId,
      status: 'completed',
      phone: _activePhoneNumber,
      duration: duration,
      notes: notes,
    );

    // Reset after delay
    Future.delayed(const Duration(milliseconds: 600), () {
      _callState = CallState.idle;
      notifyListeners();
    });

    // Refresh queue & server call logs
    checkCallQueue();
    fetchCallLogsFromServer();
  }

  void clearLastCompletedCall() {
    _lastCompletedCall = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _queuePollTimer?.cancel();
    super.dispose();
  }
}
