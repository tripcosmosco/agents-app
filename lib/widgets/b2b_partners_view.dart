import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../providers/call_provider.dart';
import '../providers/lead_provider.dart';
import '../providers/whatsapp_provider.dart';
import 'travel_quote_dialog.dart';
import 'whatsapp_team_chat_view.dart';

class B2bPartnersView extends StatefulWidget {
  const B2bPartnersView({super.key});

  @override
  State<B2bPartnersView> createState() => _B2bPartnersViewState();
}

class _B2bPartnersViewState extends State<B2bPartnersView> {
  bool _isLoading = false;
  String _selectedCity = 'All';
  String _searchQuery = '';
  String _nextScheduledCity = 'Bengaluru';
  List<Map<String, dynamic>> _agencies = [];
  Map<String, dynamic> _counts = {'total': 0, 'new': 0, 'in_crm': 0, 'contacted': 0};

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
    _loadAgenciesFromServer();
  }

  Future<void> _loadAgenciesFromServer() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<LeadProvider>(context, listen: false).apiService;
      final res = await apiService.fetchB2bAgencies(
        search: _searchQuery,
        city: _selectedCity == 'All' ? '' : _selectedCity,
      );
      if (res != null && mounted) {
        final rawList = res['agencies'] as List<dynamic>? ?? [];
        setState(() {
          _agencies = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          if (res['counts'] is Map) {
            _counts = Map<String, dynamic>.from(res['counts'] as Map);
          }
          if (res['next_city'] != null) {
            _nextScheduledCity = res['next_city'].toString();
          }
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
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

  List<Map<String, dynamic>> get _filteredAgencies {
    return _agencies.where((a) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      final city = (a['city'] ?? '').toString();
      final phone = (a['phone'] ?? '').toString();
      final matchesCity = _selectedCity == 'All' || city.toLowerCase() == _selectedCity.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery);
      return matchesCity && matchesSearch;
    }).toList();
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

              setState(() {
                _agencies.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch,
                  'name': name,
                  'city': city,
                  'phone': phone,
                  'email': email,
                  'address': address,
                  'status': 'in_crm',
                  'rating': '4.8',
                });
              });

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
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);

    return Column(
      children: [
        // 1. B2B DMC Header Banner (100% Phone Control)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🏢 PAN-INDIA B2B DMC ENGINE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFBBF24)),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => _showB2bImporterDialog(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_download_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Import / Sync', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showAddAgencyDialog(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, size: 13, color: Colors.white),
                            SizedBox(width: 3),
                            Text('Add', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dev Deepawali 2026 & Spiritual Circuit Ground DMC Desk',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildMiniStat('Agencies', '${_agencies.length}', Colors.white),
                    const SizedBox(width: 14),
                    _buildMiniStat('In CRM Drip', '${_counts['in_crm'] ?? 2}', const Color(0xFF34D399)),
                    const SizedBox(width: 14),
                    _buildMiniStat('Contacted', '${_counts['contacted'] ?? 2}', const Color(0xFF38BDF8)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        const masterSheet = '''
🏢 *TRIPCOSMOS VARANASI — B2B DMC NET TARIFF SHEET (2026)*
──────────────────────────────────────
🤝 *100% White-Label Ground Handling (Your Agency Placard)*

1️⃣ *Varanasi 3D/2N Spiritual Essence:*
   • 3★ Standard: ₹7,100 / pax net
   • 4★ Deluxe: ₹12,100 / pax net
   • Includes: AC Stay, Airport Transfers, VIP Sugam Darshan, Reserved Aarti Boat

2️⃣ *Kashi - Ayodhya - Prayagraj (4D/3N Circuit):*
   • 3★ Standard: ₹10,500 / pax net
   • 4★ Deluxe: ₹16,300 / pax net

3️⃣ *Dev Deepawali 2026 Special Allocation:*
   • Pre-booked Dashashwamedh Bajra Boat Slots & Hotel Room Blocks

4️⃣ *Dedicated UP65 B2B Fleet Tariffs:*
   • Swift Dzire AC: ₹12/km | Innova Crysta: ₹19/km | 12S Tempo: ₹25/km
──────────────────────────────────────
📞 *Varanasi B2B Partner Desk:* +91 93361 16210
''';
                        Clipboard.setData(const ClipboardData(text: masterSheet));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Master B2B DMC Net Tariff Sheet copied! Paste in any WhatsApp group.'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFFFBBF24)),
                      label: const Text('Copy B2B Tariff', style: TextStyle(fontSize: 11, color: Color(0xFFFBBF24), fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 2. Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              hintText: 'Search B2B agency by name, city or phone...',
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 19),
            ),
          ),
        ),

        // 3. City Filter Chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _cities.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final city = _cities[idx];
              final isSelected = _selectedCity == city;
              return ChoiceChip(
                label: Text(
                  city,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFF59E0B),
                backgroundColor: AppColors.surfaceCard,
                onSelected: (_) {
                  setState(() => _selectedCity = city);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // 4. Agencies List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
              : _filteredAgencies.isEmpty
                  ? const Center(
                      child: Text(
                        'No B2B agencies match this filter.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 85),
                      itemCount: _filteredAgencies.length,
                      itemBuilder: (ctx, idx) {
                        final agency = _filteredAgencies[idx];
                        final id = int.tryParse(agency['id'].toString()) ?? 1;
                        final name = (agency['name'] ?? 'Travel Agency').toString();
                        final city = (agency['city'] ?? 'India').toString();
                        final phone = (agency['phone'] ?? '').toString();
                        final email = (agency['email'] ?? '').toString();
                        final address = (agency['address'] ?? '').toString();
                        final status = (agency['status'] ?? 'new').toString();

                        Color statusColor = const Color(0xFF3B82F6);
                        String statusLabel = 'NEW PROSPECT';
                        if (status == 'in_crm') {
                          statusColor = const Color(0xFF10B981);
                          statusLabel = 'IN FLUENTCRM DRIP';
                        } else if (status == 'contacted') {
                          statusColor = const Color(0xFF8B5CF6);
                          statusLabel = 'PITCH SENT';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFD97706).withValues(alpha: 0.2),
                                    child: const Icon(Icons.business_rounded, color: Color(0xFFFBBF24), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.18),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                              ),
                                              child: Text(
                                                statusLabel,
                                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: statusColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 13, color: Color(0xFFF59E0B)),
                                            const SizedBox(width: 4),
                                            Text(
                                              city.toUpperCase(),
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFFBBF24)),
                                            ),
                                            if (address.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '• $address',
                                                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$phone ${email.isNotEmpty ? "• $email" : ""}',
                                          style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 18),

                              // 5 Mobile Action Buttons (100% Phone Workflow)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // 1. Call Agency
                                    _buildAgencyActionButton(
                                      icon: Icons.call,
                                      label: 'Call',
                                      color: const Color(0xFF2563EB),
                                      onTap: () {
                                        callProvider.startOutboundCall(
                                          phone: phone,
                                          name: '$name ($city)',
                                          tourInterest: 'B2B DMC Partnership',
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),

                                    // 2. Open In-App WhatsApp Chat
                                    _buildAgencyActionButton(
                                      icon: Icons.chat_bubble_rounded,
                                      label: 'WhatsApp Chat',
                                      color: const Color(0xFF10B981),
                                      onTap: () => _openAgencyWhatsAppChat(context, agency),
                                    ),
                                    const SizedBox(width: 8),

                                    // 3. 1-Tap White-Label / Net B2B Quote
                                    _buildAgencyActionButton(
                                      icon: Icons.bolt,
                                      label: 'B2B Net Quote',
                                      color: const Color(0xFFD97706),
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
                                    const SizedBox(width: 8),

                                    // 4. Send Official 1-Tap B2B Pitch
                                    _buildAgencyActionButton(
                                      icon: Icons.send_rounded,
                                      label: 'Send Pitch',
                                      color: const Color(0xFF8B5CF6),
                                      onTap: () async {
                                        setState(() {
                                          agency['status'] = 'contacted';
                                        });
                                        final sent = await leadProvider.apiService.sendB2bPitch(agencyId: id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sent
                                                    ? '✓ B2B DMC Partnership Pitch sent to $name on WhatsApp!'
                                                    : '✓ B2B Pitch queued for $name ($phone)',
                                              ),
                                              backgroundColor: AppColors.successGreen,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),

                                    // 5. Enroll in FluentCRM Funnel (List 8)
                                    _buildAgencyActionButton(
                                      icon: Icons.cloud_upload_rounded,
                                      label: 'CRM Drip',
                                      color: const Color(0xFF0284C7),
                                      onTap: () async {
                                        setState(() {
                                          agency['status'] = 'in_crm';
                                        });
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
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildAgencyActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
