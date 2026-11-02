import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../models/cab_tariff_item.dart';
import '../providers/lead_provider.dart';
import '../services/cab_tariff_service.dart';
import 'travel_quote_dialog.dart';

class TariffPricingManagerSheet extends StatefulWidget {
  final int initialTab;
  final VoidCallback? onTariffsUpdated;

  const TariffPricingManagerSheet({
    super.key,
    this.initialTab = 0,
    this.onTariffsUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    int initialTab = 0,
    VoidCallback? onTariffsUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TariffPricingManagerSheet(
        initialTab: initialTab,
        onTariffsUpdated: onTariffsUpdated,
      ),
    );
  }

  @override
  State<TariffPricingManagerSheet> createState() => _TariffPricingManagerSheetState();
}

class _TariffPricingManagerSheetState extends State<TariffPricingManagerSheet> {
  late int _selectedTab;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _statusBanner;

  List<CabTariffItem> _cabs = [];
  List<ActivityTariffItem> _activities = [];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadAllTariffs();
  }

  Future<void> _loadAllTariffs() async {
    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<LeadProvider>(context, listen: false).apiService;

      // 1. Load Fleet
      _cabs = await CabTariffService.loadFleet(apiService: apiService);

      // 2. Load Activities
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('tc_custom_activity_tariffs');
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr);
        if (decoded is List && decoded.isNotEmpty) {
          _activities = decoded
              .map((e) => ActivityTariffItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }

      if (_activities.isEmpty) {
        _activities = _getDefaultActivities();
      }

      // Sync activities from server
      final serverTariffs = await apiService.fetchGroundTariffs();
      if (serverTariffs != null && serverTariffs.isNotEmpty) {
        _activities = serverTariffs.map((e) => ActivityTariffItem.fromJson(e)).toList();
        await prefs.setString(
          'tc_custom_activity_tariffs',
          jsonEncode(_activities.map((t) => t.toJson()).toList()),
        );
      }
    } catch (e) {
      debugPrint('Error loading tariffs: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<ActivityTariffItem> _getDefaultActivities() {
    return [
      ActivityTariffItem(
        id: 'sugam_darshan',
        title: 'Kashi Vishwanath VIP Sugam Darshan Pass',
        price: 600,
        isPerPax: true,
        subtitle: 'Direct priest-assisted priority entry via Gate 4 (zero waiting)',
      ),
      ActivityTariffItem(
        id: 'aarti_boat',
        title: 'Dashashwamedh Aarti Reserved Bajra Boat',
        price: 1500,
        isPerPax: false,
        subtitle: 'Reserved viewing deck opposite Main Ganga Maha Aarti',
      ),
      ActivityTariffItem(
        id: 'airport_pickup',
        title: 'Varanasi Airport / Station Pickup & Drop',
        price: 1200,
        isPerPax: false,
        subtitle: 'Dedicated AC commercial cab with placard meet & assist',
      ),
      ActivityTariffItem(
        id: 'subah_e_banaras',
        title: 'Subah-e-Banaras Morning Boat Ride',
        price: 500,
        isPerPax: true,
        subtitle: 'Sunrise boat ride from Assi to Manikarnika Ghat with Vedic chanting',
      ),
      ActivityTariffItem(
        id: 'panda_shastri',
        title: 'Vedic Shastri / Panda Sankalp Pooja',
        price: 1500,
        isPerPax: false,
        subtitle: 'Experienced certified Shastri for family sankalp & abhishek',
      ),
      ActivityTariffItem(
        id: 'sarnath_excursion',
        title: 'Sarnath Buddhist Circuit & Guide',
        price: 1200,
        isPerPax: false,
        subtitle: 'Dhamekh Stupa, Archaeological Museum & expert historian guide',
      ),
    ];
  }

  Future<void> _saveAllTariffs() async {
    setState(() {
      _isSaving = true;
      _statusBanner = null;
    });

    try {
      final apiService = Provider.of<LeadProvider>(context, listen: false).apiService;

      // 1. Save cabs
      final cabsOk = await CabTariffService.saveFleet(_cabs, apiService: apiService);

      // 2. Save activities
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'tc_custom_activity_tariffs',
        jsonEncode(_activities.map((t) => t.toJson()).toList()),
      );
      final actOk = await apiService.saveGroundTariffs(_activities.map((t) => t.toJson()).toList());

      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusBanner = (cabsOk && actOk)
              ? '✓ All Cab Fleet & Activity tariffs synced to Cloud & saved locally!'
              : '✓ Saved locally (Server sync pending)';
        });
        widget.onTariffsUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusBanner = 'Error saving tariffs: $e';
        });
      }
    }
  }

  // ==========================================
  // CAB FLEET MODALS (EDIT & ADD)
  // ==========================================
  void _showEditCabModal(CabTariffItem cab) {
    final nameCtrl = TextEditingController(text: cab.name);
    final capacityCtrl = TextEditingController(text: cab.capacity);
    final surchargeCtrl = TextEditingController(text: cab.packageSurcharge.toString());
    final perKmCtrl = TextEditingController(text: cab.ratePerKm.toString());
    final localCtrl = TextEditingController(text: cab.local8h80k.toString());
    final airportCtrl = TextEditingController(text: cab.airportTransfer.toString());
    final driverDaCtrl = TextEditingController(text: cab.driverDa.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.directions_car_rounded, color: AppColors.getAccentGold(dialogCtx), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customize Cab Tariff',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Vehicle Model / Name', isDark),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: _inputDeco(isDark, hint: 'e.g. Toyota Innova Crysta (Luxury SUV)'),
                  ),
                  const SizedBox(height: 10),

                  _buildFieldLabel('Seating & Luggage Capacity', isDark),
                  TextField(
                    controller: capacityCtrl,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: _inputDeco(isDark, hint: 'e.g. 6-7 Passengers + Driver'),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Quote Surcharge (₹)', isDark),
                            TextField(
                              controller: surchargeCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: AppColors.getAccentGold(dialogCtx),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: _inputDeco(isDark, prefix: '₹ '),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Outstation Rate (₹/km)', isDark),
                            TextField(
                              controller: perKmCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                color: const Color(0xFF38BDF8),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: _inputDeco(isDark, prefix: '₹ ', suffix: '/km'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Local 8h/80km (₹)', isDark),
                            TextField(
                              controller: localCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                              decoration: _inputDeco(isDark, prefix: '₹ '),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Airport Transfer (₹)', isDark),
                            TextField(
                              controller: airportCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                              decoration: _inputDeco(isDark, prefix: '₹ '),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _buildFieldLabel('Driver Daily Allowance / DA (₹/day)', isDark),
                  TextField(
                    controller: driverDaCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: _inputDeco(isDark, prefix: '₹ ', suffix: '/day'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : AppColors.lightTextSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  setState(() {
                    cab.name = name;
                    cab.capacity = capacityCtrl.text.trim();
                    cab.packageSurcharge = int.tryParse(surchargeCtrl.text.trim()) ?? 0;
                    cab.ratePerKm = double.tryParse(perKmCtrl.text.trim()) ?? 12.0;
                    cab.local8h80k = int.tryParse(localCtrl.text.trim()) ?? 1800;
                    cab.airportTransfer = int.tryParse(airportCtrl.text.trim()) ?? 1100;
                    cab.driverDa = int.tryParse(driverDaCtrl.text.trim()) ?? 400;
                  });

                  Navigator.pop(dialogCtx);
                  _saveAllTariffs();
                },
                child: const Text('Save Cab Rates', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCabModal() {
    final nameCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '4-6 Passengers + Driver');
    final surchargeCtrl = TextEditingController(text: '2000');
    final perKmCtrl = TextEditingController(text: '16.0');
    final localCtrl = TextEditingController(text: '2500');
    final airportCtrl = TextEditingController(text: '1600');
    final driverDaCtrl = TextEditingController(text: '450');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: AppColors.getAccentGold(dialogCtx), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add New Cab / Vehicle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Vehicle Model / Name', isDark),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: _inputDeco(isDark, hint: 'e.g. Maruti Suzuki Invicto, Force Urbania 16S...'),
                  ),
                  const SizedBox(height: 10),

                  _buildFieldLabel('Seating & Luggage Capacity', isDark),
                  TextField(
                    controller: capacityCtrl,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: _inputDeco(isDark, hint: 'e.g. 7 Passengers + Driver'),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Quote Surcharge (₹)', isDark),
                            TextField(
                              controller: surchargeCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: AppColors.getAccentGold(dialogCtx),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: _inputDeco(isDark, prefix: '₹ '),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Outstation Rate (₹/km)', isDark),
                            TextField(
                              controller: perKmCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                color: const Color(0xFF38BDF8),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: _inputDeco(isDark, prefix: '₹ ', suffix: '/km'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Local 8h/80km (₹)', isDark),
                            TextField(
                              controller: localCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                              decoration: _inputDeco(isDark, prefix: '₹ '),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Airport Transfer (₹)', isDark),
                            TextField(
                              controller: airportCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                              decoration: _inputDeco(isDark, prefix: '₹ '),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : AppColors.lightTextSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  final newCab = CabTariffItem(
                    id: 'cab_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    capacity: capacityCtrl.text.trim().isNotEmpty ? capacityCtrl.text.trim() : '4 Pax',
                    packageSurcharge: int.tryParse(surchargeCtrl.text.trim()) ?? 0,
                    ratePerKm: double.tryParse(perKmCtrl.text.trim()) ?? 15.0,
                    local8h80k: int.tryParse(localCtrl.text.trim()) ?? 2500,
                    airportTransfer: int.tryParse(airportCtrl.text.trim()) ?? 1500,
                    driverDa: int.tryParse(driverDaCtrl.text.trim()) ?? 450,
                    isActive: true,
                  );

                  setState(() {
                    _cabs.add(newCab);
                  });

                  Navigator.pop(dialogCtx);
                  _saveAllTariffs();
                },
                child: const Text('Add Cab to Fleet', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // ACTIVITY TARIFF MODALS (EDIT & ADD)
  // ==========================================
  void _showEditActivityModal(ActivityTariffItem item) {
    final priceCtrl = TextEditingController(text: item.price.toString());
    final titleCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.subtitle);
    bool isPerPax = item.isPerPax;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppColors.getAccentGold(dialogCtx), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Edit Activity Tariff',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Activity Name', isDark),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: _inputDeco(isDark),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Default Rate (₹ INR)', isDark),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: AppColors.getAccentGold(dialogCtx),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: _inputDeco(isDark, prefix: '₹ '),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Billing Type', isDark),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text('Per Pax (₹/person)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPerPax ? Colors.black : (isDark ? Colors.white : Colors.black87))),
                        selected: isPerPax,
                        selectedColor: AppColors.accentGold,
                        onSelected: (val) => setDialogState(() => isPerPax = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Flat Group (₹ Total)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: !isPerPax ? Colors.black : (isDark ? Colors.white : Colors.black87))),
                        selected: !isPerPax,
                        selectedColor: AppColors.accentGold,
                        onSelected: (val) => setDialogState(() => isPerPax = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Description / Inclusions', isDark),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 12),
                    decoration: _inputDeco(isDark, hint: 'Brief description...'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : AppColors.lightTextSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final newPrice = int.tryParse(priceCtrl.text.trim()) ?? item.price;
                  final newTitle = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : item.title;
                  final newDesc = descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : item.subtitle;

                  setState(() {
                    item.price = newPrice;
                    item.title = newTitle;
                    item.subtitle = newDesc;
                    item.isPerPax = isPerPax;
                  });

                  Navigator.pop(dialogCtx);
                  _saveAllTariffs();
                },
                child: const Text('Update Rate', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddActivityModal() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '1000');
    final descCtrl = TextEditingController();
    bool isPerPax = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: AppColors.getAccentGold(dialogCtx), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Add Custom Ground Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Activity / Service Name', isDark),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: _inputDeco(isDark, hint: 'e.g. Sarnath Historian Guide, Rudrabhishek Puja...'),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Default Rate (₹ INR)', isDark),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: AppColors.getAccentGold(dialogCtx),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: _inputDeco(isDark, prefix: '₹ '),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Billing Type', isDark),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text('Flat Group (₹ Total)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: !isPerPax ? Colors.black : (isDark ? Colors.white : Colors.black87))),
                        selected: !isPerPax,
                        selectedColor: AppColors.accentGold,
                        onSelected: (val) => setDialogState(() => isPerPax = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Per Pax (₹/person)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPerPax ? Colors.black : (isDark ? Colors.white : Colors.black87))),
                        selected: isPerPax,
                        selectedColor: AppColors.accentGold,
                        onSelected: (val) => setDialogState(() => isPerPax = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Description (Optional)', isDark),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 12),
                    decoration: _inputDeco(isDark, hint: 'What is included in this service...'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : AppColors.lightTextSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final price = int.tryParse(priceCtrl.text.trim()) ?? 1000;
                  final desc = descCtrl.text.trim();

                  final newItem = ActivityTariffItem(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    subtitle: desc.isNotEmpty ? desc : 'Custom activity inclusion',
                    price: price,
                    isPerPax: isPerPax,
                    isIncluded: true,
                  );

                  setState(() {
                    _activities.add(newItem);
                  });

                  Navigator.pop(dialogCtx);
                  _saveAllTariffs();
                },
                child: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _copyCompleteMasterTariffSheet() {
    final buffer = StringBuffer();
    buffer.writeln('🏢 *TRIPCOSMOS VARANASI — MASTER GROUND & CAB TARIFF SHEET (2026)*');
    buffer.writeln('────────────────────────────────────────');
    buffer.writeln('🤝 *100% White-Label Ground Handling (Your Agency Placard)*\n');

    buffer.writeln('🚗 *DEDICATED UP65 COMMERCIAL CAB & FLEET RATES:*');
    for (final cab in _cabs.where((c) => c.isActive)) {
      buffer.writeln('• *${cab.name}* (${cab.capacity}):');
      buffer.writeln('  ▫ Outstation: ₹${cab.ratePerKm}/km | Local (8h/80km): ₹${NumberFormat('#,##,###').format(cab.local8h80k)}');
      buffer.writeln('  ▫ Airport Transfer: ₹${NumberFormat('#,##,###').format(cab.airportTransfer)} | Driver DA: ₹${cab.driverDa}/day');
      if (cab.packageSurcharge > 0) {
        buffer.writeln('  ▫ Itinerary Quote Surcharge: +₹${NumberFormat('#,##,###').format(cab.packageSurcharge)}');
      }
    }

    buffer.writeln('\n⛩️ *GROUND ACTIVITIES, BOATS & DARSHAN ADD-ONS:*');
    for (final act in _activities) {
      final billing = act.isPerPax ? 'per pax' : 'total flat';
      buffer.writeln('• *${act.title}*: ₹${NumberFormat('#,##,###').format(act.price)} ($billing)');
      if (act.subtitle.isNotEmpty) {
        buffer.writeln('  _${act.subtitle}_');
      }
    }

    buffer.writeln('────────────────────────────────────────');
    buffer.writeln('📞 *Varanasi B2B Partner Desk:* +91 93361 16210 (Jio 5G Master)');
    buffer.writeln('🌐 *Live Operations Portal:* https://tripcosmos.co');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Master Cab Fleet & Activity Tariff Sheet copied to clipboard!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLight = !isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.getAccentGold(context), width: 2)),
        boxShadow: [
          if (isLight)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getAccentGold(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded, color: AppColors.getAccentGold(context), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Master Ground & Fleet Tariff Manager',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Customize cab fleet prices, activity rates & cloud sync',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: isDark ? Colors.white70 : AppColors.lightTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(color: isDark ? Colors.white12 : AppColors.lightBorderSubtle, height: 1),

          // Status Banner (if any)
          if (_statusBanner != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              child: Text(
                _statusBanner!,
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11.5, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          // Segmented Tabs: Cabs vs Activities
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : AppColors.lightBorderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 0),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? (isDark ? AppColors.accentGold : const Color(0xFFB45309))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car_rounded,
                              size: 16,
                              color: _selectedTab == 0 ? Colors.white : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '🚕 Cab Fleet (${_cabs.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _selectedTab == 0 ? Colors.white : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTab = 1),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? (isDark ? AppColors.accentGold : const Color(0xFFB45309))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.temple_hindu_rounded,
                              size: 16,
                              color: _selectedTab == 1 ? Colors.white : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '⛩️ Activities (${_activities.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _selectedTab == 1 ? Colors.white : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_selectedTab == 0 ? _buildCabsList(isDark) : _buildActivitiesList(isDark)),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: isDark ? Colors.white12 : AppColors.lightBorderSubtle)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _copyCompleteMasterTariffSheet,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Tariff Card'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    side: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAllTariffs,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.cloud_sync_rounded, size: 18),
                    label: Text(_isSaving ? 'Syncing...' : 'Save & Cloud Sync'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CABS LIST VIEW
  // ==========================================
  Widget _buildCabsList(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE CAB FLEET & VEHICLE PRICING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                letterSpacing: 0.5,
              ),
            ),
            InkWell(
              onTap: _showAddCabModal,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getAccentGold(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.getAccentGold(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 13, color: AppColors.getAccentGold(context)),
                    const SizedBox(width: 4),
                    Text(
                      '+ Add New Cab',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.getAccentGold(context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ..._cabs.map((cab) => _buildCabCard(cab, isDark)),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCabCard(CabTariffItem cab, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cab.isActive
              ? (isDark ? Colors.white12 : AppColors.lightBorderSubtle)
              : Colors.red.withValues(alpha: 0.3),
        ),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_car_rounded, size: 20, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cab.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          cab.capacity,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (cab.packageSurcharge > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.getAccentGold(context).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+₹${NumberFormat('#,##,###').format(cab.packageSurcharge)} Quote',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.getAccentGold(context)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_note_rounded, color: AppColors.getAccentGold(context), size: 22),
                tooltip: 'Customize Cab Rates',
                onPressed: () => _showEditCabModal(cab),
              ),
              if (cab.id.startsWith('cab_'))
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Remove Custom Cab',
                  onPressed: () {
                    setState(() => _cabs.remove(cab));
                    _saveAllTariffs();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: isDark ? Colors.white10 : AppColors.lightBorderSubtle, height: 1),
          const SizedBox(height: 8),

          // 3-Metric Rate Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricPill('Outstation', '₹${cab.ratePerKm}/km', const Color(0xFF38BDF8), isDark),
              _buildMetricPill('Local 8h/80k', '₹${NumberFormat('#,##,###').format(cab.local8h80k)}', const Color(0xFF10B981), isDark),
              _buildMetricPill('Airport Transfer', '₹${NumberFormat('#,##,###').format(cab.airportTransfer)}', const Color(0xFFF59E0B), isDark),
              _buildMetricPill('Driver DA', '₹${cab.driverDa}/day', const Color(0xFFA855F7), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color accent, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: isDark ? Colors.white54 : AppColors.lightTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ACTIVITIES LIST VIEW
  // ==========================================
  Widget _buildActivitiesList(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GROUND ACTIVITIES & DARSHAN ADD-ONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                letterSpacing: 0.5,
              ),
            ),
            InkWell(
              onTap: _showAddActivityModal,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getAccentGold(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.getAccentGold(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 13, color: AppColors.getAccentGold(context)),
                    const SizedBox(width: 4),
                    Text(
                      '+ Add Custom',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.getAccentGold(context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ..._activities.map((act) => _buildActivityCard(act, isDark)),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActivityCard(ActivityTariffItem act, bool isDark) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.getAccentGold(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.temple_hindu_rounded, size: 18, color: AppColors.getAccentGold(context)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  act.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    act.isPerPax
                        ? '₹${NumberFormat('#,##,###').format(act.price)} / pax'
                        : '₹${NumberFormat('#,##,###').format(act.price)} Total Flat',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: AppColors.getAccentGold(context), size: 22),
            tooltip: 'Edit Activity Rate',
            onPressed: () => _showEditActivityModal(act),
          ),
          if (act.id.startsWith('custom_'))
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              tooltip: 'Delete Custom Activity',
              onPressed: () {
                setState(() => _activities.remove(act));
                _saveAllTariffs();
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================
  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(bool isDark, {String? hint, String? prefix, String? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      suffixText: suffix,
      filled: true,
      fillColor: isDark ? AppColors.surfaceCard : const Color(0xFFF1F5F9),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.lightBorderSubtle),
      ),
    );
  }
}
