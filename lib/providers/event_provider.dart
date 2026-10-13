import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';

class EventProvider extends ChangeNotifier {
  final ApiService apiService;

  List<EventModel> _events = [];
  int _latestEventId = 0;
  bool _isLoading = false;
  Timer? _pollTimer;

  // Active top banner alert for real-time notification in app
  EventModel? _activeAlert;
  Timer? _alertDismissTimer;

  // Real-time visitor & lead telemetry counters from server DB
  int _activeNowCount = 0;
  int _visitors24hCount = 0;
  int _totalVisitorsAll = 0;
  int _liveVisitorCount = 0;
  int _leadsCapturedToday = 0;

  EventProvider({required this.apiService}) {
    startEventPolling();
  }

  List<EventModel> get events => _events;
  int get latestEventId => _latestEventId;
  bool get isLoading => _isLoading;
  EventModel? get activeAlert => _activeAlert;
  int get activeNowCount => _activeNowCount;
  int get visitors24hCount => _visitors24hCount > 0 ? _visitors24hCount : _liveVisitorCount;
  int get totalVisitorsAll => _totalVisitorsAll > 0 ? _totalVisitorsAll : _liveVisitorCount;
  int get liveVisitorCount => _visitors24hCount > 0 ? _visitors24hCount : _liveVisitorCount;
  int get leadsCapturedToday => _leadsCapturedToday;

  void startEventPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await pollRecentEvents();
    });
    // Initial fetch
    pollRecentEvents();
  }

  bool _isPolling = false;
  Future<void> pollRecentEvents() async {
    if (_isPolling || !apiService.isAuthenticated) return;
    _isPolling = true;
    try {
      final res = await apiService.fetchEventsWithStats(
        sinceId: _latestEventId > 0 ? _latestEventId : null,
        limit: 40,
      );

      if (res == null) return;

      _updateServerCounters(res);
      final fetched = (res['events'] as List<EventModel>?) ?? [];
      if (fetched.isEmpty) {
        notifyListeners();
        return;
      }

      if (_latestEventId == 0) {
        // First load: initialize list without spamming alerts
        _events = fetched;
        _latestEventId = fetched.map((e) => e.id).reduce((a, b) => a > b ? a : b);
        _calculateStats();
        notifyListeners();
        return;
      }

      // New events arrived since last poll!
      final newEvents = fetched.where((e) => e.id > _latestEventId).toList();
      if (newEvents.isNotEmpty) {
        _events.insertAll(0, newEvents);
        _latestEventId = newEvents.map((e) => e.id).reduce((a, b) => a > b ? a : b);

        // Trigger active in-app notification banner + haptic/sound alert
        final priorityEvent = newEvents.firstWhere(
          (e) => e.isLeadCapture || e.isCallQueued,
          orElse: () => newEvents.first,
        );
        _showInAppAlert(priorityEvent);
        _calculateStats();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Event polling error: $e');
    } finally {
      _isPolling = false;
    }
  }

  void _updateServerCounters(Map<String, dynamic> res) {
    final activeNow = int.tryParse('${res['active_now_count'] ?? 0}') ?? 0;
    final vis24h = int.tryParse('${res['visitors_24h_count'] ?? 0}') ?? 0;
    final totalAll = int.tryParse('${res['total_visitors_all'] ?? 0}') ?? 0;
    final leads24h = int.tryParse('${res['leads_24h_count'] ?? 0}') ?? 0;

    _activeNowCount = activeNow;
    if (vis24h > 0) _visitors24hCount = vis24h;
    if (totalAll > 0) _totalVisitorsAll = totalAll;
    if (leads24h > 0) _leadsCapturedToday = leads24h;
  }

  void _showInAppAlert(EventModel event) {
    _activeAlert = event;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    _alertDismissTimer?.cancel();
    // Auto-dismiss banner after 7 seconds
    _alertDismissTimer = Timer(const Duration(seconds: 7), () {
      _activeAlert = null;
      notifyListeners();
    });
  }

  void dismissAlert() {
    _activeAlert = null;
    _alertDismissTimer?.cancel();
    notifyListeners();
  }

  void _calculateStats() {
    final localVisitors = _events.where((e) {
      if (!e.isVisitorLanding) return false;
      final ua = (e.details['user_agent'] ?? '').toString().toLowerCase();
      if (ua.contains('bot') || ua.contains('crawl') || ua.contains('spider')) return false;
      return true;
    }).length;
    _liveVisitorCount = localVisitors;
    if (_leadsCapturedToday == 0) {
      _leadsCapturedToday = _events.where((e) => e.isLeadCapture).length;
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    final res = await apiService.fetchEventsWithStats(limit: 60);
    if (res != null) {
      _updateServerCounters(res);
      final allEvents = (res['events'] as List<EventModel>?) ?? [];
      if (allEvents.isNotEmpty) {
        _events = allEvents;
        _latestEventId = allEvents.map((e) => e.id).reduce((a, b) => a > b ? a : b);
        _calculateStats();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _alertDismissTimer?.cancel();
    super.dispose();
  }
}
