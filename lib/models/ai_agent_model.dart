class AgentSkill {
  final String id;
  final String name;
  final String description;
  final String category; // 'pricing', 'darshan', 'logistics', 'sales', 'guardrail'
  final bool isEnabled;
  final Map<String, dynamic> config;

  const AgentSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.isEnabled = true,
    this.config = const {},
  });

  AgentSkill copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    bool? isEnabled,
    Map<String, dynamic>? config,
  }) {
    return AgentSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isEnabled: isEnabled ?? this.isEnabled,
      config: config ?? this.config,
    );
  }

  factory AgentSkill.fromJson(Map<String, dynamic> json) {
    return AgentSkill(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'sales',
      isEnabled: json['is_enabled'] != false,
      config: json['config'] is Map ? Map<String, dynamic>.from(json['config']) : {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'is_enabled': isEnabled,
    'config': config,
  };
}

class AiAgentPersona {
  final String id;
  final String name;
  final String title;
  final String avatarUrl;
  final String voiceName; // e.g. 'Aditi (Hindi-English Warm)', 'Raghav (Authoritative Hindi)', 'Aarav (Friendly Courteous)'
  final String tone; // 'Devotional & Courteous', 'Fast B2B Commercial', 'Concierge Luxury'
  final List<String> circuits; // e.g. ['Varanasi', 'Ayodhya', 'Prayagraj']
  final bool canChatWhatsapp;
  final bool canMakeVoiceCalls;
  final bool canTakeInbound;
  final bool isAutonomous; // if false, acts as copilot (suggests replies)
  final String systemPrompt;
  final List<AgentSkill> skills;
  final int conversationsCount;
  final int dealsClosed;
  final double conversionRate;
  final bool isPublished;

  const AiAgentPersona({
    required this.id,
    required this.name,
    required this.title,
    this.avatarUrl = '',
    required this.voiceName,
    required this.tone,
    required this.circuits,
    this.canChatWhatsapp = true,
    this.canMakeVoiceCalls = true,
    this.canTakeInbound = true,
    this.isAutonomous = true,
    required this.systemPrompt,
    required this.skills,
    this.conversationsCount = 0,
    this.dealsClosed = 0,
    this.conversionRate = 0.0,
    this.isPublished = true,
  });

  AiAgentPersona copyWith({
    String? id,
    String? name,
    String? title,
    String? avatarUrl,
    String? voiceName,
    String? tone,
    List<String>? circuits,
    bool? canChatWhatsapp,
    bool? canMakeVoiceCalls,
    bool? canTakeInbound,
    bool? isAutonomous,
    String? systemPrompt,
    List<AgentSkill>? skills,
    int? conversationsCount,
    int? dealsClosed,
    double? conversionRate,
    bool? isPublished,
  }) {
    return AiAgentPersona(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      voiceName: voiceName ?? this.voiceName,
      tone: tone ?? this.tone,
      circuits: circuits ?? this.circuits,
      canChatWhatsapp: canChatWhatsapp ?? this.canChatWhatsapp,
      canMakeVoiceCalls: canMakeVoiceCalls ?? this.canMakeVoiceCalls,
      canTakeInbound: canTakeInbound ?? this.canTakeInbound,
      isAutonomous: isAutonomous ?? this.isAutonomous,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      skills: skills ?? this.skills,
      conversationsCount: conversationsCount ?? this.conversationsCount,
      dealsClosed: dealsClosed ?? this.dealsClosed,
      conversionRate: conversionRate ?? this.conversionRate,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  factory AiAgentPersona.fromJson(Map<String, dynamic> json) {
    return AiAgentPersona(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? 'AI Sales Specialist',
      avatarUrl: json['avatar_url']?.toString() ?? '',
      voiceName: json['voice_name']?.toString() ?? 'Aarav (Warm Hindi/English)',
      tone: json['tone']?.toString() ?? 'Courteous & Helpful',
      circuits: json['circuits'] is List
          ? List<String>.from(json['circuits'].map((e) => e.toString()))
          : ['Varanasi', 'Ayodhya'],
      canChatWhatsapp: json['can_chat_whatsapp'] != false,
      canMakeVoiceCalls: json['can_make_voice_calls'] != false,
      canTakeInbound: json['can_take_inbound'] != false,
      isAutonomous: json['is_autonomous'] != false,
      systemPrompt: json['system_prompt']?.toString() ?? '',
      skills: json['skills'] is List
          ? (json['skills'] as List).map((s) => AgentSkill.fromJson(Map<String, dynamic>.from(s))).toList()
          : [],
      conversationsCount: (json['conversations_count'] as num?)?.toInt() ?? 0,
      dealsClosed: (json['deals_closed'] as num?)?.toInt() ?? 0,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
      isPublished: json['is_published'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'avatar_url': avatarUrl,
    'voice_name': voiceName,
    'tone': tone,
    'circuits': circuits,
    'can_chat_whatsapp': canChatWhatsapp,
    'can_make_voice_calls': canMakeVoiceCalls,
    'can_take_inbound': canTakeInbound,
    'is_autonomous': isAutonomous,
    'system_prompt': systemPrompt,
    'skills': skills.map((s) => s.toJson()).toList(),
    'conversations_count': conversationsCount,
    'deals_closed': dealsClosed,
    'conversion_rate': conversionRate,
    'is_published': isPublished,
  };

  /// Default production travel agency personas
  static List<AiAgentPersona> defaultTravelPersonas() {
    return [
      AiAgentPersona(
        id: 'agent_aditi_sales_copilot',
        name: 'Aditi AI',
        title: 'Senior Sales AI Co-Pilot & Tour Closer',
        voiceName: 'Aditi (Hindi-English Warm & Devotional)',
        tone: 'Devotional, Respectful, Persuasive & Transparent',
        circuits: const ['Varanasi', 'Ayodhya', 'Prayagraj', 'Bodhgaya', 'Chitrakoot'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: true,
        canTakeInbound: true,
        isAutonomous: true,
        conversationsCount: 384,
        dealsClosed: 112,
        conversionRate: 29.2,
        isPublished: true,
        systemPrompt:
            'You are Aditi AI, Senior AI Sales Specialist and dedicated co-pilot at TripCosmos.co (Varanasi HQ). Greet guests with warm Indian hospitality ("Namaste ji 🙏", "Har Har Mahadev"). You are thoroughly trained in all TripCosmos tour circuits (Varanasi 3D/2N Kashi Darshan from ₹14,500, Ayodhya 2D/1N Ram Janmabhoomi from ₹9,800, Prayagraj Sangam excursion from ₹4,800, and Kashi-Ayodhya-Prayagraj 4D/3N Golden Circuit from ₹22,500). Provide exact fleet tariffs (Sedan ₹11/km, Innova Crysta ₹17/km, Tempo Traveller ₹24/km), VIP Sugam passes (₹300), and Dashashwamedh evening Bajra boat reservations. Always collect traveler phone/WhatsApp and dates, provide transparent inclusions, and seamlessly alert the human sales manager for custom negotiations.',
        skills: [
          const AgentSkill(
            id: 'skill_pkg_pricing_engine',
            name: 'Complete Tour Package Pricing Engine',
            description: 'Quotes exact retail and B2B DMC net pricing for Varanasi, Ayodhya, Prayagraj, Bodhgaya circuits with hotel tiers.',
            category: 'pricing',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_vip_darshan_boat',
            name: 'VIP Darshan & Bajra Boat Reservations',
            description: 'Books Kashi Vishwanath Sugam Darshan passes, Assi morning sunrise boat, and Dashashwamedh evening Aarti Bajra seats.',
            category: 'darshan',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_fleet_calculator',
            name: 'Dynamic Fleet & Outstation Fare Engine',
            description: 'Calculates instant per-km and flat quotes for Swift Dzire (₹11/km), Crysta (₹17/km), and Tempo Traveller (₹24/km).',
            category: 'pricing',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_whatsapp_pdf_quote',
            name: '1-Tap WhatsApp Itinerary & Quote Dispatch',
            description: 'Generates branded PDF day-wise itineraries with cost breakdown and dispatches to customer WhatsApp in under 5 seconds.',
            category: 'sales',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_human_co_pilot_handoff',
            name: 'Human Co-Pilot Handoff & Escalation',
            description: 'Instantly alerts assigned human sales specialist when traveler requests custom discount or human phone consultation.',
            category: 'guardrail',
            isEnabled: true,
          ),
        ],
      ),
      AiAgentPersona(
        id: 'agent_aarav_kashi',
        name: 'Aarav Sharma',
        title: 'Kashi Pilgrimage & VIP Desk Specialist',
        voiceName: 'Aarav (Warm Devotional Hindi-English)',
        tone: 'Devotional, Respectful & Prompt (Bilingual)',
        circuits: const ['Varanasi', 'Ayodhya', 'Prayagraj'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: true,
        canTakeInbound: true,
        isAutonomous: true,
        conversationsCount: 142,
        dealsClosed: 38,
        conversionRate: 26.8,
        isPublished: true,
        systemPrompt:
            'You are Aarav Sharma, senior pilgrimage specialist at TripCosmos.co Varanasi. Greet guests with "Namaste ji 🙏". You specialize in Kashi Vishwanath Sugam Darshan passes, Dashashwamedh evening Bajra boat rides, and Kashi-Ayodhya-Prayagraj 4D/3N and 5D/4N packages. Keep answers concise, highly respectful, and always ask for travel dates and group size to send the exact quote.',
        skills: [
          const AgentSkill(
            id: 'skill_vip_darshan',
            name: 'VIP Sugam Darshan Quota Guidance',
            description: 'Provides exact protocol, ticket rates (₹300 Sugam, ₹500 Mangla Aarti), entry gates, and dress code for Kashi Vishwanath.',
            category: 'darshan',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_bajra_boat',
            name: 'Dashashwamedh Bajra Boat Booking',
            description: 'Explains wooden bajra vs motor boat tariffs, reserved seats for Ganga Aarti, and net rate allocation.',
            category: 'pricing',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_itinerary_customizer',
            name: 'Day-Wise Itinerary Customizer',
            description: 'Generates day-by-day sightseeing plan including Sarnath, Manikarnika Ghat, and Ram Janmabhoomi.',
            category: 'sales',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_human_escalation',
            name: 'Human Rep Handover Guardrail',
            description: 'Instantly alerts assigned human manager if customer expresses price grievance or requests human agent.',
            category: 'guardrail',
            isEnabled: true,
          ),
        ],
      ),
      AiAgentPersona(
        id: 'agent_priya_b2b',
        name: 'Priya Singhania',
        title: 'B2B Travel Agent & DMC Closer',
        voiceName: 'Priya (Corporate Crisp Hindi-English)',
        tone: 'Professional, Fast, Margin-Focused',
        circuits: const ['All UP Circuits', 'Dev Deepawali 2026', 'Mahakumbh'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: true,
        canTakeInbound: false,
        isAutonomous: true,
        conversationsCount: 89,
        dealsClosed: 24,
        conversionRate: 31.5,
        isPublished: true,
        systemPrompt:
            'You are Priya Singhania, Head of B2B DMC Partnerships at TripCosmos.co. You interact with travel agents from Mumbai, Gujarat, Delhi, and Kolkata. Speak in business-friendly terms. Share wholesale net tariffs with protected margins, fleet details (Innova Crysta, Urbania), and boat allocations. Always verify their agency name and GST.',
        skills: [
          const AgentSkill(
            id: 'skill_b2b_net_rates',
            name: 'B2B DMC Wholesale Tariff Engine',
            description: 'Quotes confidential net rates with agent markup margins for packages and transport.',
            category: 'pricing',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_dev_deepawali_alloc',
            name: 'Dev Deepawali 2026 Inventory Lock',
            description: 'Manages advance seat blocks on Dashashwamedh double-deck Bajras and 4-star hotel allotments.',
            category: 'sales',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_gst_invoice',
            name: 'B2B GST Billing & Credit Terms',
            description: 'Explains 5% GST on tour packages, billing formalities, and advance deposit requirements.',
            category: 'sales',
            isEnabled: true,
          ),
        ],
      ),
      AiAgentPersona(
        id: 'agent_vikram_cab',
        name: 'Vikram Rathore',
        title: 'Outstation Fleet & Cab Desk',
        voiceName: 'Vikram (Fast Ground-Level Hindi)',
        tone: 'Crisp, Reliable & Transparent',
        circuits: const ['Varanasi Airport', 'Ayodhya Highway', 'Prayagraj Sangam', 'Lucknow'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: true,
        canTakeInbound: true,
        isAutonomous: true,
        conversationsCount: 215,
        dealsClosed: 71,
        conversionRate: 33.0,
        isPublished: true,
        systemPrompt:
            'You are Vikram from the TripCosmos Cab Desk. Provide quick, accurate per-km and flat-fare quotes for Airport Pickups (₹950 Dzire, ₹1500 Innova) and Outstation round trips (Varanasi-Ayodhya ₹4200 sedan, ₹6200 Innova). Confirm toll, state taxes, and night allowance transparency.',
        skills: [
          const AgentSkill(
            id: 'skill_dynamic_cab_calc',
            name: 'Dynamic Outstation & City Fare Engine',
            description: 'Calculates exact kilometer, toll, parking, and driver allowances for Sedan, Innova, Crysta, and Tempo.',
            category: 'pricing',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_driver_dispatch',
            name: 'Driver & Vehicle Dispatch Alerts',
            description: 'Automates driver name, mobile number, vehicle number, and live tracking dispatch over WhatsApp/SMS.',
            category: 'logistics',
            isEnabled: true,
          ),
        ],
      ),
    ];
  }
}
