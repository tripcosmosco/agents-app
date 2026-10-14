import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../providers/lead_provider.dart';

class TravelQuoteDialog extends StatefulWidget {
  final LeadModel lead;
  final bool initialB2bMode;

  const TravelQuoteDialog({
    super.key,
    required this.lead,
    this.initialB2bMode = false,
  });

  static void show(BuildContext context, LeadModel lead, {bool initialB2bMode = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TravelQuoteDialog(lead: lead, initialB2bMode: initialB2bMode),
    );
  }

  @override
  State<TravelQuoteDialog> createState() => _TravelQuoteDialogState();
}

class _TravelQuoteDialogState extends State<TravelQuoteDialog> {
  late String _selectedCircuit;
  late int _pax;
  late bool _isB2bMode;
  String _hotelCategory = '4-Star Deluxe';
  String _cabType = 'Innova Crysta';
  bool _includeSugamDarshan = true;
  bool _includeAartiBoat = true;
  bool _includeAirportPickup = true;
  bool _includeSubahEBanaras = false;

  final List<String> _circuits = [
    'Varanasi 3D2N Spiritual Essence',
    'Kashi - Ayodhya - Prayagraj 4D3N Circuit',
    'Dev Deepawali 2026 Special 3D2N Allocation',
    'Kashi - Gaya - Bodhgaya 3D2N Pind Daan',
    'Varanasi Local 2D1N Darshan & Ghats',
    'Prayagraj Sangam Day Tour (from Kashi)',
  ];

  @override
  void initState() {
    super.initState();
    _isB2bMode = widget.initialB2bMode ||
        widget.lead.source.toLowerCase().contains('b2b') ||
        widget.lead.tags.any((t) => t.toLowerCase().contains('b2b') || t.toLowerCase().contains('agency'));
    _pax = widget.lead.pax > 0 ? widget.lead.pax : 2;

    // Smart default circuit based on lead's destination
    _selectedCircuit = _circuits.firstWhere(
      (c) => c.toLowerCase().contains(widget.lead.destination.toLowerCase()),
      orElse: () => _circuits[0],
    );

    if (_pax > 4) {
      _cabType = '12S Force Tempo Traveller';
    } else if (_pax <= 2) {
      _cabType = 'Swift Dzire AC';
    } else {
      _cabType = 'Innova Crysta';
    }
  }

  int get _retailPrice {
    int basePerPax = 0;
    if (_selectedCircuit.contains('Dev Deepawali')) {
      basePerPax = _hotelCategory == '5-Star Heritage' ? 34000 : (_hotelCategory == '4-Star Deluxe' ? 21500 : 14500);
    } else if (_selectedCircuit.contains('3D2N')) {
      basePerPax = _hotelCategory == '5-Star Heritage' ? 24500 : (_hotelCategory == '4-Star Deluxe' ? 14500 : 8500);
    } else if (_selectedCircuit.contains('4D3N')) {
      basePerPax = _hotelCategory == '5-Star Heritage' ? 32000 : (_hotelCategory == '4-Star Deluxe' ? 19500 : 12500);
    } else {
      basePerPax = _hotelCategory == '5-Star Heritage' ? 18000 : (_hotelCategory == '4-Star Deluxe' ? 11000 : 6500);
    }

    int total = basePerPax * _pax;

    // Vehicle adjustments
    if (_cabType == 'Innova Crysta') total += 3500;
    if (_cabType == '12S Force Tempo Traveller') total += 8000;

    // Addons
    if (_includeSugamDarshan) total += (600 * _pax);
    if (_includeAartiBoat) total += (_pax <= 2 ? 1500 : 2800);
    if (_includeAirportPickup) total += 1200;
    if (_includeSubahEBanaras) total += (500 * _pax);

    return total;
  }

  int get _b2bNetPrice => (_retailPrice * 0.84).round();
  int get _agentMargin => _retailPrice - _b2bNetPrice;
  int get _activePrice => _isB2bMode ? _b2bNetPrice : _retailPrice;

  String _generateQuotationText({bool forceWhiteLabel = false}) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final retailFormatted = currencyFormatter.format(_retailPrice);
    final netFormatted = currencyFormatter.format(_b2bNetPrice);
    final marginFormatted = currencyFormatter.format(_agentMargin);
    final perPaxRetail = currencyFormatter.format((_retailPrice / _pax).round());
    final perPaxNet = currencyFormatter.format((_b2bNetPrice / _pax).round());

    final buffer = StringBuffer();

    if (forceWhiteLabel) {
      // 100% White-Label Quote for B2B Partner to forward directly to their client
      buffer.writeln('🕉️ *SACRED PILGRIMAGE TOUR PROPOSAL*');
      buffer.writeln('------------------------------------------');
      buffer.writeln('📍 *Circuit:* $_selectedCircuit');
      buffer.writeln('👥 *Guests:* $_pax Pax');
      buffer.writeln('🏨 *Stay Category:* $_hotelCategory (Near Temple / Ghats)');
      buffer.writeln('🚗 *Private Transport:* $_cabType (AC, Verified Chauffeur)');
      buffer.writeln('');
      buffer.writeln('✨ *CONFIRMED VIP INCLUSIONS:*');
      if (_includeSugamDarshan) buffer.writeln('  • ✅ Kashi Vishwanath VIP Sugam Darshan (Priority Entry)');
      if (_includeAartiBoat) buffer.writeln('  • ✅ Reserved Evening Dashashwamedh Ganga Aarti Boat');
      if (_includeAirportPickup) buffer.writeln('  • ✅ Varanasi Airport / Station Private Pickup & Drop');
      if (_includeSubahEBanaras) buffer.writeln('  • ✅ Morning Ghat Boat Ride & Subah-e-Banaras');
      buffer.writeln('  • ✅ 24x7 On-Ground Local Escort & Darshan Assistance');
      buffer.writeln('');
      buffer.writeln('💰 *Total Package Tariff:* $retailFormatted ($perPaxRetail / guest)');
      buffer.writeln('------------------------------------------');
      buffer.writeln('_Reply to confirm your dates and lock hotel & boat allocations._');
      return buffer.toString();
    }

    if (_isB2bMode) {
      // B2B Partner Net DMC Tariff Sheet
      buffer.writeln('🏢 *TRIPCOSMOS B2B DMC NET TARIFF QUOTATION*');
      buffer.writeln('------------------------------------------');
      buffer.writeln('🤝 *Partner Agency:* ${widget.lead.name}');
      buffer.writeln('📍 *Circuit:* $_selectedCircuit');
      buffer.writeln('👥 *Group Size:* $_pax Pax');
      buffer.writeln('🏨 *Hotel Tier:* $_hotelCategory');
      buffer.writeln('🚗 *Dedicated Fleet:* $_cabType (White-Label Placard)');
      buffer.writeln('');
      buffer.writeln('✨ *GROUND DMC INCLUSIONS:*');
      if (_includeSugamDarshan) buffer.writeln('  • ✅ Kashi Vishwanath VIP Sugam Darshan Passes');
      if (_includeAartiBoat) buffer.writeln('  • ✅ Pre-Allocated Ganga Aarti Bajra Boat Seats');
      if (_includeAirportPickup) buffer.writeln('  • ✅ Airport/Station Welcome with YOUR Agency Placard');
      if (_includeSubahEBanaras) buffer.writeln('  • ✅ Morning Subah-e-Banaras Boat Ride');
      buffer.writeln('  • ✅ 100% White-Label Vouchers (Zero TripCosmos Branding to Guest)');
      buffer.writeln('');
      buffer.writeln('💼 *B2B NET DMC RATE:* *$netFormatted* ($perPaxNet / pax)');
      buffer.writeln('🏷️ *Suggested Retail:* $retailFormatted (Your Margin: *$marginFormatted*)');
      buffer.writeln('🔒 *Allocation Hold:* ₹2,000 token advance (UPI: 9336116210@upi)');
      buffer.writeln('');
      buffer.writeln('TripCosmos B2B DMC Desk, Varanasi | +91 93361 16210');
      return buffer.toString();
    }

    // Standard B2C Retail Quote
    buffer.writeln('🕉️ *TRIPCOSMOS SPECIALIZED PILGRIMAGE QUOTATION*');
    buffer.writeln('------------------------------------------');
    buffer.writeln('👤 *Traveler:* ${widget.lead.name}');
    buffer.writeln('📍 *Circuit:* $_selectedCircuit');
    buffer.writeln('👥 *Travelers:* $_pax Pax');
    buffer.writeln('🏨 *Hotel Category:* $_hotelCategory (Centrally Located / Near Ghats)');
    buffer.writeln('🚗 *Dedicated Transport:* $_cabType (UP65 Tourist Permit, AC, Sanitized)');
    buffer.writeln('');
    buffer.writeln('✨ *SPECIAL VIP INCLUSIONS:*');
    if (_includeSugamDarshan) buffer.writeln('  • ✅ Kashi Vishwanath VIP Sugam Darshan (No Queue Direct Entry)');
    if (_includeAartiBoat) buffer.writeln('  • ✅ Reserved Evening Dashashwamedh Ganga Aarti Bajra Boat');
    if (_includeAirportPickup) buffer.writeln('  • ✅ Lal Bahadur Shastri Airport (VNS) Pickup & Drop');
    if (_includeSubahEBanaras) buffer.writeln('  • ✅ Morning Boat Ride & Subah-e-Banaras Cultural Protocol');
    buffer.writeln('  • ✅ 24x7 Local Concierge & Temple Protocol Assistance');
    buffer.writeln('');
    buffer.writeln('💰 *Total Package Value:* $retailFormatted ($perPaxRetail / person)');
    buffer.writeln('🔒 *Confirmation Advance:* ₹3,000 via UPI: 9336116210@upi (Balance upon Varanasi arrival)');
    buffer.writeln('');
    buffer.writeln('TripCosmos.co | Assi Ghat Desk, Varanasi');
    buffer.writeln('Direct Contact: +91 93361 16210');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final totalFormatted = currencyFormatter.format(_activePrice);

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isB2bMode ? Icons.business_rounded : Icons.bolt,
                        color: const Color(0xFFFBBF24),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isB2bMode ? 'B2B DMC NET TARIFF & WHITE-LABEL' : '1-TAP TRAVEL QUOTATION',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                          Text(
                            '${_isB2bMode ? 'Agency' : 'Client'}: ${widget.lead.name} (${widget.lead.phone})',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // B2C vs B2B Segmented Mode Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isB2bMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isB2bMode ? AppColors.accentBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                '👤 Direct Pilgrim (B2C)',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isB2bMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isB2bMode ? const Color(0xFFD97706) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                '🏢 Travel Agent (B2B DMC)',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Tour Circuit Dropdown
                const Text(
                  'PILGRIMAGE / TOUR CIRCUIT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white54),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0F172A),
                      value: _circuits.contains(_selectedCircuit) ? _selectedCircuit : _circuits.first,
                      items: _circuits
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13, color: Colors.white))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCircuit = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Pax & Hotel Tier Row
                Row(
                  children: [
                    // Pax
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TRAVELERS (PAX)',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white54),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                dropdownColor: const Color(0xFF0F172A),
                                value: [1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 26].contains(_pax) ? _pax : 2,
                                items: [1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 26]
                                    .map((p) => DropdownMenuItem(value: p, child: Text('$p Pax', style: const TextStyle(fontSize: 13, color: Colors.white))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _pax = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Hotel Tier
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HOTEL CATEGORY',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white54),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                dropdownColor: const Color(0xFF0F172A),
                                value: ['3-Star Standard', '4-Star Deluxe', '5-Star Heritage'].contains(_hotelCategory)
                                    ? _hotelCategory
                                    : '4-Star Deluxe',
                                items: ['3-Star Standard', '4-Star Deluxe', '5-Star Heritage']
                                    .map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 13, color: Colors.white))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _hotelCategory = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Transport Vehicle
                const Text(
                  'TRANSPORT VEHICLE (UP65 FLEET)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white54),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0F172A),
                      value: ['Swift Dzire AC', 'Innova Crysta', '12S Force Tempo Traveller'].contains(_cabType)
                          ? _cabType
                          : 'Innova Crysta',
                      items: ['Swift Dzire AC', 'Innova Crysta', '12S Force Tempo Traveller']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13, color: Colors.white))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _cabType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Special Pilgrimage Inclusions
                const Text(
                  'SPECIAL PILGRIMAGE INCLUSIONS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white54),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _buildInclusionCheckbox('Kashi Vishwanath VIP Sugam Darshan Pass', _includeSugamDarshan, (val) => setState(() => _includeSugamDarshan = val ?? false)),
                      _buildInclusionCheckbox('Dashashwamedh Aarti Reserved Bajra Boat', _includeAartiBoat, (val) => setState(() => _includeAartiBoat = val ?? false)),
                      _buildInclusionCheckbox('Lal Bahadur Shastri Airport (VNS) Pickup & Drop', _includeAirportPickup, (val) => setState(() => _includeAirportPickup = val ?? false)),
                      _buildInclusionCheckbox('Subah-e-Banaras Morning Ghat Boat Ride', _includeSubahEBanaras, (val) => setState(() => _includeSubahEBanaras = val ?? false)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Total Price Banner (Retail vs B2B Net + Margin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isB2bMode
                        ? const Color(0xFFD97706).withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isB2bMode
                          ? const Color(0xFFD97706).withValues(alpha: 0.4)
                          : const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isB2bMode ? 'B2B NET DMC TARIFF' : 'CALCULATED QUOTATION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _isB2bMode ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                                ),
                              ),
                              Text(
                                totalFormatted,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isB2bMode ? const Color(0xFFD97706) : const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${currencyFormatter.format((_activePrice / _pax).round())} / pax',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (_isB2bMode) ...[
                        const Divider(color: Colors.white12, height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Retail: ${currencyFormatter.format(_retailPrice)}',
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Profit: +${currencyFormatter.format(_agentMargin)} (16%)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF34D399)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final text = _generateQuotationText(forceWhiteLabel: _isB2bMode);
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isB2bMode
                                    ? '✓ 100% White-Label Client Quote copied (Zero TripCosmos branding)!'
                                    : '✓ Quotation text copied to clipboard!',
                              ),
                              backgroundColor: const Color(0xFF1E293B),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 15, color: Colors.white),
                        label: Text(
                          _isB2bMode ? 'Copy White-Label' : 'Copy Quote',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final quoteText = _generateQuotationText();
                          final leadProvider = Provider.of<LeadProvider>(context, listen: false);
                          leadProvider.updateLeadStage(widget.lead.id, 'quote_sent');
                          leadProvider.addLeadNote(
                            widget.lead.id,
                            '⚡ ${_isB2bMode ? "B2B Net Tariff" : "Quotation"} for $_selectedCircuit ($totalFormatted) dispatched via official WhatsApp.',
                          );

                          final apiService = leadProvider.apiService;
                          final delivered = await apiService.sendWhatsAppMessage(
                            phone: widget.lead.phone,
                            message: quoteText,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  delivered
                                      ? '✓ ${_isB2bMode ? "B2B Net Tariff" : "Official quotation"} sent to ${widget.lead.name} via WhatsApp!'
                                      : '⚠️ Quotation queued for delivery to ${widget.lead.name}',
                                ),
                                backgroundColor: delivered ? AppColors.successGreen : const Color(0xFF1E293B),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                        label: Text(
                          _isB2bMode ? 'Send B2B Net Rate on WhatsApp' : 'Send Official WhatsApp Quote',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showBrandedQuotePreview(context),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.accentGold),
                    label: Text(
                      _isB2bMode ? 'Preview White-Label Proposal Card' : 'Preview Branded Proposal Card',
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: const BorderSide(color: AppColors.accentGold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInclusionCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                activeColor: const Color(0xFFF59E0B),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBrandedQuotePreview(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final totalFormatted = currencyFormatter.format(_activePrice);
    final perPaxFormatted = currencyFormatter.format((_activePrice / _pax).round());
    final quoteId = 'TC-PRP-${DateTime.now().year}-${widget.lead.id.replaceAll(RegExp(r'[^0-9]'), '')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF0B132B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.accentGold, width: 2)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isB2bMode ? 'WHITE-LABEL B2B VOUCHER PREVIEW' : 'TRIPCOSMOS.CO',
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      _isB2bMode ? '100% Unbranded Client Proposal • $quoteId' : 'Official Sacred Pilgrimage Proposal • $quoteId',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 24),
            Expanded(
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lead.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.lead.phone,
                              style: const TextStyle(color: AppColors.accentGold, fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            '$_pax Pilgrims',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PILGRIMAGE CIRCUIT & VEHICLE', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Text(_selectedCircuit, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Reserved Cab: $_cabType', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Hotel Tier: $_hotelCategory', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0F2E1E), Color(0xFF1E293B)]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_isB2bMode ? 'B2B Net Partner Tariff:' : 'Total Package Investment:', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(totalFormatted, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Rate per Pilgrim:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text('$perPaxFormatted / person', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
