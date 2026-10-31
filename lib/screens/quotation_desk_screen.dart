import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../providers/lead_provider.dart';
import '../widgets/glass_card.dart';

class QuotationDeskScreen extends StatefulWidget {
  final LeadModel? initialLead;

  const QuotationDeskScreen({super.key, this.initialLead});

  static void open(BuildContext context, [LeadModel? lead]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuotationDeskScreen(initialLead: lead)),
    );
  }

  @override
  State<QuotationDeskScreen> createState() => _QuotationDeskScreenState();
}

class _QuotationDeskScreenState extends State<QuotationDeskScreen> {
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _hotelNameCtrl = TextEditingController();
  final _customInclusionsCtrl = TextEditingController();
  final _advanceTokenCtrl = TextEditingController(text: '3000');
  final _customTotalCtrl = TextEditingController();

  String _selectedCircuit = 'Varanasi 3D2N Spiritual Essence';
  int _pax = 2;
  String _hotelCategory = '4-Star Deluxe';
  String _cabType = 'Innova Crysta';
  DateTime? _travelDate;

  bool _includeSugamDarshan = true;
  bool _includeAartiBoat = true;
  bool _includeAirportPickup = true;
  bool _includeSubahEBanaras = false;
  bool _includePandaShastri = false;
  bool _isB2bMode = false;
  bool _isManualPrice = false;

  final List<String> _circuits = [
    'Varanasi 3D2N Spiritual Essence',
    'Kashi - Ayodhya - Prayagraj 4D3N Circuit',
    'Dev Deepawali 2026 Special 3D2N Allocation',
    'Kashi - Gaya - Bodhgaya 3D2N Pind Daan',
    'Varanasi Local 2D1N Darshan & Ghats',
    'Prayagraj Sangam Day Tour (from Kashi)',
    'Ayodhya Ram Mandir Same Day VIP Darshan',
    'Customized Spiritual Tour Circuit...',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialLead != null) {
      final lead = widget.initialLead!;
      _customerNameCtrl.text = lead.name;
      _customerPhoneCtrl.text = lead.phone;
      _pax = lead.pax > 0 ? lead.pax : 2;
      _isB2bMode = lead.source.toLowerCase().contains('b2b') ||
          lead.tags.any((t) => t.toLowerCase().contains('b2b'));
      if (lead.destination.trim().isNotEmpty) {
        _selectedCircuit = _circuits.firstWhere(
          (c) => c.toLowerCase().contains(lead.destination.toLowerCase()),
          orElse: () => _circuits[0],
        );
      }
    } else {
      _travelDate = DateTime.now().add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _hotelNameCtrl.dispose();
    _customInclusionsCtrl.dispose();
    _advanceTokenCtrl.dispose();
    _customTotalCtrl.dispose();
    super.dispose();
  }

  double get _calculatedTotal {
    if (_isManualPrice && _customTotalCtrl.text.isNotEmpty) {
      return double.tryParse(_customTotalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 12500;
    }

    double basePerPax = 6500;
    if (_selectedCircuit.contains('4D3N')) basePerPax = 13500;
    if (_selectedCircuit.contains('Dev Deepawali')) basePerPax = 19500;
    if (_selectedCircuit.contains('Gaya')) basePerPax = 11500;
    if (_selectedCircuit.contains('Local 2D1N')) basePerPax = 4200;
    if (_selectedCircuit.contains('Sangam Day')) basePerPax = 3200;
    if (_selectedCircuit.contains('Ayodhya Ram Mandir')) basePerPax = 3800;

    double hotelCost = 0;
    if (_hotelCategory.contains('5-Star')) hotelCost = (8500 * (_pax / 2).ceil()).toDouble();
    if (_hotelCategory.contains('4-Star')) hotelCost = (4200 * (_pax / 2).ceil()).toDouble();
    if (_hotelCategory.contains('3-Star')) hotelCost = (2500 * (_pax / 2).ceil()).toDouble();

    double cabCost = 4500;
    if (_cabType.contains('Innova')) cabCost = 6500;
    if (_cabType.contains('Tempo') || _cabType.contains('Urbania')) cabCost = 12500;
    if (_cabType.contains('Dzire')) cabCost = 3800;

    double vipPasses = 0;
    if (_includeSugamDarshan) vipPasses += 350 * _pax;
    if (_includeAartiBoat) vipPasses += 750 * _pax;
    if (_includeSubahEBanaras) vipPasses += 400 * _pax;
    if (_includePandaShastri) vipPasses += 1500;

    double subtotal = (basePerPax * _pax) + hotelCost + cabCost + vipPasses;
    if (_isB2bMode) {
      return (subtotal * 0.88).roundToDouble(); // 12% wholesale DMC discount
    }
    return subtotal.roundToDouble();
  }

  String _generateProposalText() {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final total = currency.format(_calculatedTotal);
    final perPax = currency.format((_calculatedTotal / _pax).round());
    final advance = currency.format(double.tryParse(_advanceTokenCtrl.text) ?? 3000);
    final dateStr = _travelDate != null ? DateFormat('dd MMM yyyy').format(_travelDate!) : 'Dates Flexible';
    final name = _customerNameCtrl.text.trim().isNotEmpty ? _customerNameCtrl.text.trim() : 'Respected Traveler';

    final buffer = StringBuffer();
    if (_isB2bMode) {
      buffer.writeln('📋 *CONFIDENTIAL B2B NET WHOLESALE TARIFF & ALLOCATION*');
      buffer.writeln('Destination: *$_selectedCircuit*');
    } else {
      buffer.writeln('🙏 *Namaste $name! Greetings from TripCosmos Varanasi.*');
      buffer.writeln('Here is your personalized pilgrimage proposal for *$_selectedCircuit*:');
    }

    buffer.writeln('');
    buffer.writeln('📅 *Travel Date:* $dateStr');
    buffer.writeln('👥 *Travelers:* $_pax Pax');
    buffer.writeln('🏨 *Hotel Category:* $_hotelCategory ${_hotelNameCtrl.text.trim().isNotEmpty ? "(${_hotelNameCtrl.text.trim()})" : ""}');
    buffer.writeln('🚗 *Dedicated AC Cab:* $_cabType (Pickup to Drop throughout)');
    buffer.writeln('');
    buffer.writeln('✨ *VIP Inclusions:*');
    if (_includeSugamDarshan) buffer.writeln('• *Kashi Vishwanath Sugam Darshan Passes:* Priority entry via Gate 4 (Zero line waiting)');
    if (_includeAartiBoat) buffer.writeln('• *Dashashwamedh Ghat Ganga Aarti:* Reserved prime viewing deck on Bajra boat');
    if (_includeSubahEBanaras) buffer.writeln('• *Subah-e-Banaras Sunrise Boat Ride:* Assi Ghat to Manikarnika Ghat with Vedic chanting');
    if (_includePandaShastri) buffer.writeln('• *Vedic Shastri / Teerth Purohit:* Personal guide for Sankalp, Abhishek & Temple rituals');
    if (_includeAirportPickup) buffer.writeln('• *Airport / Railway Station Transfers:* AC Chauffeur meet & assist with placard');
    if (_customInclusionsCtrl.text.trim().isNotEmpty) buffer.writeln('• ${_customInclusionsCtrl.text.trim()}');

    buffer.writeln('');
    buffer.writeln('💰 *Total Package Investment:* *$total* ($perPax per person)');
    buffer.writeln('💳 *Advance Booking Token:* *$advance* to lock dates, VIP darshan passes & vehicle fleet.');
    buffer.writeln('⚖️ *Balance:* Payable on check-in arrival in Varanasi.');
    buffer.writeln('');
    buffer.writeln('📞 *Helpline / Operations Desk:* +91 93361 16210 | support@tripcosmos.co');
    return buffer.toString();
  }

  void _sendWhatsAppProposal() async {
    final phone = _customerPhoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter traveler phone number.')),
      );
      return;
    }

    final apiService = Provider.of<LeadProvider>(context, listen: false).apiService;
    final proposal = _generateProposalText();
    final ok = await apiService.sendWhatsAppMessage(phone: phone, message: proposal);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '✓ Proposal dispatched via WhatsApp!' : 'Dispatched via WhatsApp Gateway.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _copyProposal() {
    Clipboard.setData(ClipboardData(text: _generateProposalText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Complete proposal copied to clipboard!'),
        backgroundColor: AppColors.successGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _dispatchDriverSheet() {
    final driverNameCtrl = TextEditingController(text: 'Shiv Kumar Chauffeur');
    final driverPhoneCtrl = TextEditingController(text: '+91 98380 12345');
    final vehicleNumCtrl = TextEditingController(text: 'UP 65 BT 4589');
    final pickupLocCtrl = TextEditingController(text: 'Varanasi Cantt / Airport');
    final balanceCtrl = TextEditingController(text: '₹${(_calculatedTotal * 0.8).toInt()}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCard(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car_rounded, color: AppColors.accentBlue, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '1-Tap Chauffeur Duty Slip',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(context)),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: driverNameCtrl,
              decoration: const InputDecoration(labelText: 'Driver Name', prefixIcon: Icon(Icons.person_outline, size: 18)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: driverPhoneCtrl,
              decoration: const InputDecoration(labelText: 'Driver Phone', prefixIcon: Icon(Icons.phone_outlined, size: 18)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: vehicleNumCtrl,
              decoration: const InputDecoration(labelText: 'Vehicle Number & Model', prefixIcon: Icon(Icons.badge_outlined, size: 18)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pickupLocCtrl,
              decoration: const InputDecoration(labelText: 'Reporting Location', prefixIcon: Icon(Icons.location_on_outlined, size: 18)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue, padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                label: const Text('Dispatch Driver Slip via WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final guestPhone = _customerPhoneCtrl.text.trim();
                  final guestName = _customerNameCtrl.text.trim().isNotEmpty ? _customerNameCtrl.text.trim() : 'Guest';
                  final api = Provider.of<LeadProvider>(context, listen: false).apiService;

                  final driverMsg = '🚖 *TRIPCOSMOS DUTY SLIP*\nGuest: $guestName\nPhone: $guestPhone\nPax: $_pax\nPickup: ${pickupLocCtrl.text}\nVehicle: ${vehicleNumCtrl.text}\nCollect Balance: ${balanceCtrl.text}';
                  final guestMsg = '🚖 *YOUR CHAUFFEUR IS ASSIGNED*\nNamaste $guestName, your vehicle for $_selectedCircuit is confirmed:\nChauffeur: ${driverNameCtrl.text}\nPhone: ${driverPhoneCtrl.text}\nVehicle: ${vehicleNumCtrl.text} ($_cabType)\nPickup: ${pickupLocCtrl.text}';

                  Navigator.pop(ctx);
                  if (driverPhoneCtrl.text.isNotEmpty) {
                    await api.sendWhatsAppMessage(phone: driverPhoneCtrl.text, message: driverMsg);
                  }
                  if (guestPhone.isNotEmpty) {
                    await api.sendWhatsAppMessage(phone: guestPhone, message: guestMsg);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Duty slip dispatched to driver and guest!'), backgroundColor: AppColors.successGreen),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendReviewBooster() async {
    final phone = _customerPhoneCtrl.text.trim();
    final name = _customerNameCtrl.text.trim().isNotEmpty ? _customerNameCtrl.text.trim() : 'Traveler';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter phone number first.')));
      return;
    }
    final api = Provider.of<LeadProvider>(context, listen: false).apiService;
    final reviewText = '🙏 *Namaste $name!* Thank you for experiencing Varanasi with TripCosmos.\n\nOur team was blessed to serve you on your sacred pilgrimage. If you loved our Sugam Darshan passes, private boat ride and chauffeur service, please take 30 seconds to support us with a 5-star Google Review:\n\n⭐⭐⭐⭐⭐ *Leave Google Review:* https://g.page/r/TripCosmosVaranasi/review\n\nHar Har Mahadev! 🕉️';
    await api.sendWhatsAppMessage(phone: phone, message: reviewText);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Google 5-Star review booster dispatched!'), backgroundColor: AppColors.successGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('⚡ Quotation & Proposal Desk', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy Proposal',
            onPressed: _copyProposal,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'Send WhatsApp',
            onPressed: _sendWhatsAppProposal,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Client Header Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('1. TRAVELER / B2B PROFILE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5)),
                        Row(
                          children: [
                            const Text('B2B Wholesale Rate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Switch(
                              value: _isB2bMode,
                              activeColor: AppColors.accentGold,
                              onChanged: (v) => setState(() => _isB2bMode = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customerNameCtrl,
                            decoration: const InputDecoration(labelText: 'Traveler / Agency Name', prefixIcon: Icon(Icons.person_outline, size: 18)),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _customerPhoneCtrl,
                            decoration: const InputDecoration(labelText: 'WhatsApp Phone', prefixIcon: Icon(Icons.phone_outlined, size: 18)),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Circuit & Dates
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2. CIRCUIT & ITINERARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _circuits.contains(_selectedCircuit) ? _selectedCircuit : _circuits[0],
                      decoration: const InputDecoration(labelText: 'Pilgrimage Circuit', prefixIcon: Icon(Icons.temple_hindu_rounded, size: 18)),
                      isExpanded: true,
                      items: _circuits.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCircuit = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _travelDate ?? DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _travelDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.accentGold),
                                  const SizedBox(width: 8),
                                  Text(
                                    _travelDate != null ? DateFormat('dd MMM yyyy').format(_travelDate!) : 'Select Travel Date',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: _pax > 1 ? () => setState(() => _pax--) : null,
                              ),
                              Text('$_pax Pax', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => setState(() => _pax++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Vehicle & Hotel
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('3. FLEET & ACCOMMODATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _cabType,
                            decoration: const InputDecoration(labelText: 'AC Vehicle Fleet', prefixIcon: Icon(Icons.directions_car_rounded, size: 18)),
                            items: const [
                              DropdownMenuItem(value: 'Swift Dzire AC', child: Text('Swift Dzire (1-3 Pax)', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 'Innova Crysta', child: Text('Innova Crysta (4-6 Pax)', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: '12S Force Tempo Traveller', child: Text('Force Tempo (7-12 Pax)', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 'Force Urbania Luxury', child: Text('Force Urbania (10-15 Pax)', style: TextStyle(fontSize: 12.5))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _cabType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _hotelCategory,
                            decoration: const InputDecoration(labelText: 'Hotel Category', prefixIcon: Icon(Icons.hotel_rounded, size: 18)),
                            items: const [
                              DropdownMenuItem(value: '3-Star Premium', child: Text('3-Star Premium', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: '4-Star Deluxe', child: Text('4-Star Deluxe Ghat-Facing', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: '5-Star Heritage / Taj', child: Text('5-Star Luxury Heritage', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 'Cab Only (No Hotel)', child: Text('Cab Only (No Hotel)', style: TextStyle(fontSize: 12.5))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _hotelCategory = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // VIP Spiritual Inclusions Checklist
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('4. VIP SPIRITUAL INCLUSIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeSugamDarshan,
                      activeColor: AppColors.accentGold,
                      title: const Text('Sugam Darshan VIP Passes (Gate 4 Zero Waiting)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      onChanged: (v) => setState(() => _includeSugamDarshan = v ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeAartiBoat,
                      activeColor: AppColors.accentGold,
                      title: const Text('Reserved Dashashwamedh Bajra Boat (Ganga Aarti)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      onChanged: (v) => setState(() => _includeAartiBoat = v ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeSubahEBanaras,
                      activeColor: AppColors.accentGold,
                      title: const Text('Subah-e-Banaras Morning Sunrise Boat (Assi to Manikarnika)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      onChanged: (v) => setState(() => _includeSubahEBanaras = v ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includePandaShastri,
                      activeColor: AppColors.accentGold,
                      title: const Text('Dedicated Teerth Purohit / Shastri (Sankalp & Rituals)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      onChanged: (v) => setState(() => _includePandaShastri = v ?? false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Real-Time Total Calculation Box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.6), width: 1.5),
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
                              _isB2bMode ? 'B2B NET WHOLESALE' : 'TOTAL ESTIMATED TARIFF',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currency.format(_calculatedTotal),
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Per Person', style: TextStyle(fontSize: 11, color: Colors.white54)),
                            const SizedBox(height: 4),
                            Text(
                              currency.format((_calculatedTotal / _pax).round()),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 14)),
                            icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                            label: const Text('Send WhatsApp Proposal', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                            onPressed: _sendWhatsAppProposal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E293B), padding: const EdgeInsets.all(12)),
                          icon: const Icon(Icons.copy_rounded, color: AppColors.accentGold, size: 20),
                          tooltip: 'Copy Proposal Text',
                          onPressed: _copyProposal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Operational Companion Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accentBlue),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.local_taxi_rounded, size: 16, color: AppColors.accentBlue),
                      label: const Text('Dispatch Driver Slip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
                      onPressed: _dispatchDriverSheet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.star_rate_rounded, size: 16, color: Color(0xFFF59E0B)),
                      label: const Text('Google 5★ Booster', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                      onPressed: _sendReviewBooster,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
