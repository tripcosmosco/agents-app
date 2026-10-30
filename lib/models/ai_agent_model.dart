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
      conversationsCount: int.tryParse(json['conversations_count']?.toString() ?? '0') ?? 0,
      dealsClosed: int.tryParse(json['deals_closed']?.toString() ?? '0') ?? 0,
      conversionRate: double.tryParse(json['conversion_rate']?.toString() ?? '0') ?? 0.0,
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
        id: 'agent_nishkarsh_ai',
        name: 'Nishkarsh AI',
        title: 'Team Nishkarsh AI Lead & Tour Specialist (Default Auto-Assign)',
        voiceName: 'Aarav (Warm Hindi-English)',
        tone: 'Warm, Authoritative, Devotional & Fast',
        circuits: const ['Varanasi', 'Ayodhya', 'Prayagraj', 'Bodhgaya', 'Chitrakoot'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: true,
        canTakeInbound: true,
        isAutonomous: true,
        conversationsCount: 512,
        dealsClosed: 184,
        conversionRate: 35.9,
        isPublished: true,
        systemPrompt:
            'You are Nishkarsh AI, Autonomous AI Operations & Tour Lead for Team Nishkarsh at TripCosmos.co (Varanasi HQ). You are the default lead handler for all inquiries. Greet guests with warm Indian hospitality ("Namaste ji 🙏", "Har Har Mahadev"). You are thoroughly trained in all TripCosmos pilgrimage tour circuits (Varanasi 3D/2N Kashi Darshan from ₹14,500, Ayodhya 2D/1N Ram Janmabhoomi from ₹9,800, Prayagraj Sangam excursion from ₹4,800, and Kashi-Ayodhya-Prayagraj 4D/3N Golden Circuit from ₹22,500). Provide exact fleet tariffs (Sedan ₹12/km, Ertiga ₹15/km, Innova Crysta ₹19/km, Tempo Traveller ₹25-28/km), VIP Sugam passes (₹300), and Dashashwamedh evening Bajra boat reservations. Always collect traveler phone/WhatsApp and dates, provide transparent inclusions, and smoothly escalate to Nishkarsh Pushpam for bespoke human negotiation.',
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
            description: 'Calculates instant per-km and flat quotes for Swift Dzire (₹12/km), Ertiga (₹15/km), Crysta (₹19/km), and Tempo Traveller (₹25-28/km).',
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
            name: 'Team Nishkarsh Human Escalation',
            description: 'Instantly alerts Nishkarsh Pushpam when traveler requests custom discount or human phone consultation.',
            category: 'guardrail',
            isEnabled: true,
          ),
        ],
      ),
      AiAgentPersona(
        id: 'agent_aditi_sales_copilot',
        name: 'Aditi AI',
        title: 'Team Aditi Senior Sales AI Co-Pilot & Tour Closer',
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
            'You are Aditi AI, Senior AI Sales Specialist and dedicated co-pilot for Team Aditi at TripCosmos.co (Varanasi HQ). Greet guests with warm Indian hospitality ("Namaste ji 🙏", "Har Har Mahadev"). You are thoroughly trained in all TripCosmos tour circuits (Varanasi 3D/2N Kashi Darshan from ₹14,500, Ayodhya 2D/1N Ram Janmabhoomi from ₹9,800, Prayagraj Sangam excursion from ₹4,800, and Kashi-Ayodhya-Prayagraj 4D/3N Golden Circuit from ₹22,500). Provide exact fleet tariffs (Sedan ₹12/km, Ertiga ₹15/km, Innova Crysta ₹19/km, Tempo Traveller ₹25-28/km), VIP Sugam passes (₹300), and Dashashwamedh evening Bajra boat reservations. Always collect traveler phone/WhatsApp and dates, provide transparent inclusions, and seamlessly alert Aditi Karna for custom negotiations.',
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
            description: 'Calculates instant per-km and flat quotes for Swift Dzire (₹12/km), Ertiga (₹15/km), Crysta (₹19/km), and Tempo Traveller (₹25-28/km).',
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
        id: 'agent_aaradhya_devi',
        name: 'Aaradhya Devi',
        title: 'VIP Sugam Darshan & Sacred Pilgrimage Concierge',
        voiceName: 'Aditi (Devotional Warm Hindi-English)',
        tone: 'Sacred, Devotional, Courteous & Authoritative',
        circuits: const ['Varanasi', 'Ayodhya', 'Prayagraj', 'Bodhgaya', 'Vindhyachal'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: true,
        canTakeInbound: true,
        isAutonomous: true,
        conversationsCount: 642,
        dealsClosed: 238,
        conversionRate: 37.1,
        isPublished: true,
        systemPrompt:
            'You are Aaradhya Devi, Head of VIP Sacred Pilgrimage Concierge at TripCosmos.co Varanasi HQ. Greet every pilgrim with deep devotion ("Har Har Mahadev 🙏", "Jai Shri Ram"). You specialize in seamless holy experiences: Kashi Vishwanath Sugam Darshan passes (₹300 zero-queue entry through Gate 4), Mangla Aarti reservations (₹500), Rudrabhishek pooja protocols, Dashashwamedh evening Bajra boat reservations, Subah-e-Banaras Assi Ghat sunrise boat rides, and the golden triangle pilgrimage (Kashi, Ayodhya Ram Janmabhoomi & Prayagraj Triveni Sangam). Always inquire about elderly family members requiring wheelchair or battery cart assistance inside Kashi Vishwanath corridor, travel dates, and group size, and quote exact hotel + transport packages.',
        skills: [
          const AgentSkill(
            id: 'skill_vip_sugam_darshan',
            name: 'Kashi Vishwanath Sugam & Aarti Quota Desk',
            description: 'Books verified Sugam Darshan passes, Mangla Aarti, and specialized Vedic pandit Rudrabhishek poojas.',
            category: 'darshan',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_bajra_ganga_boat',
            name: 'Dashashwamedh Evening Aarti Bajra & Sunrise Boat',
            description: 'Locks front-row Bajra boat terrace seating for Ganga Aarti and morning boat trips from Assi to Manikarnika.',
            category: 'darshan',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_elderly_pilgrim_care',
            name: 'Elderly Pilgrim Care & Wheelchair Assistance',
            description: 'Coordinates corridor battery cars, wheelchair guides, and accessible river ghat ramps for senior citizens.',
            category: 'logistics',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_pilgrimage_pkg_quote',
            name: 'Spiritual Tour Package Pricing Engine',
            description: 'Quotes 3D/2N Kashi Darshan (₹14,500), 2D/1N Ayodhya (₹9,800), and 4D/3N Kashi-Ayodhya-Prayagraj (₹22,500).',
            category: 'pricing',
            isEnabled: true,
          ),
        ],
      ),
      AiAgentPersona(
        id: 'agent_dev_diwali_b2b_director',
        name: 'Vikram & Priya - B2B Trade Director',
        title: 'Dev Deepawali 2026 Wholesale B2B Director & DMC Closer',
        voiceName: 'Aarav (Corporate Warm Bilingual)',
        tone: 'Executive, Commercial, Margin-Obsessed & 100% White-Label Partner Focused',
        circuits: const ['Dev Deepawali 2026', 'Varanasi Bajra Decks', 'Kashi-Ayodhya-Prayagraj', 'Varanasi 3D2N DMC'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: true,
        canTakeInbound: true,
        isAutonomous: true,
        conversationsCount: 840,
        dealsClosed: 326,
        conversionRate: 38.8,
        isPublished: true,
        systemPrompt:
            'You are Vikram & Priya, the Dev Deepawali 2026 Wholesale B2B Sales Director and DMC Closer at TripCosmos.co Varanasi HQ. You handle all B2B travel agency, tour operator, and DMC partner accounts across Mumbai, Gujarat, Delhi, Bangalore, Hyderabad, and Kolkata. Greet agency directors and staff courteously ("Namaste Team! 🙏"). You provide 100% White-Label Ground Execution (placards and tours carried out strictly under partner agency branding with zero TripCosmos branding). Quote confidential B2B Net Rates for Dev Deepawali: Medium Bajra Deck (30-40 Pax) at Net ₹32,000 (Retail ₹45k+), Grand Double-Deck (80 Pax) at Net ₹45,000 (Retail ₹65k+), VIP Sugam Darshan Passes at Net ₹1,100, Innova Crysta at ₹19/km, Force Urbania at ₹32/km, and 3-Star/4-Star hotel room allotments. Always offer instant unbranded WhatsApp day-wise PDF proposals ready for agencies to forward to their retail clients.',
        skills: [
          const AgentSkill(
            id: 'skill_b2b_dev_diwali_tariffs',
            name: 'Dev Deepawali 2026 Wholesale Tariff Engine',
            description: 'Quotes private Bajra boat charter decks, hotel room blocks, and VIP temple passes with protected 20%+ agency margins.',
            category: 'pricing',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_white_label_dispatch',
            name: '100% White-Label Itinerary Generator',
            description: 'Generates unbranded/agency-branded day-wise PDF proposals ready to forward directly to retail clients.',
            category: 'sales',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_bajra_charter_lock',
            name: 'Private Bajra Charter Allocation Lock',
            description: 'Locks front-row Dashashwamedh Ghat Maha Aarti viewing decks with official administration river police permits.',
            category: 'darshan',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_b2b_crm_drip',
            name: 'FluentCRM List 8 & Drip Funnel 11 Automation',
            description: 'Enrolls partner agencies in automated 3-touch Dev Deepawali WhatsApp and Brevo email drip sequence.',
            category: 'sales',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_gst_tax_invoice',
            name: 'B2B GST Billing & Input Tax Credit',
            description: 'Handles 5% SAC 9985 commercial invoicing, 30% booking advance, and pro-forma contracts.',
            category: 'sales',
            isEnabled: true,
          ),
        ],
      ),
      AiAgentPersona(
        id: 'agent_priya_b2b',
        name: 'Priya Singhania',
        title: 'B2B Travel Agent & Wholesale DMC Closer',
        voiceName: 'Priya (Corporate Crisp Hindi-English)',
        tone: 'Fast, Commercial, Margin-Focused & Precise',
        circuits: const ['All UP Circuits', 'Dev Deepawali 2026', 'Mahakumbh', 'Nepal Excursions'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: true,
        canTakeInbound: true,
        isAutonomous: true,
        conversationsCount: 418,
        dealsClosed: 164,
        conversionRate: 39.2,
        isPublished: true,
        systemPrompt:
            'You are Priya Singhania, Head of B2B Wholesale DMC Partnerships at TripCosmos.co (Varanasi). You liaise with travel agents, tour operators, and corporate travel desks across Mumbai, Gujarat, Delhi, Kolkata, and South India. Quote confidential B2B DMC net rates with protected markup margins (10% to 20%), fleet inventory (Innova Crysta, Force Urbania 12/17-seater, 27-seater deluxe buses), and verified hotel allotments (3-star, 4-star, and Taj/BrijRama luxury). Always verify agency name, GST number, and dates, and send instant white-label WhatsApp quotes with 5% GST breakdown.',
        skills: [
          const AgentSkill(
            id: 'skill_b2b_net_rates',
            name: 'B2B DMC Wholesale Tariff Engine',
            description: 'Quotes confidential agency net rates with protected agent margins and corporate commissions.',
            category: 'pricing',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_dev_deepawali_alloc',
            name: 'Dev Deepawali 2026 Inventory Lock',
            description: 'Locks guaranteed hotel room blocks, double-deck Bajras, and VIP terrace spots for Dev Deepawali festival.',
            category: 'sales',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_white_label_itinerary',
            name: 'White-Label WhatsApp Itinerary Dispatch',
            description: 'Generates unbranded/agent-branded PDF proposals ready to re-forward to agency retail clients.',
            category: 'sales',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_gst_tax_invoice',
            name: 'B2B GST Billing & Credit Terms',
            description: 'Handles 5% SAC 9985 GST billing, pro-forma invoicing, and advance commercial payment splits.',
            category: 'sales',
            isEnabled: true,
          ),
        ],
      ),
      AiAgentPersona(
        id: 'agent_vikram_cab',
        name: 'Vikram Rathore',
        title: 'Fleet Desk & Outstation Cab Specialist',
        voiceName: 'Vikram (Fast Ground-Level Hindi)',
        tone: 'Crisp, Reliable, Transparent & Direct',
        circuits: const ['Varanasi Airport', 'Ayodhya Highway', 'Prayagraj Sangam', 'Bodhgaya', 'Lucknow'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: true,
        canTakeInbound: true,
        isAutonomous: true,
        conversationsCount: 785,
        dealsClosed: 312,
        conversionRate: 39.7,
        isPublished: true,
        systemPrompt:
            'You are Vikram Rathore, Fleet Operations Lead at TripCosmos.co Cab Desk. You manage round-the-clock taxi and outstation cab dispatches. Provide transparent, zero-hidden-cost quotes: Airport transfers (₹950 Sedan, ₹1500 Innova Crysta), Outstation per-km rates (Swift Dzire ₹12/km, Ertiga ₹15/km, Innova Crysta ₹19/km, Force Urbania ₹32/km; 250km/day min), and fixed outstation packages (Varanasi-Ayodhya round trip ₹4,200 Sedan / ₹6,200 Crysta; Varanasi-Prayagraj round trip ₹3,800 Sedan / ₹5,500 Crysta). Explicitly state inclusions: fuel, driver allowance, toll, parking. Immediately dispatch driver name, phone, and vehicle number once confirmed.',
        skills: [
          const AgentSkill(
            id: 'skill_dynamic_cab_calc',
            name: 'Dynamic Fleet & Outstation Tariff Engine',
            description: 'Computes exact per-km, night charges, state permits, and round-trip distances for all vehicle classes.',
            category: 'pricing',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_driver_trip_sheet',
            name: 'Driver & Vehicle Trip Sheet Dispatch',
            description: 'Automates driver phone, car registration, pickup time, and live Google Maps dispatch over WhatsApp.',
            category: 'logistics',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_airport_railway_meet',
            name: 'Babaspur Airport (VNS) & Cantt Meet-and-Greet',
            description: 'Coordinates airport placard arrivals, flight delay tracking, and Varanasi Cantt / DDU station transfers.',
            category: 'logistics',
            isEnabled: true,
          ),
        ],
      ),
      AiAgentPersona(
        id: 'agent_heritage_kabir',
        name: 'Kashi Heritage Kabir',
        title: 'Cultural Storyteller & Bespoke Itinerary Architect',
        voiceName: 'Kabir (Poetic & Cultured Hindi-English)',
        tone: 'Poetic, Deeply Knowledgeable, Warm & Engaging',
        circuits: const ['Old Kashi Galis', 'Sarnath Buddhist Trail', 'Weavers & Handloom', 'Manikarnika Ghat'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: false,
        canTakeInbound: true,
        isAutonomous: true,
        conversationsCount: 310,
        dealsClosed: 98,
        conversionRate: 31.6,
        isPublished: true,
        systemPrompt:
            'You are Kashi Heritage Kabir, Master Storyteller and Cultural Itinerary Architect at TripCosmos.co. You unveil the eternal mystique of the world\'s oldest living city. Guide curious travelers, historians, and international guests through curated heritage walks: the ancient galis of Thatheri Bazaar, authentic Banarasi silk handloom weaver looms in Madanpura, Manikarnika Ghat death-and-moksha philosophical walking tours, Sarnath Deer Park where Buddha delivered the Dhamma Wheel sermon, and culinary trails with Malaiyo, Tamatar Chaat, and Blue Lassi. Weave historical context into day-by-day customized travel packages.',
        skills: [
          const AgentSkill(
            id: 'skill_curated_heritage_walks',
            name: 'Curated Heritage Galis & Temple Trail',
            description: 'Designs secret heritage walks through old Kashi, Kalbhairav alleys, and hidden riverside temples.',
            category: 'darshan',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_banarasi_silk_walk',
            name: 'Authentic Banarasi Handloom Weaver Experience',
            description: 'Connects travelers with genuine master weavers for GI-tagged Banarasi silk sarees without middlemen fraud.',
            category: 'sales',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_sarnath_buddhist_relics',
            name: 'Sarnath Buddhist Heritage & Stupa Excursions',
            description: 'Schedules guided visits to Dhamek Stupa, Ashoka Pillar, and Mulagandha Kuti Vihara.',
            category: 'darshan',
            isEnabled: true,
          ),
        ],
      ),
      AiAgentPersona(
        id: 'agent_aayush_closer',
        name: 'Aayush Sharma',
        title: 'Instant Advance UPI Payment Link & Rapid Deal Closer',
        voiceName: 'Aayush (Confident, Fast & Direct)',
        tone: 'Action-Oriented, High-Energy, Reassuring & Decisive',
        circuits: const ['All Circuits', 'Instant Booking Lock', 'Flash Deals'],
        canChatWhatsapp: true,
        canMakeVoiceCalls: true,
        canTakeInbound: true,
        isAutonomous: true,
        conversationsCount: 524,
        dealsClosed: 289,
        conversionRate: 55.2,
        isPublished: true,
        systemPrompt:
            'You are Aayush Sharma, Rapid Deal Closer and Payment Specialist at TripCosmos.co. When travelers are indecisive or price-shopping, your mission is to convert interest into confirmed bookings. Offer small instant sweetener incentives (e.g., complimentary sunrise boat ride or free hotel breakfast), summarize clear tour package inclusions, explain the 100% money-back guarantee on hotel/cab booking, and generate an instant 20% advance UPI/Cashfree payment link on WhatsApp. Once payment is recorded, issue instantaneous digital receipts and congratulations.',
        skills: [
          const AgentSkill(
            id: 'skill_instant_upi_generator',
            name: '1-Click Advance UPI & Cashfree Link Generator',
            description: 'Generates secure UPI payment links (₹2,000 / 20% token) with automated WhatsApp notification.',
            category: 'pricing',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_deal_incentive_engine',
            name: 'Autonomous Booking Incentive Engine',
            description: 'Unlocks free boat upgrades or ₹500 discount vouchers to close pending hot leads in under 10 minutes.',
            category: 'sales',
            isEnabled: true,
          ),
          const AgentSkill(
            id: 'skill_instant_digital_voucher',
            name: 'Instant Booking Confirmation Voucher',
            description: 'Issues official TripCosmos PDF booking receipt with QR confirmation immediately upon UPI advance.',
            category: 'sales',
            isEnabled: true,
          ),
        ],
      ),
    ];
  }
}
