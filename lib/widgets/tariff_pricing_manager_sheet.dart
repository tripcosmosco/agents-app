import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../providers/lead_provider.dart';
import 'travel_quote_dialog.dart';

class TariffPricingManagerSheet extends StatefulWidget {
  final VoidCallback? onTariffsUpdated;

  const TariffPricingManagerSheet({super.key, this.onTariffsUpdated});

  static Future<void> show(BuildContext context, {VoidCallback? onTariffsUpdated}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TariffPricingManagerSheet(onTariffsUpdated: onTariffsUpdated),
    );
  }

  @override
  State<TariffPricingManagerSheet> createState() => _TariffPricingManagerSheetState();
}

class _TariffPricingManagerSheetState extends State<TariffPricingManagerSheet> {
  bool _isLoading = false;
  bool _isSaving = false;
  String? _statusBanner;
  List<ActivityTariffItem> _tariffs = [];

  @override
  void initState() {
    super.initState();
    _loadTariffs();
  }

  Future<void> _loadTariffs() async {
    setState(() => _isLoading = true);

    // 1. Load from local cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('tc_custom_activity_tariffs');
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr);
        if (decoded is List) {
          _tariffs = decoded
              .map((e) => ActivityTariffItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached tariffs: $e');
    }

    if (_tariffs.isEmpty) {
      _tariffs = _getDefaultTariffs();
    }

    // 2. Fetch latest from backend API (/mobile/tariffs)
    try {
      if (!mounted) return;
      final apiService = Provider.of<LeadProvider>(context, listen: false).apiService;
      final serverTariffs = await apiService.fetchGroundTariffs();
      if (serverTariffs != null && serverTariffs.isNotEmpty && mounted) {
        final loaded = serverTariffs
            .map((e) => ActivityTariffItem.fromJson(e))
            .toList();
        if (loaded.isNotEmpty) {
          _tariffs = loaded;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('tc_custom_activity_tariffs', jsonEncode(_tariffs.map((t) => t.toJson()).toList()));
        }
      }
    } catch (e) {
      debugPrint('Error syncing tariffs from server: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<ActivityTariffItem> _getDefaultTariffs() {
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

  Future<void> _saveAndSyncTariffs() async {
    setState(() {
      _isSaving = true;
      _statusBanner = null;
    });

    try {
      // 1. Save to SharedPreferences (offline cache)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tc_custom_activity_tariffs', jsonEncode(_tariffs.map((t) => t.toJson()).toList()));

      // 2. Sync to WordPress REST API
      if (!mounted) return;
      final apiService = Provider.of<LeadProvider>(context, listen: false).apiService;
      final ok = await apiService.saveGroundTariffs(_tariffs.map((t) => t.toJson()).toList());

      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusBanner = ok ? '✓ Rates synced to Cloud and saved locally!' : '✓ Saved locally (Server offline)';
        });
        widget.onTariffsUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusBanner = 'Error saving: $e';
        });
      }
    }
  }

  void _showEditTariffModal(ActivityTariffItem item) {
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
                  Text(
                    'Activity Name',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceCard : const Color(0xFFF1F5F9),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Default Rate (₹ INR)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: AppColors.getAccentGold(dialogCtx),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        color: AppColors.getAccentGold(dialogCtx),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceCard : const Color(0xFFF1F5F9),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pricing Mode',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Per Guest (/pax)'),
                          selected: isPerPax,
                          selectedColor: AppColors.getAccentGold(dialogCtx),
                          onSelected: (val) {
                            if (val) setDialogState(() => isPerPax = true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Flat / Group'),
                          selected: !isPerPax,
                          selectedColor: AppColors.getAccentGold(dialogCtx),
                          onSelected: (val) {
                            if (val) setDialogState(() => isPerPax = false);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Description / Note',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: TextStyle(color: isDark ? Colors.white70 : AppColors.lightTextPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceCard : const Color(0xFFF1F5F9),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getAccentGold(dialogCtx),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final newPrice = int.tryParse(priceCtrl.text) ?? item.price;
                  setState(() {
                    item.title = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : item.title;
                    item.price = newPrice;
                    item.isPerPax = isPerPax;
                    item.subtitle = descCtrl.text.trim();
                  });
                  _saveAndSyncTariffs();
                  Navigator.pop(ctx);
                },
                child: const Text('Update Rate'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCustomActivityModal() {
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
                  'Add Custom Activity Tariff',
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
                  Text(
                    'Activity Name',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. Sarnath Wheelchair & Attendant',
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceCard : const Color(0xFFF1F5F9),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Default Tariff (₹ INR)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: AppColors.getAccentGold(dialogCtx),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        color: AppColors.getAccentGold(dialogCtx),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceCard : const Color(0xFFF1F5F9),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pricing Calculation Mode',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Flat / Group'),
                          selected: !isPerPax,
                          selectedColor: AppColors.getAccentGold(dialogCtx),
                          onSelected: (val) {
                            if (val) setDialogState(() => isPerPax = false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Per Guest (/pax)'),
                          selected: isPerPax,
                          selectedColor: AppColors.getAccentGold(dialogCtx),
                          onSelected: (val) {
                            if (val) setDialogState(() => isPerPax = true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getAccentGold(dialogCtx),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final price = int.tryParse(priceCtrl.text) ?? 1000;
                  final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';

                  setState(() {
                    _tariffs.add(ActivityTariffItem(
                      id: newId,
                      title: title,
                      price: price,
                      isPerPax: isPerPax,
                      subtitle: descCtrl.text.trim(),
                    ));
                  });
                  _saveAndSyncTariffs();
                  Navigator.pop(ctx);
                },
                child: const Text('Add Activity'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _copyMasterTariffSheet() {
    final buffer = StringBuffer();
    buffer.writeln('📋 *TRIPCOSMOS WHOLESALE GROUND TARIFFS & DMC RATE CARD*');
    buffer.writeln('Destination: Varanasi & Sacred Circuit • Verified Partner Rates\n');

    for (final item in _tariffs) {
      final mode = item.isPerPax ? '/pax' : ' flat / per group';
      buffer.writeln('• *${item.title}:* ₹${item.price}$mode');
      if (item.subtitle.isNotEmpty) {
        buffer.writeln('  _${item.subtitle}_');
      }
    }

    buffer.writeln('\n👉 *B2B Partner Portal:* https://tripcosmos.co/b2b/');
    buffer.writeln('📞 *24/7 Operations Desk:* +91 93361 16210');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Master B2B Tariff Sheet copied to clipboard!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.getAccentGold(context), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getAccentGold(context).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.price_change_rounded, color: AppColors.getAccentGold(context), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ground Tariffs & Activity Pricing Manager',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Set default rates for Itinerary Builder & B2B DMC Quotes',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
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
          const Divider(height: 1),

          // Status & Action Strip
          if (_statusBanner != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              child: Text(
                _statusBanner!,
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          // Tariffs List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.getAccentGold(context)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tariffs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = _tariffs[idx];
                      final isCustom = item.id.startsWith('custom_');

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceCard : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white12 : AppColors.lightBorderSubtle),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: AppColors.getAccentGold(context).withValues(alpha: 0.15),
                              child: Icon(
                                item.id.contains('boat')
                                    ? Icons.directions_boat_rounded
                                    : (item.id.contains('darshan')
                                        ? Icons.temple_hindu_rounded
                                        : (item.id.contains('airport') ? Icons.local_taxi_rounded : Icons.star_rounded)),
                                color: AppColors.getAccentGold(context),
                                size: 18,
                              ),
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
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ),
                                      if (isCustom)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            setState(() => _tariffs.removeAt(idx));
                                            _saveAndSyncTariffs();
                                          },
                                        ),
                                    ],
                                  ),
                                  if (item.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      item.subtitle,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _showEditTariffModal(item),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.getAccentGold(context).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppColors.getAccentGold(context).withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '₹${item.price}${item.isPerPax ? " / pax" : " flat"}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.getAccentGold(context),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.edit, size: 12, color: AppColors.getAccentGold(context)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.isPerPax ? 'Per Guest' : 'Flat Cab / Group',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
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

          // Bottom Action Footer
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.lightBorderSubtle)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showAddCustomActivityModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Activity'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.getAccentGold(context),
                    side: BorderSide(color: AppColors.getAccentGold(context)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _copyMasterTariffSheet,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Sheet'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                    side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAndSyncTariffs,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_rounded, size: 16),
                  label: Text(_isSaving ? 'Syncing...' : 'Sync to Cloud'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
