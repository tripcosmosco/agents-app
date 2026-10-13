import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/lead_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

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
    _leads = _buildInitialLeads();
    _initAgentIdentity();
    refreshLeadsFromServer();
  }

  String _ownerFilter = 'all'; // 'all', 'my_leads', 'unassigned', 'follow_ups'
  String get ownerFilter => _ownerFilter;

  String _currentAgent = '';
  String get currentAgent => _currentAgent;

  Future<void> _initAgentIdentity() async {
    final saved = await StorageService.getAgentName();
    if (saved.isNotEmpty && saved != 'Executive Agent') {
      _currentAgent = saved;
      notifyListeners();
    }
    try {
      final profile = await apiService.fetchAgentProfile();
      if (profile != null && profile['name'] != null && profile['name'].toString().trim().isNotEmpty) {
        _currentAgent = profile['name'].toString().trim();
        await StorageService.setAgentName(_currentAgent);
        if (profile['paired_ai'] is Map && profile['paired_ai']['name'] != null) {
          await StorageService.setPairedAiName(profile['paired_ai']['name'].toString());
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void setOwnerFilter(String filter) {
    _ownerFilter = filter;
    notifyListeners();
  }

  void setCurrentAgent(String agentName) {
    _currentAgent = agentName.trim();
    StorageService.setAgentName(_currentAgent);
    notifyListeners();
  }

  int get myLeadsCount {
    if (_currentAgent.isEmpty) return 0;
    return _leads.where((l) =>
      l.stickyAgent.isNotEmpty &&
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

      final isMyLead = _currentAgent.isNotEmpty &&
          lead.stickyAgent.isNotEmpty &&
          lead.stickyAgent.toLowerCase() == _currentAgent.toLowerCase();
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
      if (serverLeads.isNotEmpty) {
        _leads = serverLeads;
        _isLiveConnected = true;
      }
    } catch (e) {
      debugPrint('Error syncing leads from server: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static List<LeadModel> _buildInitialLeads() {
    final now = DateTime.now();
    return [
      LeadModel(
        id: 'ld_varanasi_101',
        name: 'Ramesh Chandra',
        phone: '+91 98765 43210',
        email: 'ramesh.chandra@gmail.com',
        destination: 'Varanasi 3D Spiritual Circuit',
        companyOrCity: 'Delhi NCR',
        pax: 4,
        budget: '₹25,000',
        stage: 'new',
        source: 'website_chat',
        stickyAgent: 'Aditi',
        score: 85,
        createdAt: now.subtract(const Duration(minutes: 18)),
        tags: ['VIP Sugam', 'Innova Crysta', 'Senior Citizens'],
        notes: ['Wants Kashi Vishwanath Sugam Darshan passes & morning boat.'],
        lastChatSummary: 'Requested quote for 4 pax, family coming from Delhi.',
      ),
      LeadModel(
        id: 'ld_ayodhya_102',
        name: 'Priya Sharma',
        phone: '+91 98112 34567',
        email: 'priya.s@yahoo.com',
        destination: 'Ayodhya Ram Janmabhoomi 2D/1N',
        companyOrCity: 'Mumbai',
        pax: 2,
        budget: '₹18,000',
        stage: 'contacted',
        source: 'whatsapp',
        stickyAgent: 'Aditi',
        score: 78,
        createdAt: now.subtract(const Duration(hours: 2)),
        tags: ['Ram Mandir VIP', 'Couple'],
        notes: ['Spoke on WhatsApp. Sent hotel options near Kanak Bhavan.'],
        lastChatSummary: 'Interested in Saryu AartiBajra and VIP Darshan.',
      ),
      LeadModel(
        id: 'ld_circuit_103',
        name: 'Vikram Malhotra',
        phone: '+91 97123 45678',
        email: 'vikram.m@corporatetravel.in',
        destination: 'Kashi - Ayodhya - Prayagraj 4D/3N',
        companyOrCity: 'Bangalore',
        pax: 6,
        budget: '₹48,000',
        stage: 'quote_sent',
        source: 'meta_ads',
        stickyAgent: 'Santosh',
        score: 92,
        createdAt: now.subtract(const Duration(hours: 5)),
        tags: ['Golden Circuit', 'High Intent'],
        notes: ['Detailed itinerary sent via WhatsApp PDF.'],
        lastChatSummary: 'Ready to pay 30% advance once flight timings align.',
      ),
      LeadModel(
        id: 'ld_sangam_104',
        name: 'Sneha Patel',
        phone: '+91 99234 56789',
        email: 'sneha.patel@gmail.com',
        destination: 'Prayagraj Triveni Sangam 1-Day',
        companyOrCity: 'Ahmedabad',
        pax: 3,
        budget: '₹12,000',
        stage: 'advance_received',
        source: 'phone_call',
        stickyAgent: 'Santosh',
        score: 96,
        createdAt: now.subtract(const Duration(days: 1)),
        tags: ['Advance Paid', 'Sedan AC'],
        notes: ['₹4,000 advance received via UPI. Cab confirmed.'],
        lastChatSummary: 'Wants pickup from Varanasi Cantt station at 6 AM.',
      ),
      LeadModel(
        id: 'ld_bodhgaya_105',
        name: 'Anand Verma',
        phone: '+91 94123 89012',
        email: '',
        destination: 'Varanasi - Bodhgaya 2D/1N',
        companyOrCity: 'Lucknow',
        pax: 5,
        budget: '₹28,000',
        stage: 'new',
        source: 'website_chat',
        stickyAgent: 'Unassigned',
        score: 70,
        createdAt: now.subtract(const Duration(hours: 1)),
        tags: ['Mahabodhi', 'Unassigned'],
        notes: ['New lead from website chat. Needs assignment.'],
        lastChatSummary: 'Enquiring about Buddhist circuit tour with vehicle.',
      ),
    ];
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
