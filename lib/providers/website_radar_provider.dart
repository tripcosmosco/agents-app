import 'dart:async';
import 'package:flutter/material.dart';
import '../models/website_visitor_model.dart';
import '../services/api_service.dart';

class WebsiteRadarProvider extends ChangeNotifier {
  final List<WebsiteVisitor> _visitors = [];
  Timer? _ticker;
  Timer? _remotePoller;
  final ApiService _api = ApiService();
  bool _isLiveSynced = false;
  bool _disposed = false;

  WebsiteRadarProvider() {
    _initDefaultVisitors();
    _startLiveSimulation();
    _startRemotePolling();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _remotePoller?.cancel();
    super.dispose();
  }

  List<WebsiteVisitor> get visitors => List.unmodifiable(_visitors);
  bool get isLiveSynced => _isLiveSynced;

  int get activeCount => _visitors.where((v) => v.isOnline).length;
  int get hotCount => _visitors.where((v) => v.intentScore >= 75).length;

  void _startRemotePolling() {
    _fetchLiveVisitors();
    _remotePoller = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchLiveVisitors();
    });
  }

  Future<void> _fetchLiveVisitors() async {
    try {
      final remoteList = await _api.fetchLiveRadarVisitors();
      if (remoteList.isNotEmpty) {
        _isLiveSynced = true;
        final now = DateTime.now();
        final List<WebsiteVisitor> updated = [];

        for (final r in remoteList) {
          final id = (r['visitor_id'] ?? r['thread_id'] ?? r['id'] ?? '').toString();
          final city = (r['city'] ?? 'Varanasi').toString();
          final country = (r['country'] ?? 'India').toString();
          final flag = country.toLowerCase().contains('india') ? '🇮🇳' : '🌐';
          final page = (r['current_page'] ?? '/kashi-divya-darshan').toString();
          final intentScore = (r['intent_score'] as num?)?.toInt() ?? 88;
          final intentLabel = (r['intent'] ?? 'High-Intent Pilgrimage Inquiry').toString();

          updated.add(WebsiteVisitor(
            id: id,
            ip: '200.234.41.x',
            city: city,
            country: country,
            flag: flag,
            currentPage: page,
            pageTitle: r['summary']?.toString() ?? 'TripCosmos Prospective Traveler',
            referrer: 'Google Search / Direct',
            durationSeconds: 120,
            scrollDepth: 80,
            intentScore: intentScore,
            intentLabel: intentLabel,
            device: 'Mobile Browser',
            isOnline: true,
            lastActive: now,
          ));
        }

        if (updated.isNotEmpty && !_disposed) {
          _visitors.clear();
          _visitors.addAll(updated);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating radar visitors: $e');
    }
  }

  void _startLiveSimulation() {
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_disposed) return;
      for (int i = 0; i < _visitors.length; i++) {
        if (_visitors[i].isOnline) {
          final newDuration = _visitors[i].durationSeconds + 5;
          _visitors[i] = _visitors[i].copyWith(
            durationSeconds: newDuration,
            lastActive: DateTime.now(),
          );
        }
      }
      notifyListeners();
    });
  }

  /// Trigger a 1-click Proactive Chat ping to an active website visitor
  Future<bool> proactivePing({
    required WebsiteVisitor visitor,
    required String promptMessage,
  }) async {
    final ok = await _api.sendProactivePing(
      visitorId: visitor.id,
      message: promptMessage,
    );
    notifyListeners();
    return ok;
  }

  void _initDefaultVisitors() {
    final now = DateTime.now();
    _visitors.addAll([
      WebsiteVisitor(
        id: 'vis_vns_01',
        ip: '103.21.244.18',
        city: 'Varanasi',
        country: 'India',
        flag: '🇮🇳',
        currentPage: '/kashi-divya-darshan-vip',
        pageTitle: '3-Day Kashi Divya Darshan VIP Itinerary',
        referrer: 'Google Search ("kashi vishwanath sugam darshan package")',
        durationSeconds: 145,
        scrollDepth: 90,
        intentScore: 94,
        intentLabel: 'High Intent',
        device: 'iPhone 15 Pro • Safari',
        isOnline: true,
        lastActive: now,
      ),
      WebsiteVisitor(
        id: 'vis_sur_02',
        ip: '117.211.88.24',
        city: 'Surat',
        country: 'India',
        flag: '🇮🇳',
        currentPage: '/dev-diwali-private-bajra',
        pageTitle: 'Dev Diwali 2026 Private VIP Bajra Charter',
        referrer: 'Direct WhatsApp Share',
        durationSeconds: 180,
        scrollDepth: 95,
        intentScore: 96,
        intentLabel: 'Pricing Evaluation',
        device: 'Samsung Galaxy S24 • Chrome',
        isOnline: true,
        lastActive: now,
      ),
      WebsiteVisitor(
        id: 'vis_mum_03',
        ip: '182.72.14.92',
        city: 'Mumbai',
        country: 'India',
        flag: '🇮🇳',
        currentPage: '/varanasi-ayodhya-prayagraj-cab',
        pageTitle: 'Outstation Luxury Cab Tariff & Booking',
        referrer: 'Google Search ("innova crysta varanasi to ayodhya")',
        durationSeconds: 95,
        scrollDepth: 75,
        intentScore: 82,
        intentLabel: 'Engaged Prospect',
        device: 'MacBook Air • Chrome',
        isOnline: true,
        lastActive: now,
      ),
      WebsiteVisitor(
        id: 'vis_dxb_04',
        ip: '194.170.12.88',
        city: 'Dubai',
        country: 'UAE',
        flag: '🇦🇪',
        currentPage: '/luxury-ganga-heritage-hotels',
        pageTitle: 'BrijRama Palace & Taj Ganges Suites',
        referrer: 'Instagram Ad (Direct)',
        durationSeconds: 45,
        scrollDepth: 50,
        intentScore: 68,
        intentLabel: 'Casual Browsing',
        device: 'iPad Pro • Safari',
        isOnline: true,
        lastActive: now,
      ),
    ]);
  }
}
