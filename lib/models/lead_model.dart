class LeadModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String destination;
  final String companyOrCity;
  final int pax;
  final String budget;
  final String stage; // new, contacted, qualified, quote_sent, won, lost
  final String source; // website_chat, whatsapp, meta_ads, google_ads, phone_call
  final String stickyAgent; // Lead Owner
  final int score;
  final DateTime createdAt;
  final DateTime? lastContactAt;
  final DateTime? nextFollowUpAt;
  final List<String> tags;
  final List<String> notes;
  final String? lastChatSummary;

  LeadModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.destination = 'Varanasi',
    this.companyOrCity = 'Varanasi',
    this.pax = 2,
    this.budget = '',
    this.stage = 'new',
    this.source = 'website_chat',
    this.stickyAgent = '',
    this.score = 65,
    required this.createdAt,
    this.lastContactAt,
    this.nextFollowUpAt,
    this.tags = const [],
    this.notes = const [],
    this.lastChatSummary,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'TL';
  }

  String get ownerInitials {
    final parts = stickyAgent.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'AV';
  }

  /// Dynamic Real-Time Urgency Score (0 - 150)
  int get intelligentUrgencyScore {
    int total = score > 0 ? (score / 3).round() : 20;
    final now = DateTime.now();

    // 1. Golden Response Window for New Leads (< 15 min SLA)
    if (stage == 'new' || stage == 'inquiry') {
      final ageMinutes = now.difference(createdAt).inMinutes;
      if (ageMinutes <= 15) {
        total += 55; // Extreme Priority
      } else if (ageMinutes <= 60) {
        total += 35;
      } else if (ageMinutes <= 240) {
        total += 20;
      }
    }

    // 2. Follow-Up Deadlines
    if (nextFollowUpAt != null) {
      if (nextFollowUpAt!.isBefore(now)) {
        total += 45; // Overdue task!
      } else if (nextFollowUpAt!.isBefore(now.add(const Duration(hours: 4)))) {
        total += 30; // Due within 4 hours
      } else if (nextFollowUpAt!.isBefore(now.add(const Duration(hours: 24)))) {
        total += 15;
      }
    }

    // 3. High Deal Value / Large Group
    if (pax >= 5) total += 15;
    final numericBudget = int.tryParse(budget.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (numericBudget >= 40000) total += 20;

    // 4. Buying Decision Stage
    if (stage == 'quote_sent' || stage == 'proposal') {
      total += 25; // In decision loop
    } else if (stage == 'contacted' || stage == 'qualified') {
      total += 15;
    } else if (stage == 'won' || stage == 'lost') {
      total -= 35; // Already concluded
    }

    return total;
  }

  /// Dynamic Urgency Tag for Badges
  String? get urgencyTag {
    final now = DateTime.now();
    if ((stage == 'new' || stage == 'inquiry') && now.difference(createdAt).inMinutes <= 20) {
      return '⚡ SLA 15M (Golden)';
    }
    if (nextFollowUpAt != null && nextFollowUpAt!.isBefore(now)) {
      return '🚨 Follow-Up Overdue';
    }
    if (nextFollowUpAt != null && nextFollowUpAt!.isBefore(now.add(const Duration(hours: 4)))) {
      return '⏳ Due Today';
    }
    final numericBudget = int.tryParse(budget.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (numericBudget >= 40000 || pax >= 6) {
      return '💎 High Value';
    }
    if (stage == 'quote_sent' || stage == 'proposal') {
      return '🔥 Decision Pending';
    }
    return null;
  }

  /// Next-Best-Action Label tailored to Lead Stage
  String get nextBestActionLabel {
    switch (stage.toLowerCase()) {
      case 'new':
      case 'inquiry':
        return '⚡ 1-Tap First Call & Intro';
      case 'contacted':
      case 'qualified':
        return '💰 Build Custom Quotation';
      case 'quote_sent':
      case 'proposal':
        return '💳 Secure Booking Token (UPI)';
      case 'won':
      case 'converted':
        return '🚗 Dispatch Fleet & Driver Slip';
      case 'lost':
        return '🔄 Re-engagement Drip';
      default:
        return '📞 Call & Follow-Up';
    }
  }

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    // Parse tags safely from string or list
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = List<String>.from(json['tags'].map((e) => e.toString()));
    } else if (json['tags'] is String && (json['tags'] as String).isNotEmpty) {
      parsedTags = (json['tags'] as String).split(',').map((e) => e.trim()).toList();
    }

    final rawStage = (json['mobile_stage'] ?? json['stage'] ?? json['status'] ?? 'new').toString().trim().toLowerCase();
    final normalizedStage = () {
      if (rawStage == 'inquiry' || rawStage == 'inquiries' || rawStage.isEmpty) return 'new';
      if (rawStage == 'proposal' || rawStage == 'quotation_sent') return 'quote_sent';
      if (rawStage == 'negotiation') return 'follow_up';
      if (rawStage == 'trip_completed') return 'completed';
      return rawStage;
    }();

    return LeadModel(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['customer_name'] ?? 'Prospective Traveler').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      destination: (json['destination'] ?? 'Varanasi').toString(),
      companyOrCity: (json['company'] ?? json['city'] ?? json['destination'] ?? 'Varanasi').toString(),
      pax: int.tryParse(json['pax']?.toString() ?? '2') ?? 2,
      budget: json['deal_value'] != null ? '₹${json['deal_value']}' : (json['budget']?.toString() ?? ''),
      stage: normalizedStage,
      source: (json['source_channel'] ?? json['source'] ?? 'website_chat').toString(),
      stickyAgent: (json['owner'] ?? json['sticky_agent'] ?? json['assigned_to'] ?? json['assigned_manager'] ?? '').toString().trim(),
      score: int.tryParse(json['score']?.toString() ?? '65') ?? 65,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastContactAt: json['last_contact_at'] != null
          ? DateTime.tryParse(json['last_contact_at'].toString())
          : null,
      nextFollowUpAt: json['next_follow_up_at'] != null
          ? DateTime.tryParse(json['next_follow_up_at'].toString())
          : null,
      tags: parsedTags,
      notes: (json['notes'] is List)
          ? List<String>.from(json['notes'].map((e) => e.toString()))
          : [],
      lastChatSummary: (json['last_chat_summary'] ?? json['requirements'] ?? json['last_message'] ?? json['reason'])?.toString(),
    );
  }

  double get dealValue {
    if (budget.isEmpty) return 0.0;
    final clean = budget.replaceAll(RegExp(r'[^0-9.]'), '');
    final parsed = double.tryParse(clean);
    return (parsed != null && parsed > 0) ? parsed : 0.0;
  }

  double get estimatedDealValue => dealValue > 0 ? dealValue : (pax > 0 ? pax : 2) * 12000.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'destination': destination,
      'companyOrCity': companyOrCity,
      'pax': pax,
      'budget': budget,
      'stage': stage,
      'source': source,
      'sticky_agent': stickyAgent,
      'score': score,
      'created_at': createdAt.toIso8601String(),
      'last_contact_at': lastContactAt?.toIso8601String(),
      'next_follow_up_at': nextFollowUpAt?.toIso8601String(),
      'tags': tags,
      'notes': notes,
      'last_chat_summary': lastChatSummary,
    };
  }

  LeadModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? destination,
    String? companyOrCity,
    int? pax,
    String? budget,
    String? stage,
    String? source,
    String? stickyAgent,
    int? score,
    DateTime? lastContactAt,
    DateTime? nextFollowUpAt,
    List<String>? tags,
    List<String>? notes,
    String? lastChatSummary,
  }) {
    return LeadModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      destination: destination ?? this.destination,
      companyOrCity: companyOrCity ?? this.companyOrCity,
      pax: pax ?? this.pax,
      budget: budget ?? this.budget,
      stage: stage ?? this.stage,
      source: source ?? this.source,
      stickyAgent: stickyAgent ?? this.stickyAgent,
      score: score ?? this.score,
      createdAt: createdAt,
      lastContactAt: lastContactAt ?? this.lastContactAt,
      nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      lastChatSummary: lastChatSummary ?? this.lastChatSummary,
    );
  }
}
