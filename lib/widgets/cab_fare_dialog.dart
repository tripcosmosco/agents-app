import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/lead_model.dart';
import '../providers/whatsapp_provider.dart';

class CabFareDialog extends StatefulWidget {
  final LeadModel? lead;

  const CabFareDialog({super.key, this.lead});

  static void show(BuildContext context, {LeadModel? lead}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CabFareDialog(lead: lead),
    );
  }

  @override
  State<CabFareDialog> createState() => _CabFareDialogState();
}

class _CabFareDialogState extends State<CabFareDialog> {
  String _origin = 'Varanasi';
  String _destination = 'Ayodhya';
  String _vehicleKey = 'innova';
  int _days = 2;
  bool _isRoundTrip = true;

  final List<String> _origins = [
    'Varanasi',
    'Ayodhya',
    'Prayagraj',
    'Lucknow',
    'Bodhgaya',
    'Delhi',
  ];

  final List<String> _destinations = [
    'Ayodhya',
    'Prayagraj',
    'Bodhgaya',
    'Chitrakoot',
    'Lucknow',
    'Gorakhpur',
    'Local Darshan (8h/80km)',
    'Airport Transfer',
  ];

  static const Map<String, Map<String, dynamic>> _fleet = {
    'sedan': {
      'name': 'AC Sedan (Swift Dzire)',
      'rate': 12.0,
      'capacity': '4 Pax',
      'min_km': 250,
      'da': 400.0,
      'local': 1800.0,
      'airport': 1100.0,
    },
    'ertiga': {
      'name': 'Maruti Ertiga / XL6',
      'rate': 15.0,
      'capacity': '6 Pax',
      'min_km': 250,
      'da': 400.0,
      'local': 2400.0,
      'airport': 1500.0,
    },
    'innova': {
      'name': 'Toyota Innova Crysta',
      'rate': 19.0,
      'capacity': '6-7 Pax',
      'min_km': 250,
      'da': 450.0,
      'local': 3000.0,
      'airport': 2000.0,
    },
    'tempo_12': {
      'name': 'Force Tempo (12 Seater)',
      'rate': 25.0,
      'capacity': '12 Pax',
      'min_km': 250,
      'da': 500.0,
      'local': 4500.0,
      'airport': 3000.0,
    },
    'tempo_17': {
      'name': 'Force Tempo (17 Seater)',
      'rate': 28.0,
      'capacity': '17-20 Pax',
      'min_km': 300,
      'da': 600.0,
      'local': 5500.0,
      'airport': 3800.0,
    },
    'tempo_26': {
      'name': 'Luxury Mini-Bus (26S)',
      'rate': 35.0,
      'capacity': '26 Pax',
      'min_km': 300,
      'da': 700.0,
      'local': 7000.0,
      'airport': 5000.0,
    },
  };

  static const Map<String, int> _distances = {
    'varanasi_ayodhya': 220,
    'varanasi_prayagraj': 125,
    'varanasi_bodhgaya': 250,
    'varanasi_chitrakoot': 260,
    'varanasi_lucknow': 310,
    'varanasi_gorakhpur': 200,
    'ayodhya_prayagraj': 165,
    'ayodhya_lucknow': 135,
    'prayagraj_chitrakoot': 130,
    'lucknow_prayagraj': 200,
    'bodhgaya_prayagraj': 360,
    'delhi_varanasi': 820,
    'delhi_ayodhya': 680,
  };

  @override
  void initState() {
    super.initState();
    if (widget.lead != null) {
      final dest = widget.lead!.destination.toLowerCase();
      if (dest.contains('ayodhya')) {
        _destination = 'Ayodhya';
      } else if (dest.contains('prayagraj') || dest.contains('allahabad')) {
        _destination = 'Prayagraj';
      } else if (dest.contains('gaya') || dest.contains('bodhgaya')) {
        _destination = 'Bodhgaya';
      } else if (dest.contains('local') || dest.contains('kashi')) {
        _destination = 'Local Darshan (8h/80km)';
      }

      if (widget.lead!.pax > 6) {
        _vehicleKey = 'tempo_12';
      } else if (widget.lead!.pax > 4) {
        _vehicleKey = 'ertiga';
      } else if (widget.lead!.pax <= 2) {
        _vehicleKey = 'sedan';
      } else {
        _vehicleKey = 'innova';
      }
    }
  }

  Map<String, dynamic> _computeFare() {
    final v = _fleet[_vehicleKey]!;
    final vName = v['name'] as String;
    final rate = double.tryParse(v['rate']?.toString() ?? '0') ?? 0.0;
    final minDaily = int.tryParse(v['min_km']?.toString() ?? '0') ?? 0;
    final da = double.tryParse(v['da']?.toString() ?? '0') ?? 0.0;

    if (_destination == 'Airport Transfer') {
      final fare = (double.tryParse(v['airport']?.toString() ?? '0') ?? 0.0).toInt();
      return {
        'total': fare,
        'title': 'Airport Transfer (Varanasi)',
        'vehicle': vName,
        'details': 'Chilled AC private cab with meet & greet at terminal',
        'distance': '30 km',
        'da': 'Included',
        'tolls': 'Included',
      };
    }

    if (_destination == 'Local Darshan (8h/80km)') {
      final fare = ((double.tryParse(v['local']?.toString() ?? '0') ?? 0.0) * _days).toInt();
      return {
        'total': fare,
        'title': 'Varanasi Local Darshan ($_days Day${_days > 1 ? 's' : ''})',
        'vehicle': vName,
        'details': '8 Hours / 80 Km per day • Kashi Vishwanath, Sankat Mochan, Sarnath, Ghats',
        'distance': '${80 * _days} km',
        'da': 'Included',
        'tolls': 'Parking actuals',
      };
    }

    // Outstation
    final key1 = '${_origin.toLowerCase()}_${_destination.toLowerCase()}';
    final key2 = '${_destination.toLowerCase()}_${_origin.toLowerCase()}';
    int oneWayKm = _distances[key1] ?? _distances[key2] ?? 200;
    int totalRunKm = _isRoundTrip ? (oneWayKm * 2) : oneWayKm;
    int billableKm = (totalRunKm < minDaily * _days) ? (minDaily * _days) : totalRunKm;

    double kmFare = billableKm * rate;
    double daTotal = da * _days;
    int grandTotal = (kmFare + daTotal).toInt();

    return {
      'total': grandTotal,
      'title': '$_origin to $_destination (${_isRoundTrip ? 'Round Trip' : 'One Way'})',
      'vehicle': vName,
      'details': '$billableKm Billable Km (@ ₹${rate.toInt()}/km) + Driver DA (₹${da.toInt()}/day)',
      'distance': '$billableKm km',
      'da': '₹${daTotal.toInt()}',
      'tolls': '₹${_isRoundTrip ? 500 : 250} (approx.)',
    };
  }

  String _formatWhatsAppQuote(Map<String, dynamic> fare) {
    final curFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final totalStr = curFmt.format(fare['total']);

    return '''
*TripCosmos Cab Quotation* 🚕
──────────────────
📍 *Route:* ${fare['title']}
🚘 *Vehicle:* ${fare['vehicle']}
⏱️ *Duration:* $_days Day(s) (${_isRoundTrip ? 'Round Trip' : 'One Way'})
🛣️ *Chargeable Distance:* ${fare['distance']}
💰 *All-Inclusive Tariff:* *$totalStr*

*Inclusions:*
✔️ Dedicated Clean & Chilled AC Vehicle
✔️ Experienced Verified Tourist Chauffeur
✔️ Fuel Charges & Driver Daily Allowance (DA)
✔️ 24x7 TripCosmos Varanasi Control Desk Support

*Exclusions:* Expressway Tolls & Parking slips (as per actuals).
──────────────────
_To confirm this cab, reply *YES* or pay ₹1,000 booking token advance._
'''.trim();
  }

  @override
  Widget build(BuildContext context) {
    final fare = _computeFare();
    final curFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Dialog(
      backgroundColor: AppColors.getCard(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.getBorder(context)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_taxi_rounded, color: Color(0xFFF59E0B), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cab Fare & Circuit Calculator',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Instant verified tariffs for UP & Bihar circuits',
                          style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.getTextMuted(context), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Route Selectors (Origin & Destination)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ORIGIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.getTextMuted(context))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.getElevated(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.getBorder(context)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _origin,
                              isExpanded: true,
                              dropdownColor: AppColors.getElevated(context),
                              style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13, fontWeight: FontWeight.w600),
                              items: _origins.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _origin = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Icon(Icons.arrow_forward, color: AppColors.getTextMuted(context), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DESTINATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.getTextMuted(context))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.getElevated(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.getBorder(context)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _destination,
                              isExpanded: true,
                              dropdownColor: AppColors.getElevated(context),
                              style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13, fontWeight: FontWeight.w600),
                              items: _destinations.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _destination = val);
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

              // Fleet Vehicle Selection
              Text('FLEET VEHICLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.getTextMuted(context))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.getElevated(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _vehicleKey,
                    isExpanded: true,
                    dropdownColor: AppColors.getElevated(context),
                    style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13, fontWeight: FontWeight.w600),
                    items: _fleet.entries.map((e) {
                      final name = e.value['name'] as String;
                      final cap = e.value['capacity'] as String;
                      final rate = (double.tryParse(e.value['rate']?.toString() ?? '0') ?? 0.0).toInt();
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          '$name ($cap) • ₹$rate/km',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _vehicleKey = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Trip Days and Round-Trip Controls
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRIP DURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.getTextMuted(context))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.getElevated(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.getBorder(context)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove, color: AppColors.getTextSecondary(context), size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  if (_days > 1) setState(() => _days--);
                                },
                              ),
                              Text('$_days Day${_days > 1 ? 's' : ''}', style: TextStyle(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.w700, fontSize: 13)),
                              IconButton(
                                icon: Icon(Icons.add, color: AppColors.getTextSecondary(context), size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setState(() => _days++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRIP TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.getTextMuted(context))),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () {
                            if (_destination != 'Airport Transfer' && _destination != 'Local Darshan (8h/80km)') {
                              setState(() => _isRoundTrip = !_isRoundTrip);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.getElevated(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.getBorder(context)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isRoundTrip ? Icons.sync_alt : Icons.arrow_right_alt,
                                  color: AppColors.accentBlue,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isRoundTrip ? 'Round Trip' : 'One Way',
                                  style: TextStyle(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.w700, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Computed Estimate Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.light
                        ? [const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)]
                        : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ALL-INCLUSIVE ESTIMATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.accentGold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Verified Tariff',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.successGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      curFmt.format(fare['total']),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fare['details'] as String,
                      style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context)),
                    ),
                    Divider(color: AppColors.getBorder(context), height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Distance: ${fare['distance']}', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context))),
                        Text('DA: ${fare['da']}', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context))),
                        Text('Tolls: ${fare['tolls']}', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons: Copy Quote & Send WhatsApp
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final text = _formatWhatsAppQuote(fare);
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Cab quotation copied to clipboard!'),
                            backgroundColor: AppColors.getCard(context),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: Icon(Icons.copy, size: 16, color: AppColors.getTextPrimary(context)),
                      label: Text('Copy Quote', style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.getBorder(context)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final text = _formatWhatsAppQuote(fare);
                        if (widget.lead != null) {
                          final wpProvider = Provider.of<WhatsAppProvider>(context, listen: false);
                          final thread = wpProvider.getOrCreateThread(
                            customerPhone: widget.lead!.phone,
                            customerName: widget.lead!.name,
                            circuit: widget.lead!.destination.isNotEmpty ? widget.lead!.destination : 'Cab Booking',
                          );
                          await wpProvider.sendMessage(thread.id, text);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Cab quote sent to ${widget.lead!.name} via WhatsApp!'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          await Clipboard.setData(ClipboardData(text: text));
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Quote copied! Select a lead to send directly.'),
                                backgroundColor: AppColors.getCard(context),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      label: const Text('Send WhatsApp', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int maxInt(int a, int b) => a > b ? a : b;
}
