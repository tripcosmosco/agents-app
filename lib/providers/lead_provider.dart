import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/lead_model.dart';
import '../services/api_service.dart';

class LeadProvider extends ChangeNotifier {
  final ApiService apiService;

  List<LeadModel> _leads = [];
  List<LeadModel> get leads => _leads;

  String _selectedStage = 'all';
  String get selectedStage => _selectedStage;

  String _selectedSource = 'all';
  String get selectedSource => _selectedSource;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  LeadProvider({required this.apiService}) {
    refreshLeadsFromServer();
  }

  String _ownerFilter = 'all'; // 'all', 'my_leads', 'unassigned', 'follow_ups'
  String get ownerFilter => _ownerFilter;

  String _currentAgent = 'Santosh Yadav';
  String get currentAgent => _currentAgent;

  void setOwnerFilter(String filter) {
    _ownerFilter = filter;
    notifyListeners();
  }

  void setCurrentAgent(String agentName) {
    _currentAgent = agentName;
    notifyListeners();
  }

  int get myLeadsCount {
    return _leads.where((l) =>
      l.stickyAgent.toLowerCase() == _currentAgent.toLowerCase()
    ).length;
  }

  int get unassignedLeadsCount {
    return _leads.where((l) =>
      l.stickyAgent.isEmpty ||
      l.stickyAgent.toLowerCase() == 'unassigned' ||
      l.stickyAgent.toLowerCase() == 'admin'
    ).length;
  }

  int get followUpsDueCount {
    final now = DateTime.now();
    return _leads.where((l) =>
      l.nextFollowUpAt != null &&
      l.nextFollowUpAt!.isBefore(now.add(const Duration(hours: 24)))
    ).length;
  }

  List<LeadModel> get filteredLeads {
    return _leads.where((lead) {
      final matchesStage =
          _selectedStage == 'all' ||
          lead.stage.toLowerCase() == _selectedStage.toLowerCase();
      final matchesSource =
          _selectedSource == 'all' ||
          lead.source.toLowerCase() == _selectedSource.toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty ||
          lead.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lead.phone.contains(_searchQuery) ||
          lead.destination.toLowerCase().contains(_searchQuery.toLowerCase());

      final isMyLead = lead.stickyAgent.toLowerCase() == _currentAgent.toLowerCase();
      final isUnassigned = lead.stickyAgent.isEmpty ||
          lead.stickyAgent.toLowerCase() == 'unassigned' ||
          lead.stickyAgent.toLowerCase() == 'admin';
      final hasFollowUpDue = lead.nextFollowUpAt != null &&
          lead.nextFollowUpAt!.isBefore(DateTime.now().add(const Duration(hours: 24)));

      final matchesOwner = _ownerFilter == 'all' ||
          (_ownerFilter == 'my_leads' && isMyLead) ||
          (_ownerFilter == 'unassigned' && isUnassigned) ||
          (_ownerFilter == 'follow_ups' && hasFollowUpDue);

      return matchesStage && matchesSource && matchesSearch && matchesOwner;
    }).toList();
  }

  void setStageFilter(String stage) {
    _selectedStage = stage;
    notifyListeners();
  }

  void setSourceFilter(String source) {
    _selectedSource = source;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool _isLiveConnected = false;
  bool get isLiveConnected => _isLiveConnected;

  Future<void> refreshLeadsFromServer() async {
    _isLoading = true;
    notifyListeners();

    try {
      final serverLeads = await apiService.fetchLeads();
      _leads = serverLeads;
      _isLiveConnected = true;
    } catch (e) {
      debugPrint('Error syncing leads from server: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateLeadStage(String leadId, String newStage) {
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index != -1) {
      final lead = _leads[index];
      final updated = lead.copyWith(
        stage: newStage,
        lastContactAt: DateTime.now(),
      );
      _leads[index] = updated;
      notifyListeners();

      apiService.updateLead(
        leadId: leadId,
        phone: lead.phone,
        name: lead.name,
        stage: newStage,
      );
    }
  }

  void addLeadNote(String leadId, String noteText) {
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index != -1) {
      final lead = _leads[index];
      final currentNotes = List<String>.from(lead.notes);
      currentNotes.insert(
        0,
        '${DateTime.now().toLocal().toString().split('.')[0]}: $noteText',
      );
      _leads[index] = lead.copyWith(
        notes: currentNotes,
        lastContactAt: DateTime.now(),
      );
      notifyListeners();

      apiService.updateLead(
        leadId: leadId,
        phone: lead.phone,
        name: lead.name,
        note: noteText,
        author: _currentAgent,
      );
    }
  }

  void assignLeadOwner(String leadId, String newOwner) {
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index != -1) {
      final lead = _leads[index];
      _leads[index] = lead.copyWith(stickyAgent: newOwner);
      notifyListeners();

      apiService.updateLead(
        leadId: leadId,
        phone: lead.phone,
        name: lead.name,
        owner: newOwner,
      );
    }
  }

  void scheduleFollowUp(String leadId, DateTime followUpAt) {
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index != -1) {
      final lead = _leads[index];
      _leads[index] = lead.copyWith(nextFollowUpAt: followUpAt);
      notifyListeners();

      apiService.updateLead(
        leadId: leadId,
        phone: lead.phone,
        name: lead.name,
        nextFollowUpAt: followUpAt.toIso8601String(),
      );
    }
  }

  Future<void> createNewLead({
    required String name,
    required String phone,
    String? email,
    String destination = 'Varanasi',
    int pax = 2,
    String budget = '',
    String source = 'phone_call',
    String stage = 'new',
    String? note,
    DateTime? nextFollowUpAt,
  }) async {
    final tempLead = LeadModel(
      id: 'ld_${const Uuid().v4().substring(0, 8)}',
      name: name,
      phone: phone,
      email: email ?? '',
      destination: destination,
      pax: pax,
      budget: budget,
      stage: stage,
      source: source,
      createdAt: DateTime.now(),
      nextFollowUpAt: nextFollowUpAt,
      notes: note != null && note.isNotEmpty ? [note] : [],
    );

    _leads.insert(0, tempLead);
    notifyListeners();

    final res = await apiService.createLead(
      name: name,
      phone: phone,
      email: email,
      destination: destination,
      budget: budget,
      note: note,
      pax: pax,
      stage: stage,
      nextFollowUpAt: nextFollowUpAt?.toIso8601String(),
    );

    if (res != null && res['ok'] == true) {
      refreshLeadsFromServer();
    }
  }
}
