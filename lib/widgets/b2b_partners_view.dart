import 'tariff_pricing_manager_sheet.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../providers/call_provider.dart';
import '../providers/lead_provider.dart';
import '../providers/whatsapp_provider.dart';
import 'travel_quote_dialog.dart';
import 'whatsapp_team_chat_view.dart';

class B2bPartnersView extends StatefulWidget {
  final bool embedded;
  const B2bPartnersView({super.key, this.embedded = false});

  @override
  State<B2bPartnersView> createState() => _B2bPartnersViewState();
}

class _B2bPartnersViewState extends State<B2bPartnersView> {
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCity = 'All';
  String _selectedStatus = 'all'; // all, new, in_crm, contacted
  String _searchQuery = '';
  String _nextScheduledCity = 'Bengaluru';
  List<Map<String, dynamic>> _agencies = [];
  Map<String, dynamic> _counts = {'total': 0, 'new': 0, 'in_crm': 0, 'contacted': 0};

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  final List<String> _cities = [
    'All',
    'Varanasi',
    'Delhi',
    'Mumbai',
    'Ahmedabad',
    'Surat',
    'Bengaluru',
    'Hyderabad',
    'Kolkata',
    'Chennai',
    'Jaipur',
    'Lucknow',
    'Pune',
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedAgencies();
    _loadAgenciesFromServer();
  }

  Future<void> _loadCachedAgencies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('tc_cached_b2b_agencies_data');
      if (cachedJson != null && cachedJson.isNotEmpty && mounted) {
        final decoded = json.decode(cachedJson) as Map<String, dynamic>;
        final rawList = decoded['agencies'] as List<dynamic>? ?? [];
        if (rawList.isNotEmpty && _agencies.isEmpty) {
          setState(() {
            _agencies = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            if (decoded['counts'] is Map) {
              _counts = Map<String, dynamic>.from(decoded['counts'] as Map);
            }
            if (decoded['next_city'] != null) {
              _nextScheduledCity = decoded['next_city'].toString();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading cached B2B agencies: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _searchQuery = val.trim();
        });
        _loadAgenciesFromServer();
      }
    });
  }

  Future<void> _loadAgenciesFromServer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      if (_agencies.isEmpty) _errorMessage = null;
    });

    try {
      final apiService = Provider.of<LeadProvider>(context, listen: false).apiService;
      final res = await apiService.fetchB2bAgencies(
        search: _searchQuery,
        city: _selectedCity == 'All' ? '' : _selectedCity,
        status: _selectedStatus == 'all' ? '' : _selectedStatus,
        limit: 100,
      );

      if (res != null && mounted) {
        final rawList = res['agencies'] as List<dynamic>? ?? [];
        setState(() {
          _agencies = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _errorMessage = null;
          if (res['counts'] is Map) {
            _counts = Map<String, dynamic>.from(res['counts'] as Map);
          }
          if (res['next_city'] != null) {
            _nextScheduledCity = res['next_city'].toString();
          }
        });
        // Cache to local storage
        if (_searchQuery.isEmpty && _selectedCity == 'All' && _selectedStatus == 'all') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('tc_cached_b2b_agencies_data', json.encode(res));
        }
      } else if (mounted) {
        if (_agencies.isEmpty) {
          setState(() {
            _errorMessage = 'Unable to reach B2B database. Please verify server connection.';
          });
        }
      }
    } catch (e) {
      if (mounted && _agencies.isEmpty) {
        setState(() {
          _errorMessage = 'Connection error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // 1. INTELLIGENT AI B2B PITCH ASSISTANT
  // ==========================================
  void _showAiPitchModal(BuildContext context, Map<String, dynamic> agency) {
    final agencyId = int.tryParse(agency['id'].toString()) ?? 0;
    final name = (agency['name'] ?? 'Partner Agency').toString();
    final city = (agency['city'] ?? 'India').toString();
    final phone = (agency['phone'] ?? '').toString();

    int selectedArchetype = 0;
    final List<Map<String, String>> pitchArchetypes = [
      {
        'title': '🪔 Dev Deepawali 2026 VIP Inventory',
        'subtitle': 'Reserved Bajra Boats + VIP Sugam Darshan Passes',
        'template': '''Namaste $name Team! 🙏 Greetings from TripCosmos Varanasi.

Are your clients inquiring about *Dev Deepawali 2026 in Varanasi (Kartik Poornima)*?

As your verified on-ground Destination Management Company (DMC), we have pre-allocated ground inventory exclusively for our B2B travel partners:
• *Reserved Private Bajra Boats:* Prime Dashashwamedh Ghat Maha Aarti viewing decks (Zero line waiting)
• *VIP Sugam Darshan Passes:* Priority Kashi Vishwanath Temple entry via Gate 4
• *Dedicated AC Fleet:* Innova Crysta, Force Urbania & Tempo Travellers ($city pickup connections)
• *100% White-Label Execution:* Executed seamlessly under *your agency brand* with your client welcome placards

👉 *View 2N3D Dev Deepawali Itinerary:* https://tripcosmos.co/tour-packages/dev-deepawali-varanasi/

May we share our complete 2026 B2B Net Wholesale Tariff Sheet and Bajra Allotment slabs on this chat?''',
      },
      {
        'title': '🕉️ Kashi - Ayodhya - Prayagraj 4D3N Circuit',
        'subtitle': 'High-volume wholesale spiritual circuit with Ram Mandir VIP',
        'template': '''Namaste $name Team! 🙏 Greetings from TripCosmos Ground DMC.

We are handling premium ground operations for travel agencies in $city for the *Kashi - Ayodhya - Prayagraj (4D/3N) Spiritual Circuit*:
• *Kashi:* VIP Sugam Darshan & Exclusive Ganga Aarti Boat
• *Ayodhya:* Direct Darshan at Shri Ram Janmabhoomi & Saryu Aarti
• *Prayagraj:* Triveni Sangam Snan Boat & Hanuman Mandir
• *Ground Fleet:* Dedicated sanitized Innova Crysta / 17S Urbania with experienced pilot

💼 *B2B Net Wholesale Tariffs:*
• Standard (3★): ₹10,500 / pax net
• Deluxe (4★): ₹16,300 / pax net
(100% White-Label ground placard with your agency brand)

Shall I WhatsApp our detailed wholesale day-wise itinerary to your reservations team?''',
      },
      {
        'title': '🥗 Gujarat & Western India Pilgrim Groups',
        'subtitle': 'Jain / Satvik meals, wheelchair ghat assistance & senior-friendly',
        'template': '''Jai Jinendra / Pranam $name Team! 🙏

Greetings from TripCosmos Varanasi. We specialize in ground management for *Gujarat & Western India pilgrim groups* visiting Varanasi, Ayodhya, and Prayagraj:
• *Pure Satvik / Jain Meal Arrangements* across all stay and transit points
• *Senior Citizen Care:* E-rickshaw ghat access, wheelchair escorts & Gate 4 VIP darshan
• *Gujarati / Hindi Speaking Escorts* on ground from airport arrival to departure

We are offering special wholesale DMC rates for $city group departures. Can we send you our Gujarat Group Tariff Card?''',
      },
      {
        'title': '🚩 South India Temple Pilgrim Special',
        'subtitle': 'Tamil / Telugu / Kannada coordinators & South Indian catering',
        'template': '''Vanakkam / Namaskaram $name Team! 🙏

Greetings from TripCosmos Varanasi DMC. We offer specialized ground handling for South Indian temple pilgrimage groups to Varanasi - Rameswaram Pinda Daan, Kashi Vishwanath & Ayodhya:
• *South Indian Cuisine:* Authentic South Indian breakfast & meals available
• *Ritual Coordination:* Vedic purohits arranged for Ganga Pinda Daan, Tarpan & Sankalp
• *South Indian Speaking Tour Coordinators* throughout the tour

Would you like our B2B wholesale rates for your upcoming group departures?''',
      },
      {
        'title': '⏰ Touch 2 Scarcity Follow-Up (+48h)',
        'subtitle': 'Bajra boat scarcity alert & urgent block reminder',
        'template': '''Namaste $name Team! Following up regarding Dev Deepawali 2026 ground allotments in Varanasi.

Just an alert from our DMC Operations Desk:
Over 75% of Dashashwamedh Ghat private Bajra boat seats and 4★ riverfront hotel allocations for Nov 2026 are already blocked by our B2B partner network.

If you have confirmed client enquiries or pending groups from $city, please let us hold your required rooms and boat seats without immediate lock-in:
📞 *Direct Desk:* +91 93361 16210''',
      },
    ];

    final TextEditingController pitchTextCtrl =
        TextEditingController(text: pitchArchetypes[0]['template']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isLight = Theme.of(context).brightness == Brightness.light;
          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: const Color(0xFFF59E0B), width: isLight ? 2 : 1.5)),
              boxShadow: [
                if (isLight)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFBBF24), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI B2B Pitch Assistant • $name',
                              style: TextStyle(
                                color: isLight ? AppColors.lightTextPrimary : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Location: $city • Phone: $phone',
                              style: TextStyle(
                                color: isLight ? AppColors.lightTextSecondary : const Color(0xFF94A3B8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isLight ? AppColors.lightTextSecondary : Colors.white70),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                ),
                Divider(color: isLight ? AppColors.lightBorderSubtle : Colors.white12, height: 1),

                // Pitch Archetype Selector
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT AI PITCH ARCHETYPE:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isLight ? const Color(0xFFB45309) : const Color(0xFFFBBF24),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: pitchArchetypes.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final isSel = selectedArchetype == idx;
                            return ChoiceChip(
                              label: Text(
                                pitchArchetypes[idx]['title']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isSel
                                      ? Colors.white
                                      : (isLight ? const Color(0xFF334155) : Colors.white),
                                ),
                              ),
                              selected: isSel,
                              selectedColor: isLight ? const Color(0xFFB45309) : const Color(0xFFF59E0B),
                              backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                              side: BorderSide(
                                color: isSel
                                    ? Colors.transparent
                                    : (isLight ? const Color(0xFFCBD5E1) : Colors.transparent),
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    selectedArchetype = idx;
                                    pitchTextCtrl.text = pitchArchetypes[idx]['template']!;
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Pitch Editor & Preview (Guaranteed High Contrast in Light & Dark Mode)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0B132B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLight
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: pitchTextCtrl,
                        maxLines: null,
                        expands: true,
                        cursorColor: const Color(0xFFF59E0B),
                        style: TextStyle(
                          color: isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          fontSize: 12.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Edit WhatsApp pitch message...',
                          hintStyle: TextStyle(
                            color: isLight ? AppColors.lightTextMuted : Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Action Toolbar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: pitchTextCtrl.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ AI Pitch copied to clipboard!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF38BDF8)),
                      label: const Text('Copy', style: TextStyle(color: Color(0xFF38BDF8))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final msg = pitchTextCtrl.text.trim();
                          if (msg.isEmpty) return;

                          Navigator.pop(modalContext);
                          setState(() {
                            agency['status'] = 'contacted';
                          });

                          final leadProvider = Provider.of<LeadProvider>(context, listen: false);
                          final sent = await leadProvider.apiService.sendB2bPitch(
                            agencyId: agencyId,
                            customMessage: msg,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  sent
                                      ? '✓ AI B2B Pitch dispatched to $name on WhatsApp!'
                                      : '✓ B2B Pitch queued for $name ($phone)',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                            _loadAgenciesFromServer();
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Send via WhatsApp (Evolution API)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

  // ==========================================
  // 2. DYNAMIC B2B NET RATE CALCULATOR
  // ==========================================
  void _showB2bRateCalculatorModal(BuildContext context) {
    int pax = 6;
    String selectedCircuit = 'Varanasi 3D/2N Spiritual Essence';
    String hotelTier = '4★ Deluxe';
    String vehicleType = 'Innova Crysta AC';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setCalcState) {
          int basePricePerPax = 7100;
          if (selectedCircuit.contains('4D/3N')) {
            basePricePerPax = 10500;
          } else if (selectedCircuit.contains('Dev Deepawali')) {
            basePricePerPax = 18500;
          }

          int hotelMultiplier = hotelTier.startsWith('4★') ? 3500 : (hotelTier.startsWith('5★') ? 8500 : 0);
          int netWholesaleRate = basePricePerPax + hotelMultiplier;
          int totalNetInvoice = netWholesaleRate * pax;
          int recommendedRetailRate = (netWholesaleRate * 1.35).round();
          int travelAgentProfit = (recommendedRetailRate - netWholesaleRate) * pax;

          final calculationSummary = '''
🏢 *TRIPCOSMOS B2B NET WHOLESALE QUOTE*
────────────────────────────────────
📍 *Circuit:* $selectedCircuit
👥 *Group Size:* $pax Pax
🏨 *Accommodation:* $hotelTier
🚗 *Dedicated Transport:* $vehicleType (100% White-Label)

💰 *Wholesale DMC Net Rate:* ₹$netWholesaleRate / pax net
🧾 *Total Group Net Invoice:* ₹$totalNetInvoice
🏷️ *Recommended Client Retail:* ₹$recommendedRetailRate / pax
✨ *Your Agency Profit Margin:* ₹$travelAgentProfit
────────────────────────────────────
📞 *Ground Operations Desk:* +91 93361 16210
''';

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calculate_rounded, color: Color(0xFFFBBF24), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dynamic B2B Net Rate Calculator',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Wholesale DMC Tariffs & Agent Markup',
                        style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Tour Circuit', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCircuit,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'Varanasi 3D/2N Spiritual Essence', child: Text('Varanasi 3D/2N Spiritual Essence')),
                      DropdownMenuItem(value: 'Kashi - Ayodhya - Prayagraj 4D/3N Circuit', child: Text('Kashi - Ayodhya - Prayagraj 4D/3N')),
                      DropdownMenuItem(value: 'Dev Deepawali 2026 Special (Bajra + VIP)', child: Text('Dev Deepawali 2026 Special (Bajra + VIP)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setCalcState(() => selectedCircuit = val);
                    },
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hotel Category', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              initialValue: hotelTier,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: const InputDecoration(isDense: true),
                              items: const [
                                DropdownMenuItem(value: '3★ Standard', child: Text('3★ Standard')),
                                DropdownMenuItem(value: '4★ Deluxe', child: Text('4★ Deluxe')),
                                DropdownMenuItem(value: '5★ Luxury Palace', child: Text('5★ Luxury Palace')),
                              ],
                              onChanged: (val) {
                                if (val != null) setCalcState(() => hotelTier = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Group Pax Size', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<int>(
                              initialValue: pax,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: const InputDecoration(isDense: true),
                              items: [2, 4, 6, 12, 17, 26, 35]
                                  .map((p) => DropdownMenuItem(value: p, child: Text('$p Pax')))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setCalcState(() => pax = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Calculated Financial Metric Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Wholesale Net / Pax:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('₹$netWholesaleRate', style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w900, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Net Invoice:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('₹$totalNetInvoice', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recommended B2C Retail:', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                            Text('₹$recommendedRetailRate', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Agent Profit:', style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w700)),
                            Text('+₹$travelAgentProfit', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: calculationSummary));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Calculated B2B Net Quotation copied to clipboard!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Rate Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDevDiwaliCampaignDialog(BuildContext context) {
    String targetCity = _selectedCity == 'All' ? 'Mumbai' : _selectedCity;
    int limit = 10;
    bool forceSend = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFFFBBF24), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dev Deepawali 2026 B2B Campaign',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Automated WhatsApp + Email + Sequence Drip',
                      style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎯 Multi-Channel B2B Wholesale Outreach:',
                        style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• WhatsApp Pitch: Evolution API verified numbers\n• Wholesale Rate Card: Brevo responsive HTML\n• Sequence 6 Drip: Touch 2 (+48h) & Touch 3 (+96h)\n• CRM: Automatic FluentCRM List 8 & Tag sync',
                        style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Target City / Cluster', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: targetCity,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(isDense: true),
                  items: ['All', 'Mumbai', 'Ahmedabad', 'Surat', 'Delhi', 'Bengaluru', 'Kolkata', 'Hyderabad', 'Pune']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c == 'All' ? 'All Ingested Cities' : c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => targetCity = val);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Agencies per Batch', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    Text('$limit agencies', style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w800, fontSize: 12)),
                  ],
                ),
                Slider(
                  value: limit.toDouble(),
                  min: 1,
                  max: 25,
                  divisions: 24,
                  activeColor: const Color(0xFFF59E0B),
                  onChanged: (val) => setDialogState(() => limit = val.round()),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Force Send (Bypass Quiet Hours / Test Mode)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Sends immediately even outside 8:30 AM - 9:00 PM IST', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
                  value: forceSend,
                  activeTrackColor: const Color(0xFF10B981),
                  onChanged: (val) => setDialogState(() => forceSend = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                final api = Provider.of<LeadProvider>(context, listen: false).apiService;
                final res = await api.launchB2bBatchCampaign(
                  city: targetCity == 'All' ? '' : targetCity,
                  limit: limit,
                  force: forceSend,
                  ignoreQuietHours: forceSend,
                );
                await _loadAgenciesFromServer();
                if (context.mounted) {
                  final data = res?['data'] is Map ? res!['data'] as Map : res;
                  final dispatched = data?['dispatched'] ?? 0;
                  final msg = data?['message']?.toString();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg ?? '✓ Dev Deepawali B2B Campaign dispatched to $dispatched agencies!'),
                      backgroundColor: const Color(0xFF10B981),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Launch Campaign Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showB2bImporterDialog(BuildContext context) {
    final cityCtrl = TextEditingController(text: _nextScheduledCity);
    final rawCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: Color(0xFF38BDF8), size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'B2B Importer & FluentCRM Sync',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Two-Way FluentCRM List 8 & Funnel 11 Sync',
                style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    final api = Provider.of<LeadProvider>(context, listen: false).apiService;
                    final res = await api.syncAllB2bAgenciesToCrm();
                    await _loadAgenciesFromServer();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res?['message']?.toString() ?? '✓ Synced all B2B agencies with FluentCRM List 8!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Sync All with FluentCRM (List 8)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '2. Import Verified Agencies by City (Google Places + DMC Directory)',
                style: TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Target Indian City',
                        hintText: 'e.g. Mumbai, Ahmedabad, Surat, Delhi',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final c = cityCtrl.text.trim();
                      if (c.isEmpty) return;
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      final api = Provider.of<LeadProvider>(context, listen: false).apiService;
                      final res = await api.importB2bAgencies(city: c);
                      await _loadAgenciesFromServer();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res?['message']?.toString() ?? '✓ Imported $c agencies & synced to FluentCRM!'),
                            backgroundColor: const Color(0xFF2563EB),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Import'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    final api = Provider.of<LeadProvider>(context, listen: false).apiService;
                    final res = await api.importB2bAgencies(runScheduledNow: true);
                    await _loadAgenciesFromServer();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res?['message']?.toString() ?? '✓ Scheduled city rotation imported!'),
                          backgroundColor: const Color(0xFFD97706),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.schedule_send_rounded, size: 15, color: Color(0xFFFBBF24)),
                  label: Text(
                    'Run Scheduled Rotation Now (Next: $_nextScheduledCity)',
                    style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '3. Quick Paste Agencies (CSV / WhatsApp List)',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: rawCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Agency Name, City, +919876543210, email@agency.com',
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final raw = rawCtrl.text.trim();
                    if (raw.isEmpty) return;
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    final api = Provider.of<LeadProvider>(context, listen: false).apiService;
                    final res = await api.importB2bAgencies(rawList: raw);
                    await _loadAgenciesFromServer();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res?['message']?.toString() ?? '✓ Bulk agencies imported & synced to FluentCRM!'),
                          backgroundColor: const Color(0xFF8B5CF6),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 16),
                  label: const Text('Bulk Import Pasted Rows'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _showAddAgencyDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Ahmedabad');
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.business_rounded, color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 8),
            Text('Add B2B Travel Partner', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Agency Name *',
                  hintText: 'e.g. Navbharat Tours Pvt Ltd',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cityCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'City *',
                  hintText: 'e.g. Mumbai, Ahmedabad, Surat, Delhi',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'WhatsApp / Mobile *',
                  hintText: '+91 98200 11223',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Agency Email (for FluentCRM Drip)',
                  hintText: 'b2b@agency.com',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Office Area / Address',
                  hintText: 'e.g. CG Road, Ahmedabad',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty || phone.isEmpty) return;

              final city = cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : 'Mumbai';
              final email = emailCtrl.text.trim();
              final address = addressCtrl.text.trim();

              Navigator.pop(ctx);

              final api = Provider.of<LeadProvider>(context, listen: false).apiService;
              await api.addB2bAgency(
                name: name,
                city: city,
                phone: phone,
                email: email,
                address: address,
              );
              _loadAgenciesFromServer();
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Save Agency'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openAgencyWhatsAppChat(BuildContext context, Map<String, dynamic> agency) {
    final name = (agency['name'] ?? 'Partner Agency').toString();
    final phone = (agency['phone'] ?? '').toString();
    final city = (agency['city'] ?? 'India').toString();

    final wpProvider = Provider.of<WhatsAppProvider>(context, listen: false);
    final thread = wpProvider.openOrCreateAgencyThread(
      agencyName: name,
      phone: phone,
      city: city,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF0B132B),
          body: SafeArea(
            child: WhatsAppTeamChatView(
              thread: thread,
              onBack: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: AppColors.accentGold,
      onRefresh: _loadAgenciesFromServer,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 0. Intelligent Floating SliverAppBar (Scrolls away seamlessly, snaps back on scroll up)
          if (!widget.embedded)
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              elevation: 0,
              backgroundColor: isDark ? AppColors.surface : Colors.white,
              titleSpacing: 16,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hub_rounded, color: AppColors.accentGold, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'B2B Agency Network',
                              style: TextStyle(
                                color: AppColors.getTextPrimary(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${_counts['total'] ?? _agencies.length} Agencies',
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.accentGold),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Pan-India DMC & Wholesale Ground Tariffs',
                          style: TextStyle(
                            color: AppColors.getTextSecondary(context),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Dev Deepawali Campaign',
                  icon: const Icon(Icons.rocket_launch_rounded, color: Color(0xFFF59E0B), size: 19),
                  onPressed: () => _showDevDiwaliCampaignDialog(context),
                ),
                IconButton(
                  tooltip: 'Tariff Sheet',
                  icon: const Icon(Icons.receipt_long_rounded, color: AppColors.accentGold, size: 19),
                  onPressed: () => TariffPricingManagerSheet.show(context),
                ),
                IconButton(
                  tooltip: 'Net Margin Calculator',
                  icon: const Icon(Icons.calculate_rounded, color: Color(0xFF38BDF8), size: 19),
                  onPressed: () => _showB2bRateCalculatorModal(context),
                ),
                IconButton(
                  tooltip: 'Import / CRM Sync',
                  icon: const Icon(Icons.cloud_download_rounded, color: Color(0xFF818CF8), size: 19),
                  onPressed: () => _showB2bImporterDialog(context),
                ),
                IconButton(
                  tooltip: 'Add B2B Partner',
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF34D399), size: 20),
                  onPressed: () => _showAddAgencyDialog(context),
                ),
              ],
            ),

          // 1. Ultra-Compact Command & Search Strip (~68px total, fluid and non-intrusive)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Column(
                children: [
                  // Search Bar (Compact 34px)
                  SizedBox(
                    height: 34,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 11.5),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceCard : Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        hintText: 'Search agencies by name, city, or phone...',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.lightTextMuted, fontSize: 11),
                        prefixIcon: Icon(Icons.search, color: isDark ? AppColors.textMuted : AppColors.lightTextSecondary, size: 15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.lightBorderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.getAccentGold(context), width: 1.2),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: isDark ? Colors.white54 : AppColors.lightTextSecondary, size: 13),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Unified Filter Strip: Status Metrics + City Pills (Single Fast Horizontal Scroll)
                  SizedBox(
                    height: 27,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildMetricTile(
                          label: 'All',
                          value: '${_counts['total'] ?? _agencies.length}',
                          color: Colors.white,
                          icon: Icons.business_rounded,
                          onTap: () {
                            setState(() => _selectedStatus = 'all');
                            _loadAgenciesFromServer();
                          },
                          isSelected: _selectedStatus == 'all',
                        ),
                        const SizedBox(width: 5),
                        _buildMetricTile(
                          label: 'CRM Drip',
                          value: '${_counts['in_crm'] ?? 0}',
                          color: const Color(0xFF34D399),
                          icon: Icons.cloud_done_rounded,
                          onTap: () {
                            setState(() => _selectedStatus = 'in_crm');
                            _loadAgenciesFromServer();
                          },
                          isSelected: _selectedStatus == 'in_crm',
                        ),
                        const SizedBox(width: 5),
                        _buildMetricTile(
                          label: 'Pitched',
                          value: '${_counts['contacted'] ?? 0}',
                          color: const Color(0xFF38BDF8),
                          icon: Icons.send_rounded,
                          onTap: () {
                            setState(() => _selectedStatus = 'contacted');
                            _loadAgenciesFromServer();
                          },
                          isSelected: _selectedStatus == 'contacted',
                        ),
                        const SizedBox(width: 5),
                        _buildMetricTile(
                          label: 'New',
                          value: '${_counts['new'] ?? 0}',
                          color: const Color(0xFFFBBF24),
                          icon: Icons.fiber_new_rounded,
                          onTap: () {
                            setState(() => _selectedStatus = 'new');
                            _loadAgenciesFromServer();
                          },
                          isSelected: _selectedStatus == 'new',
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          width: 1,
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        ..._cities.map((city) {
                          final isSelected = _selectedCity.toLowerCase() == city.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: ChoiceChip(
                              label: Text(
                                city,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                              selected: isSelected,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                              selectedColor: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
                              backgroundColor: isDark ? AppColors.surfaceCard : const Color(0xFFF1F5F9),
                              side: BorderSide(
                                color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedCity = city;
                                  });
                                  _loadAgenciesFromServer();
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Agencies Feed or State Handling
          if (_isLoading && _agencies.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
            )
          else if (_errorMessage != null && _agencies.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: AppColors.errorRed, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.lightTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _loadAgenciesFromServer,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry Fetching'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_agencies.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_city_rounded, color: Colors.white24, size: 44),
                    const SizedBox(height: 10),
                    Text(
                      'No B2B agencies found for $_selectedCity.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap below to import verified DMC agencies for this market.',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showB2bImporterDialog(context),
                      icon: const Icon(Icons.cloud_download_rounded, size: 15),
                      label: Text('Import Agencies for $_selectedCity'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 90),
              sliver: SliverList.builder(
                itemCount: _agencies.length,
                itemBuilder: (ctx, idx) {
                  final agency = _agencies[idx];
                  final id = int.tryParse(agency['id'].toString()) ?? 1;
                  final name = (agency['name'] ?? 'Travel Agency').toString();
                  final city = (agency['city'] ?? 'India').toString();
                  final phone = (agency['phone'] ?? '').toString();
                  final email = (agency['email'] ?? '').toString();
                  final address = (agency['address'] ?? '').toString();
                  final status = (agency['status'] ?? 'new').toString();
                  final rating = (agency['rating'] ?? '4.8').toString();

                  // Genuine Dynamic Partner Intelligence Scoring
                  final double agencyRating = double.tryParse(rating) ?? 4.5;
                  int intelligenceScore = (agencyRating * 15).round(); // 67-75 base

                  if (phone.isNotEmpty && email.isNotEmpty) intelligenceScore += 10;
                  if (address.isNotEmpty) intelligenceScore += 5;

                  // High-yield feeder markets get direct routing priority
                  final highPriorityMarkets = ['mumbai', 'ahmedabad', 'surat', 'delhi', 'bengaluru', 'hyderabad', 'kolkata', 'pune', 'chennai', 'varanasi'];
                  if (highPriorityMarkets.contains(city.toLowerCase().trim())) {
                    intelligenceScore += 10;
                  }

                  String tierLabel = '🏢 VERIFIED TRAVEL AGENT';
                  Color tierColor = const Color(0xFF38BDF8);

                  if (intelligenceScore >= 90) {
                    tierLabel = '💎 ELITE DMC PARTNER ($intelligenceScore)';
                    tierColor = const Color(0xFFFBBF24);
                  } else if (intelligenceScore >= 80) {
                    tierLabel = '🔥 HIGH CONVERSION PROSPECT ($intelligenceScore)';
                    tierColor = const Color(0xFF34D399);
                  } else {
                    tierLabel = '🏢 VERIFIED AGENT ($intelligenceScore)';
                  }

                  Color statusColor = const Color(0xFF3B82F6);
                  String statusLabel = 'NEW PROSPECT';
                  String nextAction = '⚡ AI Action: Send 1-Tap Net Tariff Pitch';

                  if (status == 'in_crm') {
                    statusColor = const Color(0xFF10B981);
                    statusLabel = 'IN FLUENTCRM DRIP';
                    nextAction = '📈 AI Action: Share Dev Deepawali & Kumbh Allotment';
                  } else if (status == 'contacted') {
                    statusColor = const Color(0xFF8B5CF6);
                    statusLabel = 'PITCH SENT';
                    nextAction = '⏰ AI Action: Touch-2 Follow-Up Due Today';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : AppColors.lightBorderSubtle),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: tierColor.withValues(alpha: 0.18),
                              child: Icon(Icons.business_rounded, color: tierColor, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: statusColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),

                                  // Partner Intelligence Tier & Rating
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: tierColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tierLabel,
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: tierColor),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24)),
                                          Text(
                                            rating,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 11, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 3),
                                      Text(
                                        city.toUpperCase(),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFBBF24)),
                                      ),
                                      if (address.isNotEmpty) ...[
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            '• $address',
                                            style: const TextStyle(fontSize: 10, color: Colors.white54),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$phone ${email.isNotEmpty ? "• $email" : ""}',
                                    style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Next-Best-Action Recommendation Banner
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, size: 11, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 4),
                              Text(
                                nextAction,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFFBBF24)),
                              ),
                            ],
                          ),
                        ),

                        const Divider(color: Colors.white10, height: 12),

                        // Streamlined Intelligent Action Row (1 Primary AI Pill + 4 Ergonomic Icon Actions)
                        Row(
                          children: [
                            // 1. Primary AI Intelligence Pill
                            Expanded(
                              child: InkWell(
                                onTap: () => _showAiPitchModal(context, agency),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6.5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD97706).withValues(alpha: 0.28),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, size: 12.5, color: Colors.black),
                                      SizedBox(width: 4),
                                      Text(
                                        'AI Pitch',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 2. Direct Call
                            _buildActionIconButton(
                              icon: Icons.call_rounded,
                              tooltip: 'Call $name ($phone)',
                              color: const Color(0xFF3B82F6),
                              onTap: () {
                                callProvider.startOutboundCall(
                                  phone: phone,
                                  name: '$name ($city)',
                                  tourInterest: 'B2B DMC Partnership',
                                );
                              },
                            ),
                            const SizedBox(width: 6),

                            // 3. Open WhatsApp Chat
                            _buildActionIconButton(
                              icon: Icons.chat_bubble_rounded,
                              tooltip: 'WhatsApp $name',
                              color: const Color(0xFF10B981),
                              onTap: () => _openAgencyWhatsAppChat(context, agency),
                            ),
                            const SizedBox(width: 6),

                            // 4. White-Label / Net B2B Quote
                            _buildActionIconButton(
                              icon: Icons.request_quote_rounded,
                              tooltip: 'Create Net B2B Quote',
                              color: const Color(0xFFF59E0B),
                              onTap: () {
                                final agencyLead = LeadModel(
                                  id: 'b2b_$id',
                                  name: name,
                                  phone: phone,
                                  email: email,
                                  companyOrCity: city,
                                  destination: 'Kashi - Ayodhya - Prayagraj 4D3N Circuit',
                                  pax: 12,
                                  stage: 'contacted',
                                  source: 'b2b_partner',
                                  createdAt: DateTime.now(),
                                );
                                TravelQuoteDialog.show(context, agencyLead, initialB2bMode: true);
                              },
                            ),
                            const SizedBox(width: 6),

                            // 5. CRM Funnel Drip
                            _buildActionIconButton(
                              icon: status == 'in_crm' ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
                              tooltip: status == 'in_crm' ? 'Synced to FluentCRM Drip' : 'Enroll in CRM Drip',
                              color: status == 'in_crm' ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                              bgColor: status == 'in_crm' ? const Color(0xFF10B981).withValues(alpha: 0.15) : null,
                              onTap: () async {
                                setState(() {
                                  agency['status'] = 'in_crm';
                                });
                                final leadProvider = Provider.of<LeadProvider>(context, listen: false);
                                final synced = await leadProvider.apiService.syncB2bAgencyToCrm(agencyId: id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        synced
                                            ? '✓ $name synced to FluentCRM List 8 & enrolled in Dev Deepawali Funnel!'
                                            : '✓ $name marked for FluentCRM B2B Funnel sync.',
                                      ),
                                      backgroundColor: const Color(0xFF0284C7),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? color : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
    Color? bgColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor ?? color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(icon, size: 15, color: color),
          ),
        ),
      ),
    );
  }
}
