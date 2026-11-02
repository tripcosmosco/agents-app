import 'tariff_pricing_manager_sheet.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../providers/lead_provider.dart';
import '../screens/quotation_desk_screen.dart';

/// Customizable Dynamic Activity & VIP Add-on Model
class ActivityTariffItem {
  final String id;
  String title;
  String subtitle;
  int price;
  bool isPerPax;
  bool isIncluded;
  bool isCustom;

  ActivityTariffItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.price,
    this.isPerPax = false,
    this.isIncluded = true,
    this.isCustom = false,
  });

  int calculateTotal(int pax) {
    if (!isIncluded) return 0;
    return isPerPax ? (price * pax) : price;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'price': price,
    'isPerPax': isPerPax,
    'isIncluded': isIncluded,
    'isCustom': isCustom,
  };

  factory ActivityTariffItem.fromJson(Map<String, dynamic> json) => ActivityTariffItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    subtitle: json['subtitle']?.toString() ?? '',
    price: (json['price'] as num?)?.toInt() ?? 0,
    isPerPax: json['isPerPax'] == true,
    isIncluded: json['isIncluded'] != false,
    isCustom: json['isCustom'] == true,
  );
}

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
  List<ActivityTariffItem> _activities = [];

  void _initDefaultActivities() {
    _activities = [
      ActivityTariffItem(
        id: 'sugam_darshan',
        title: 'Kashi Vishwanath VIP Sugam Darshan Pass',
        subtitle: 'Gate 4 Priority • Direct corridor access',
        price: 600,
        isPerPax: true,
        isIncluded: true,
      ),
      ActivityTariffItem(
        id: 'aarti_boat',
        title: 'Dashashwamedh Aarti Reserved Bajra Boat',
        subtitle: 'Prime Maha Aarti river deck viewing',
        price: _pax <= 2 ? 1500 : 2800,
        isPerPax: false,
        isIncluded: true,
      ),
      ActivityTariffItem(
        id: 'airport_pickup',
        title: 'Varanasi Airport / Station Pickup & Drop',
        subtitle: 'Dedicated AC cab with placard chauffeur',
        price: 1200,
        isPerPax: false,
        isIncluded: true,
      ),
      ActivityTariffItem(
        id: 'subah_e_banaras',
        title: 'Subah-e-Banaras Morning Boat Ride',
        subtitle: 'Assi to Manikarnika sunrise ghat cruise',
        price: 500,
        isPerPax: true,
        isIncluded: false,
      ),
      ActivityTariffItem(
        id: 'panda_shastri',
        title: 'Vedic Teerth Purohit / Panda Assistance',
        subtitle: 'Ganga Sankalp & temple protocol guidance',
        price: 1500,
        isPerPax: false,
        isIncluded: false,
      ),
    ];
  }

  Future<void> _loadSavedTariffs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('tc_custom_activity_tariffs');
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr) as List<dynamic>?;
        if (decoded != null && mounted) {
          final savedItems = decoded.map((e) => ActivityTariffItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          setState(() {
            for (final saved in savedItems) {
              final idx = _activities.indexWhere((a) => a.id == saved.id);
              if (idx != -1) {
                _activities[idx].price = saved.price;
                _activities[idx].isPerPax = saved.isPerPax;
                _activities[idx].isIncluded = saved.isIncluded;
              } else if (saved.isCustom) {
                _activities.add(saved);
              }
            }
            _syncPriceControllers();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved tariffs: ');
    }
  }

  Future<void> _saveCustomTariffs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_activities.map((a) => a.toJson()).toList());
      await prefs.setString('tc_custom_activity_tariffs', jsonStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Custom activity prices saved as personal defaults!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving custom tariffs: ');
    }
  }

  // Customizable Itinerary & Rate Controls
  DateTime? _travelDate;
  final TextEditingController _customCircuitController = TextEditingController();
  final TextEditingController _hotelNameController = TextEditingController();
  final TextEditingController _customInclusionsController = TextEditingController();

  bool _isManualPriceOverride = false;
  final TextEditingController _customTotalController = TextEditingController();
  final TextEditingController _customPerPaxController = TextEditingController();
  final TextEditingController _advanceTokenController = TextEditingController();

  bool _showTextEditor = false;
  final TextEditingController _quoteMessageController = TextEditingController();
  bool _isMessageManuallyEdited = false;

  final List<String> _circuits = [
    'Varanasi 3D2N Spiritual Essence',
    'Kashi - Ayodhya - Prayagraj 4D3N Circuit',
    'Dev Deepawali 2026 Special 3D2N Allocation',
    'Kashi - Gaya - Bodhgaya 3D2N Pind Daan',
    'Varanasi Local 2D1N Darshan & Ghats',
    'Prayagraj Sangam Day Tour (from Kashi)',
    'Custom Tour Circuit...',
  ];

  @override
  void initState() {
    super.initState();
    _isB2bMode = widget.initialB2bMode ||
        widget.lead.source.toLowerCase().contains('b2b') ||
        widget.lead.tags.any((t) => t.toLowerCase().contains('b2b') || t.toLowerCase().contains('agency'));
    _pax = widget.lead.pax > 0 ? widget.lead.pax : 2;

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

    _initDefaultActivities();
    _advanceTokenController.text = _isB2bMode ? '2000' : '3000';
    _syncPriceControllers();
    _quoteMessageController.text = _generateQuotationText();
    _loadSavedTariffs();

    // Dynamically load live catalog tours from WordPress /catalog
    final apiService = Provider.of<LeadProvider>(context, listen: false).apiService;
    Future.microtask(() async {
      try {
        final items = await apiService.fetchCatalog();
        if (items.isNotEmpty && mounted) {
          setState(() {
            for (final item in items) {
              final title = (item['title'] ?? '').toString();
              if (title.isNotEmpty && !_circuits.contains(title)) {
                _circuits.insert(0, title);
              }
            }
          });
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _customCircuitController.dispose();
    _hotelNameController.dispose();
    _customInclusionsController.dispose();
    _customTotalController.dispose();
    _customPerPaxController.dispose();
    _advanceTokenController.dispose();
    _quoteMessageController.dispose();
    super.dispose();
  }

  int get _calculatedRetailPrice {
    int basePerPax = 0;
    final circuitText = _resolvedCircuit;
    if (circuitText.contains('Dev Deepawali')) {
      basePerPax = _hotelCategory == '5-Star Heritage' ? 34000 : (_hotelCategory == '4-Star Deluxe' ? 21500 : 14500);
    } else if (circuitText.contains('3D2N')) {
      basePerPax = _hotelCategory == '5-Star Heritage' ? 24500 : (_hotelCategory == '4-Star Deluxe' ? 14500 : 8500);
    } else if (circuitText.contains('4D3N')) {
      basePerPax = _hotelCategory == '5-Star Heritage' ? 32000 : (_hotelCategory == '4-Star Deluxe' ? 19500 : 12500);
    } else {
      basePerPax = _hotelCategory == '5-Star Heritage' ? 18000 : (_hotelCategory == '4-Star Deluxe' ? 11000 : 6500);
    }

    int total = basePerPax * _pax;

    // Vehicle adjustments
    if (_cabType == 'Innova Crysta') total += 3500;
    if (_cabType == '12S Force Tempo Traveller') total += 8000;

    // Dynamic Activity Addons
    for (final act in _activities) {
      total += act.calculateTotal(_pax);
    }

    return total;
  }

  int get _retailPrice {
    if (_isManualPriceOverride) {
      final parsed = int.tryParse(_customTotalController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null && parsed > 0) return parsed;
    }
    return _calculatedRetailPrice;
  }

  int get _b2bNetPrice => (_retailPrice * 0.84).round();
  int get _agentMargin => _retailPrice - _b2bNetPrice;
  int get _activePrice => _isB2bMode ? _b2bNetPrice : _retailPrice;

  int get _advanceToken {
    final parsed = int.tryParse(_advanceTokenController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed != null && parsed > 0) return parsed;
    return _isB2bMode ? 2000 : 3000;
  }

  String get _resolvedCircuit {
    if (_selectedCircuit == 'Custom Tour Circuit...' && _customCircuitController.text.trim().isNotEmpty) {
      return _customCircuitController.text.trim();
    }
    return _selectedCircuit;
  }

  void _syncPriceControllers() {
    if (!_isManualPriceOverride) {
      final total = _calculatedRetailPrice;
      _customTotalController.text = total.toString();
      _customPerPaxController.text = (total / _pax).round().toString();
    }
    _refreshMessageIfUnedited();
  }

  void _refreshMessageIfUnedited() {
    if (!_isMessageManuallyEdited) {
      _quoteMessageController.text = _generateQuotationText();
    }
  }

  String _generateQuotationText({bool forceWhiteLabel = false}) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final retailFormatted = currencyFormatter.format(_retailPrice);
    final netFormatted = currencyFormatter.format(_b2bNetPrice);
    final marginFormatted = currencyFormatter.format(_agentMargin);
    final perPaxRetail = currencyFormatter.format((_retailPrice / _pax).round());
    final perPaxNet = currencyFormatter.format((_b2bNetPrice / _pax).round());
    final advanceFormatted = currencyFormatter.format(_advanceToken);

    final buffer = StringBuffer();
    final circuit = _resolvedCircuit;
    final dateStr = _travelDate != null ? DateFormat('dd MMM yyyy').format(_travelDate!) : null;
    final hotelDetail = _hotelNameController.text.trim().isNotEmpty
        ? '${_hotelNameController.text.trim()} ($_hotelCategory)'
        : '$_hotelCategory (Centrally Located / Near Ghats)';

    if (forceWhiteLabel) {
      buffer.writeln('🕉️ *SACRED PILGRIMAGE TOUR PROPOSAL*');
      buffer.writeln('------------------------------------------');
      buffer.writeln('📍 *Circuit:* $circuit');
      if (dateStr != null) buffer.writeln('📅 *Travel Dates:* $dateStr');
      buffer.writeln('👥 *Guests:* $_pax Pax');
      buffer.writeln('🏨 *Stay Category:* $hotelDetail');
      buffer.writeln('🚗 *Private Transport:* $_cabType (AC, Verified Chauffeur)');
      buffer.writeln('');
      buffer.writeln('✨ *CONFIRMED VIP INCLUSIONS:*');
      for (final act in _activities) {
        if (act.isIncluded) buffer.writeln('  • ✅ ${act.title}');
      }
      if (_customInclusionsController.text.trim().isNotEmpty) {
        for (final line in _customInclusionsController.text.trim().split('\n')) {
          if (line.trim().isNotEmpty) buffer.writeln('  • ✅ ${line.trim()}');
        }
      }
      buffer.writeln('  • ✅ 24x7 On-Ground Local Escort & Darshan Assistance');
      buffer.writeln('');
      buffer.writeln('💰 *Total Package Tariff:* $retailFormatted ($perPaxRetail / guest)');
      buffer.writeln('🔒 *Advance Token to Confirm:* $advanceFormatted');
      buffer.writeln('------------------------------------------');
      buffer.writeln('_Reply to confirm your dates and lock hotel & boat allocations._');
      return buffer.toString();
    }

    if (_isB2bMode) {
      buffer.writeln('🏢 *TRIPCOSMOS B2B DMC NET TARIFF QUOTATION*');
      buffer.writeln('------------------------------------------');
      buffer.writeln('🤝 *Partner Agency:* ${widget.lead.name}');
      buffer.writeln('📍 *Circuit:* $circuit');
      if (dateStr != null) buffer.writeln('📅 *Travel Dates:* $dateStr');
      buffer.writeln('👥 *Group Size:* $_pax Pax');
      buffer.writeln('🏨 *Hotel Tier:* $hotelDetail');
      buffer.writeln('🚗 *Dedicated Fleet:* $_cabType (White-Label Placard)');
      buffer.writeln('');
      buffer.writeln('✨ *GROUND DMC INCLUSIONS:*');
      for (final act in _activities) {
        if (act.isIncluded) {
          final priceTag = act.isPerPax ? ' (₹${act.price}/pax)' : ' (₹${act.price})';
          buffer.writeln('  • ✅ ${act.title}$priceTag');
        }
      }
      if (_customInclusionsController.text.trim().isNotEmpty) {
        for (final line in _customInclusionsController.text.trim().split('\n')) {
          if (line.trim().isNotEmpty) buffer.writeln('  • ✅ ${line.trim()}');
        }
      }
      buffer.writeln('  • ✅ 100% White-Label Vouchers (Zero TripCosmos Branding to Guest)');
      buffer.writeln('');
      buffer.writeln('💼 *B2B NET DMC RATE:* *$netFormatted* ($perPaxNet / pax)');
      buffer.writeln('🏷️ *Suggested Retail:* $retailFormatted (Your Margin: *$marginFormatted*)');
      buffer.writeln('🔒 *Allocation Hold:* $advanceFormatted token advance (UPI: 9336116210@upi)');
      buffer.writeln('');
      buffer.writeln('TripCosmos B2B DMC Desk, Varanasi | +91 93361 16210');
      return buffer.toString();
    }

    // Standard B2C Retail Quote
    buffer.writeln('🕉️ *TRIPCOSMOS SPECIALIZED PILGRIMAGE QUOTATION*');
    buffer.writeln('------------------------------------------');
    buffer.writeln('👤 *Traveler:* ${widget.lead.name}');
    buffer.writeln('📍 *Circuit:* $circuit');
    if (dateStr != null) buffer.writeln('📅 *Travel Dates:* $dateStr');
    buffer.writeln('👥 *Travelers:* $_pax Pax');
    buffer.writeln('🏨 *Hotel Category:* $hotelDetail');
    buffer.writeln('🚗 *Dedicated Transport:* $_cabType (UP65 Tourist Permit, AC, Sanitized)');
    buffer.writeln('');
    buffer.writeln('✨ *SPECIAL VIP INCLUSIONS:*');
    for (final act in _activities) {
      if (act.isIncluded) buffer.writeln('  • ✅ ${act.title}');
    }
    if (_customInclusionsController.text.trim().isNotEmpty) {
      for (final line in _customInclusionsController.text.trim().split('\n')) {
        if (line.trim().isNotEmpty) buffer.writeln('  • ✅ ${line.trim()}');
      }
    }
    buffer.writeln('  • ✅ 24x7 Local Concierge & Temple Protocol Assistance');
    buffer.writeln('');
    buffer.writeln('💰 *Total Package Value:* $retailFormatted ($perPaxRetail / person)');
    buffer.writeln('🔒 *Confirmation Advance:* $advanceFormatted via UPI: 9336116210@upi (Balance upon Varanasi arrival)');
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
      backgroundColor: AppColors.getCard(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.getBorder(context)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                        _isB2bMode ? Icons.business_rounded : Icons.auto_awesome,
                        color: const Color(0xFFFBBF24),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isB2bMode ? 'CUSTOM B2B DMC ITINERARY & NET TARIFF' : 'CUSTOMIZABLE ITINERARY & QUOTE BUILDER',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                          Text(
                            '${_isB2bMode ? 'Partner' : 'Client'}: ${widget.lead.name} (${widget.lead.phone})',
                            style: TextStyle(fontSize: 11.5, color: AppColors.getTextSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded, color: AppColors.accentGold, size: 22),
                      tooltip: 'Full Quotation Desk Cockpit',
                      onPressed: () {
                        Navigator.pop(context);
                        QuotationDeskScreen.open(context, widget.lead);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.getTextMuted(context), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // B2C vs B2B Mode Toggle
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.getElevated(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isB2bMode = false;
                              _advanceTokenController.text = '3000';
                              _refreshMessageIfUnedited();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: !_isB2bMode ? AppColors.accentBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '👤 Direct Pilgrim (B2C)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: !_isB2bMode ? Colors.white : AppColors.getTextSecondary(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isB2bMode = true;
                              _advanceTokenController.text = '2000';
                              _refreshMessageIfUnedited();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: _isB2bMode ? const Color(0xFFD97706) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '🏢 Travel Agent (B2B DMC)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _isB2bMode ? Colors.white : AppColors.getTextSecondary(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Tour Circuit Dropdown + Custom Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOUR CIRCUIT / ITINERARY ROUTE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.getTextMuted(context)),
                    ),
                    if (_travelDate != null)
                      Text(
                        'Start: ${DateFormat('dd MMM').format(_travelDate!)}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentGold),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.getElevated(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: AppColors.getElevated(context),
                      value: _circuits.contains(_selectedCircuit) ? _selectedCircuit : _circuits.first,
                      items: _circuits
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: TextStyle(fontSize: 12.5, color: AppColors.getTextPrimary(context))),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCircuit = val;
                            _syncPriceControllers();
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (_selectedCircuit == 'Custom Tour Circuit...') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customCircuitController,
                    style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter custom circuit (e.g. Kashi - Ayodhya - Bodhgaya 5D4N)...',
                      hintStyle: TextStyle(color: AppColors.getTextMuted(context), fontSize: 12),
                      fillColor: AppColors.getElevated(context),
                      filled: true,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accentGold)),
                    ),
                    onChanged: (_) => _refreshMessageIfUnedited(),
                  ),
                ],
                const SizedBox(height: 12),

                // 2. Travel Date & Pax & Hotel Tier Row
                Row(
                  children: [
                    // Travel Date
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _travelDate ?? DateTime.now().add(const Duration(days: 3)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null && mounted) {
                            setState(() {
                              _travelDate = picked;
                              _refreshMessageIfUnedited();
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.getElevated(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _travelDate != null ? AppColors.accentGold : AppColors.getBorder(context)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month, size: 14, color: _travelDate != null ? AppColors.accentGold : AppColors.getTextMuted(context)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _travelDate != null ? DateFormat('dd/MM/yy').format(_travelDate!) : 'Travel Date',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: _travelDate != null ? FontWeight.w700 : FontWeight.w500,
                                    color: _travelDate != null ? AppColors.getTextPrimary(context) : AppColors.getTextMuted(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Pax
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.getElevated(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            dropdownColor: AppColors.getElevated(context),
                            value: [1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 26].contains(_pax) ? _pax : 2,
                            items: [1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 26]
                                .map((p) => DropdownMenuItem(value: p, child: Text('$p Pax', style: TextStyle(fontSize: 12, color: AppColors.getTextPrimary(context)))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _pax = val;
                                  _syncPriceControllers();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Hotel Tier
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.getElevated(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: AppColors.getElevated(context),
                            value: ['3-Star Standard', '4-Star Deluxe', '5-Star Heritage'].contains(_hotelCategory)
                                ? _hotelCategory
                                : '4-Star Deluxe',
                            items: ['3-Star Standard', '4-Star Deluxe', '5-Star Heritage']
                                .map((h) => DropdownMenuItem(value: h, child: Text(h, style: TextStyle(fontSize: 12, color: AppColors.getTextPrimary(context)))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _hotelCategory = val;
                                  _syncPriceControllers();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Specific Hotel Name
                TextField(
                  controller: _hotelNameController,
                  style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Specific Hotel Name (e.g. Ganges Grand / Brijrama Palace)...',
                    hintStyle: TextStyle(color: AppColors.getTextMuted(context), fontSize: 11),
                    fillColor: AppColors.getElevated(context),
                    filled: true,
                    isDense: true,
                    prefixIcon: Icon(Icons.hotel_rounded, size: 14, color: AppColors.getTextMuted(context)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.getBorder(context))),
                  ),
                  onChanged: (_) => _refreshMessageIfUnedited(),
                ),
                const SizedBox(height: 12),

                // 3. Transport Vehicle
                Row(
                  children: [
                    Text('CAB FLEET: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.getTextMuted(context))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.getElevated(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: AppColors.getElevated(context),
                            value: ['Swift Dzire AC', 'Innova Crysta', '12S Force Tempo Traveller'].contains(_cabType)
                                ? _cabType
                                : 'Innova Crysta',
                            items: ['Swift Dzire AC', 'Innova Crysta', '12S Force Tempo Traveller']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 12, color: AppColors.getTextPrimary(context)))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _cabType = val;
                                  _syncPriceControllers();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Dynamic Inclusions & Customizable Activity Pricing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVITIES & VIP ADD-ONS (TAP RATE TO EDIT)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.getTextMuted(context)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => TariffPricingManagerSheet.show(context, onTariffsUpdated: _loadSavedTariffs),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.tune_rounded, size: 12, color: AppColors.accentBlue),
                                const SizedBox(width: 3),
                                Text(
                                  'Manage Tariffs',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentBlue),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _saveCustomTariffs,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.save_rounded, size: 12, color: AppColors.accentGold),
                                const SizedBox(width: 3),
                                Text(
                                  'Save Defaults',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.getAccentGold(context)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.getElevated(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Column(
                    children: [
                      ..._activities.map((act) => _buildActivityRow(act)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _showAddCustomActivityModal(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.getBorder(context), style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.getAccentGold(context)),
                              const SizedBox(width: 6),
                              Text(
                                '+ Add Custom Activity / Service (Custom ₹)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.getAccentGold(context)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Custom Inclusions / Day-wise notes TextField
                TextField(
                  controller: _customInclusionsController,
                  maxLines: 2,
                  style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Additional inclusions or notes (e.g. Jain satvik food, Wheelchair assistance, Sarnath excursion)...',
                    hintStyle: TextStyle(color: AppColors.getTextMuted(context), fontSize: 11),
                    fillColor: AppColors.getElevated(context),
                    filled: true,
                    isDense: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Icon(Icons.note_add_rounded, size: 16, color: AppColors.getTextMuted(context)),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.getBorder(context))),
                  ),
                  onChanged: (_) => _refreshMessageIfUnedited(),
                ),
                const SizedBox(height: 14),

                // 5. Rate Customization & Manual Override Panel
                Container(
                  padding: const EdgeInsets.all(12),
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
                          Row(
                            children: [
                              Icon(
                                _isManualPriceOverride ? Icons.edit_note_rounded : Icons.calculate_rounded,
                                size: 16,
                                color: _isB2bMode ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isManualPriceOverride ? 'CUSTOM PRICE OVERRIDE' : (_isB2bMode ? 'B2B NET TARIFF' : 'PACKAGE QUOTATION'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: _isB2bMode ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isManualPriceOverride = !_isManualPriceOverride;
                                _syncPriceControllers();
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _isManualPriceOverride ? AppColors.accentGold : AppColors.getElevated(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isManualPriceOverride ? Icons.check_circle : Icons.tune_rounded,
                                    size: 12,
                                    color: _isManualPriceOverride ? AppColors.primaryDark : AppColors.getTextPrimary(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isManualPriceOverride ? 'Custom Rate ON' : 'Edit Rate / Price',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: _isManualPriceOverride ? AppColors.primaryDark : AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_isManualPriceOverride) ...[
                        // Editable Total and Per-Pax Fields
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: TextField(
                                controller: _customTotalController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.getTextPrimary(context)),
                                decoration: InputDecoration(
                                  labelText: 'Total Price (₹)',
                                  labelStyle: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                                  fillColor: AppColors.getElevated(context),
                                  filled: true,
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (val) {
                                  final total = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                  if (total > 0 && _pax > 0) {
                                    _customPerPaxController.text = (total / _pax).round().toString();
                                  }
                                  setState(() {});
                                  _refreshMessageIfUnedited();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: _customPerPaxController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(context)),
                                decoration: InputDecoration(
                                  labelText: 'Rate / Pax (₹)',
                                  labelStyle: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                                  fillColor: AppColors.getElevated(context),
                                  filled: true,
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (val) {
                                  final perPax = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                  if (perPax > 0 && _pax > 0) {
                                    _customTotalController.text = (perPax * _pax).toString();
                                  }
                                  setState(() {});
                                  _refreshMessageIfUnedited();
                                },
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              totalFormatted,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.getTextPrimary(context)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                      ],
                      const SizedBox(height: 8),

                      // Advance Token Field
                      Row(
                        children: [
                          const Icon(Icons.lock_clock, size: 14, color: AppColors.accentGold),
                          const SizedBox(width: 6),
                          Text(
                            'Advance Token (₹): ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.getTextSecondary(context)),
                          ),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _advanceTokenController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.w800),
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                prefixStyle: const TextStyle(color: AppColors.accentGold),
                                fillColor: AppColors.getElevated(context),
                                filled: true,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onChanged: (_) {
                                setState(() {});
                                _refreshMessageIfUnedited();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 6. Review & Edit WhatsApp Message Expander
                InkWell(
                  onTap: () {
                    setState(() {
                      _showTextEditor = !_showTextEditor;
                      if (_showTextEditor && _quoteMessageController.text.isEmpty) {
                        _quoteMessageController.text = _generateQuotationText();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.getElevated(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _showTextEditor ? AppColors.accentGold : AppColors.getBorder(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.edit_note, size: 16, color: _showTextEditor ? AppColors.accentGold : AppColors.getTextSecondary(context)),
                            const SizedBox(width: 8),
                            Text(
                              _showTextEditor ? 'Hide WhatsApp Message Editor' : '✏️ Review & Edit WhatsApp Message Before Sending',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _showTextEditor ? AppColors.accentGold : AppColors.getTextPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        Icon(_showTextEditor ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.getTextMuted(context)),
                      ],
                    ),
                  ),
                ),

                if (_showTextEditor) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _quoteMessageController,
                    maxLines: 7,
                    style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 11.5, height: 1.35, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      fillColor: AppColors.getElevated(context),
                      filled: true,
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accentGold)),
                    ),
                    onChanged: (_) {
                      _isMessageManuallyEdited = true;
                    },
                  ),
                ],
                const SizedBox(height: 14),

                // 7. Action Buttons (Copy, Send WhatsApp, Preview Card)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final text = _isMessageManuallyEdited ? _quoteMessageController.text : _generateQuotationText(forceWhiteLabel: _isB2bMode);
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isB2bMode
                                    ? '✓ 100% White-Label Client Proposal copied to clipboard!'
                                    : '✓ Custom quotation copied to clipboard!',
                              ),
                              backgroundColor: AppColors.getCard(context),
                            ),
                          );
                        },
                        icon: Icon(Icons.copy_rounded, size: 15, color: AppColors.getTextPrimary(context)),
                        label: Text(
                          _isB2bMode ? 'Copy White-Label' : 'Copy Quote',
                          style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.getBorder(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final quoteText = _isMessageManuallyEdited ? _quoteMessageController.text : _generateQuotationText();
                          final leadProvider = Provider.of<LeadProvider>(context, listen: false);
                          final apiService = leadProvider.apiService;

                          leadProvider.updateLeadStage(widget.lead.id, 'quote_sent');
                          leadProvider.addLeadNote(
                            widget.lead.id,
                            '⚡ ${_isB2bMode ? "B2B Net Tariff" : "Custom Quotation"} for $_resolvedCircuit ($totalFormatted) dispatched via official WhatsApp.',
                          );

                          // 1. Officially persist quote & booking in WordPress database (wp_tc_agent_quotes & wp_tc_agent_bookings)
                          final contactId = int.tryParse(widget.lead.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          if (contactId > 0) {
                            await apiService.dispatchQuote(
                              contactId: contactId,
                              destination: _resolvedCircuit,
                              tier: _hotelCategory.toLowerCase(),
                              pax: _pax,
                              dealValue: _activePrice.toDouble(),
                              advanceAmount: _advanceToken.toDouble(),
                              message: quoteText,
                            );
                          }

                          // 2. Deliver via official WhatsApp
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
                                      ? '✓ ${_isB2bMode ? "B2B Net Tariff" : "Custom quotation"} sent to ${widget.lead.name} via WhatsApp!'
                                      : '⚠️ Quotation queued for delivery to ${widget.lead.name}',
                                ),
                                backgroundColor: delivered ? AppColors.successGreen : AppColors.getCard(context),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                        label: Text(
                          _isB2bMode ? 'Send B2B Net on WhatsApp' : 'Send WhatsApp Quote',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showBrandedQuotePreview(context),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 15, color: AppColors.accentGold),
                    label: Text(
                      _isB2bMode ? 'Preview White-Label Proposal Card' : 'Preview Branded Proposal Card',
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildActivityRow(ActivityTariffItem item) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: item.isIncluded
            ? (isLight ? const Color(0xFFEFF6FF) : const Color(0xFF1E2D52).withValues(alpha: 0.5))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isIncluded
              ? (isLight ? const Color(0xFFBFDBFE) : const Color(0xFF38BDF8).withValues(alpha: 0.25))
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: item.isIncluded,
              activeColor: isLight ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
              onChanged: (val) {
                setState(() {
                  item.isIncluded = val ?? false;
                  _syncPriceControllers();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: item.isIncluded ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                if (item.subtitle.isNotEmpty)
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 9.5, color: AppColors.getTextMuted(context)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Interactive Price Tag with 1-Tap Edit
          InkWell(
            onTap: () => _showEditActivityPriceModal(context, item),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: item.isIncluded
                    ? (isLight ? const Color(0xFFDBEAFE) : const Color(0xFF0284C7).withValues(alpha: 0.25))
                    : (isLight ? const Color(0xFFF1F5F9) : Colors.white.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isIncluded
                      ? (isLight ? const Color(0xFF60A5FA) : const Color(0xFF38BDF8).withValues(alpha: 0.4))
                      : AppColors.getBorder(context),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.isPerPax
                        ? '₹${NumberFormat('#,##,###').format(item.price)}/pax'
                        : '₹${NumberFormat('#,##,###').format(item.price)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: item.isIncluded
                          ? (isLight ? const Color(0xFF1D4ED8) : const Color(0xFF38BDF8))
                          : AppColors.getTextMuted(context),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.edit_rounded,
                    size: 10.5,
                    color: item.isIncluded
                        ? (isLight ? const Color(0xFF1D4ED8) : const Color(0xFF38BDF8))
                        : AppColors.getTextMuted(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditActivityPriceModal(BuildContext context, ActivityTariffItem item) {
    final priceCtrl = TextEditingController(text: item.price.toString());
    bool tempPerPax = item.isPerPax;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isLight = Theme.of(context).brightness == Brightness.light;
          return AlertDialog(
            backgroundColor: AppColors.getCard(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.getBorder(context)),
            ),
            title: Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.getAccentGold(context), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customize Rate',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(context)),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(context)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(context)),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    labelText: 'Tariff Rate Amount',
                    fillColor: AppColors.getElevated(context),
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Billing Method:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.getTextMuted(context))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => tempPerPax = false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !tempPerPax
                                ? (isLight ? const Color(0xFFDBEAFE) : const Color(0xFF2563EB).withValues(alpha: 0.3))
                                : AppColors.getElevated(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: !tempPerPax ? AppColors.accentBlue : AppColors.getBorder(context)),
                          ),
                          child: Center(
                            child: Text(
                              'Flat (Per Cab/Boat)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: !tempPerPax ? AppColors.accentBlue : AppColors.getTextSecondary(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => tempPerPax = true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: tempPerPax
                                ? (isLight ? const Color(0xFFDBEAFE) : const Color(0xFF2563EB).withValues(alpha: 0.3))
                                : AppColors.getElevated(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tempPerPax ? AppColors.accentBlue : AppColors.getBorder(context)),
                          ),
                          child: Center(
                            child: Text(
                              'Per Pax (x )',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tempPerPax ? AppColors.accentBlue : AppColors.getTextSecondary(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: AppColors.getTextMuted(context))),
              ),
              ElevatedButton(
                onPressed: () {
                  final newPrice = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? item.price;
                  setState(() {
                    item.price = newPrice;
                    item.isPerPax = tempPerPax;
                    item.isIncluded = true;
                    _syncPriceControllers();
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update Rate'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCustomActivityModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '1200');
    bool tempPerPax = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isLight = Theme.of(context).brightness == Brightness.light;
          return AlertDialog(
            backgroundColor: AppColors.getCard(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.getBorder(context)),
            ),
            title: Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add Custom Activity / Service',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.getTextPrimary(context)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: TextStyle(fontSize: 13, color: AppColors.getTextPrimary(context)),
                  decoration: InputDecoration(
                    labelText: 'Activity Name',
                    hintText: 'e.g. Sarnath Buddhist Tour, Rudrabhishek Puja...',
                    fillColor: AppColors.getElevated(context),
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(context)),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    labelText: 'Tariff Rate (₹)',
                    fillColor: AppColors.getElevated(context),
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => tempPerPax = false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !tempPerPax
                                ? (isLight ? const Color(0xFFDBEAFE) : const Color(0xFF2563EB).withValues(alpha: 0.3))
                                : AppColors.getElevated(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: !tempPerPax ? AppColors.accentBlue : AppColors.getBorder(context)),
                          ),
                          child: Center(
                            child: Text(
                              'Flat Rate',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: !tempPerPax ? AppColors.accentBlue : AppColors.getTextSecondary(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => tempPerPax = true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: tempPerPax
                                ? (isLight ? const Color(0xFFDBEAFE) : const Color(0xFF2563EB).withValues(alpha: 0.3))
                                : AppColors.getElevated(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tempPerPax ? AppColors.accentBlue : AppColors.getBorder(context)),
                          ),
                          child: Center(
                            child: Text(
                              'Per Pax (x )',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tempPerPax ? AppColors.accentBlue : AppColors.getTextSecondary(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: AppColors.getTextMuted(context))),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final p = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1000;
                  setState(() {
                    _activities.add(
                      ActivityTariffItem(
                        id: 'custom_',
                        title: title,
                        price: p,
                        isPerPax: tempPerPax,
                        isIncluded: true,
                        isCustom: true,
                      ),
                    );
                    _syncPriceControllers();
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add to Quote'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBrandedQuotePreview(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final totalFormatted = currencyFormatter.format(_activePrice);
    final perPaxFormatted = currencyFormatter.format((_activePrice / _pax).round());
    final quoteId = 'TC-PRP-${DateTime.now().year}-${widget.lead.id.replaceAll(RegExp(r'[^0-9]'), '')}';
    final dateStr = _travelDate != null ? DateFormat('dd MMM yyyy').format(_travelDate!) : 'Dates Flexible';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.getCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(top: BorderSide(color: AppColors.accentGold, width: 2)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.getBorder(context), borderRadius: BorderRadius.circular(2)),
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
                      style: TextStyle(color: AppColors.getTextMuted(context), fontSize: 11),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close, color: AppColors.getTextMuted(context)),
                ),
              ],
            ),
            Divider(color: AppColors.getBorder(context), height: 20),
            Expanded(
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.getElevated(context),
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
                              style: TextStyle(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.w800, fontSize: 15),
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
                            color: AppColors.getCard(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.getBorder(context)),
                          ),
                          child: Text(
                            '$_pax Pilgrims',
                            style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.getElevated(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PILGRIMAGE CIRCUIT & FLEET', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Text(_resolvedCircuit, style: TextStyle(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Travel Date: $dateStr', style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12)),
                        Text('Reserved Cab: $_cabType', style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12)),
                        Text(
                          'Hotel: ${_hotelNameController.text.trim().isNotEmpty ? _hotelNameController.text.trim() : _hotelCategory}',
                          style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.light
                            ? [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]
                            : [const Color(0xFF0F2E1E), const Color(0xFF1E293B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isB2bMode ? 'B2B Net Partner Tariff:' : 'Total Package Investment:',
                              style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 13),
                            ),
                            Text(
                              totalFormatted,
                              style: TextStyle(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rate per Pilgrim:', style: TextStyle(color: AppColors.getTextMuted(context), fontSize: 11)),
                            Text('$perPaxFormatted / person', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                        Divider(color: AppColors.getBorder(context), height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Advance Booking Token:', style: TextStyle(color: AppColors.getTextMuted(context), fontSize: 11)),
                            Text('₹${currencyFormatter.format(_advanceToken)}', style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.accentGold),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.accentGold),
                    label: const Text('Copy Proposal', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generateQuotationText(forceWhiteLabel: _isB2bMode)));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Proposal copied to clipboard!'), backgroundColor: AppColors.successGreen),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                    label: const Text('Send WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: () async {
                      final apiService = Provider.of<LeadProvider>(context, listen: false).apiService;
                      final messenger = ScaffoldMessenger.of(context);
                      final txt = _generateQuotationText(forceWhiteLabel: _isB2bMode);
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                      await apiService.sendWhatsAppMessage(phone: widget.lead.phone, message: txt);
                      messenger.showSnackBar(
                        SnackBar(content: Text('✓ Proposal dispatched via WhatsApp to ${widget.lead.name}!'), backgroundColor: AppColors.successGreen),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
