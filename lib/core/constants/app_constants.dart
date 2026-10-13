class AppConstants {
  static const String appName = 'X-Agents';
  static const String appFullName = 'X-Agents';
  static const String appVersion = '1.0.0 Pro';
  static const String appTagline =
      'Intelligent Telephony, CRM & AI Agent Engine';

  // Production WordPress REST Endpoints
  static const String defaultApiBaseUrl =
      'https://tripcosmos.co/wp-json/tc-agents/v1';
  static const String defaultMobileToken = 'a9P3cHjoyDq5Fkm0ucODllxnuuy35rXJ';

  // Primary Free Hardware Bridge
  static const String officeJioPhone = '+919336116210';
  static const String officeJioDisplay = '+91 93361 16210 (Jio 5G Master)';
  static const String officeWhatsAppNumber = '919336116210';

  // RAG Bot Details
  static const String localRagBotId = '155464';
  static const String localRagBotName =
      'TripCosmos AI Brain (Varanasi/Pilgrimage RAG)';

  // Configurable Travel Pipeline Stages (Matching Benchmark Spec)
  static const List<String> pipelineStages = [
    'all',
    'new',
    'contacted',
    'requirement_pending',
    'qualified',
    'quote_sent',
    'follow_up',
    'advance_received',
    'won',
    'traveling',
    'completed',
    'lost',
  ];

  static const List<Map<String, dynamic>> travelPipelineStages = [
    {'id': 'all', 'label': 'All Leads', 'color': 0xFF3B82F6},
    {'id': 'new', 'label': 'New Inquiry', 'color': 0xFFF59E0B},
    {'id': 'contacted', 'label': 'Contacted', 'color': 0xFF3B82F6},
    {'id': 'requirement_pending', 'label': 'Requirement Pending', 'color': 0xFF8B5CF6},
    {'id': 'qualified', 'label': 'Customer Interested', 'color': 0xFF10B981},
    {'id': 'quote_sent', 'label': 'Quotation Sent', 'color': 0xFF06B6D4},
    {'id': 'follow_up', 'label': 'Follow-up', 'color': 0xFFEC4899},
    {'id': 'advance_received', 'label': 'Advance Received', 'color': 0xFF6366F1},
    {'id': 'won', 'label': 'Booking Confirmed', 'color': 0xFF10B981},
    {'id': 'traveling', 'label': 'Traveling', 'color': 0xFF14B8A6},
    {'id': 'completed', 'label': 'Trip Completed', 'color': 0xFF059669},
    {'id': 'lost', 'label': 'Lost', 'color': 0xFFEF4444},
  ];

  // Team Telecallers / Lead Owners
  static const List<Map<String, String>> teamMembers = [
    {'name': 'Santosh Yadav', 'initials': 'SY', 'role': 'Senior Sales Specialist', 'phone': '+91 93361 16210'},
    {'name': 'Ajay Verma', 'initials': 'AV', 'role': 'Inbound Lead Manager', 'phone': '+91 98190 55432'},
    {'name': 'Nishkarsh Pushpam', 'initials': 'NP', 'role': 'Operations & Booking Lead', 'phone': '+91 74640 42539'},
    {'name': 'TripCosmos Admin', 'initials': 'TC', 'role': 'Master SuperAdmin', 'phone': '+91 93361 16210'},
  ];

  // Tour Circuits for 1-Tap Post-Call Actions
  static const List<Map<String, String>> quickBrochures = [
    {
      'id': 'varanasi_3d',
      'title': 'Kashi Vishwanath & Ganga Aarti (3D/2N)',
      'badge': 'Best Seller',
      'price': '₹12,499',
      'summary':
          'VIP Sugam Darshan, Reserved Aarti Boat, Deluxe Hotel, AC Cab.',
    },
    {
      'id': 'ayodhya_kashi_4d',
      'title': 'Varanasi - Ayodhya - Prayagraj (4D/3N)',
      'badge': 'High Intent',
      'price': '₹19,800',
      'summary':
          'Ram Mandir VIP entry, Sangam Snan, Kashi Darshan & all transfers.',
    },
    {
      'id': 'bodhgaya_circuit',
      'title': 'Kashi - Gaya - Bodhgaya Circuit (4D/3N)',
      'badge': 'Spiritual',
      'price': '₹18,500',
      'summary':
          'Pind Daan rituals support, Mahabodhi Temple, AC Innova Crysta.',
    },
    {
      'id': 'cab_outstation',
      'title': 'Varanasi Outstation Cab Rate Card',
      'badge': 'Tariff Sheet',
      'price': 'From ₹11/km',
      'summary':
          'Swift Dzire (₹11/km), Innova Crysta (₹17/km), Tempo 12S (₹24/km).',
    },
  ];
}
