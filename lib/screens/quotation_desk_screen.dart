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

class _ItineraryPlan {
  final String title;
  final List<String> highlights;

  const _ItineraryPlan({required this.title, required this.highlights});
}

class _QuotationDeskScreenState extends State<QuotationDeskScreen> {
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _hotelNameCtrl = TextEditingController();
  final _customInclusionsCtrl = TextEditingController();
  final _advanceTokenCtrl = TextEditingController(text: '3000');
  final _customTotalCtrl = TextEditingController();

  // Duration State: 2D/1N, 3D/2N, 4D/3N, 5D/4N
  int _selectedDays = 3;
  int _selectedNights = 2;

  String _selectedCircuit = 'Varanasi 3D2N Spiritual Essence (Bestseller)';
  int _pax = 2;
  String _hotelCategory = '4-Star Deluxe';
  String _cabType = 'Innova Crysta';
  DateTime? _travelDate;

  bool _includeDayWiseItinerary = true;
  bool _includeSugamDarshan = true;
  bool _includeAartiBoat = true;
  bool _includeAirportPickup = true;
  bool _includeSubahEBanaras = true;
  bool _includePandaShastri = false;
  bool _isB2bMode = false;
  bool _isManualPrice = false;
  bool _showLivePreview = false;

  // Circuit catalog by duration
  final Map<int, List<String>> _circuitsByDays = {
    2: [
      'Varanasi Local 2D1N Spiritual Darshan & Ghats',
      'Prayagraj Sangam Express Excursion (2D1N)',
    ],
    3: [
      'Varanasi 3D2N Spiritual Essence (Bestseller)',
      'Dev Deepawali 2026 Special 3D2N Allocation',
      'Ayodhya Ram Mandir & Kashi 3D2N Fast-Track',
    ],
    4: [
      'Varanasi + Ayodhya Ram Mandir 4D3N Circuit',
      'Varanasi + Prayagraj Triveni Sangam 4D3N Circuit',
      'Kashi - Gaya - Bodhgaya 4D3N Pind Daan Circuit',
    ],
    5: [
      'The Holy Trinity: Varanasi - Prayagraj - Ayodhya 5D4N',
      'Grand Spiritual Yatra: Kashi - Bodhgaya - Ayodhya 5D4N',
    ],
  };

  // Pre-compiled Day-by-Day Itineraries audited from live WordPress packages
  Map<String, List<_ItineraryPlan>> get _itineraryCatalog => {
    'Varanasi Local 2D1N Spiritual Darshan & Ghats': const [
      _ItineraryPlan(
        title: 'Day 1: Arrival, Kashi Vishwanath VIP Darshan & Ganga Aarti',
        highlights: [
          'Arrival transfer from Varanasi Airport (VNS) / Cantt Railway Station in private AC cab.',
          'Hotel check-in & refreshment.',
          'Shri Kashi Vishwanath VIP Sugam Darshan (Gate 4 Corridor - Zero line waiting).',
          'Darshan at Maa Annapurna Mandir & Mata Vishalakshi Shaktipeeth.',
          'Evening Dashashwamedh Ghat Grand Ganga Aarti from private reserved Bajra boat deck.',
          'Night stay in Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 2: Subah-e-Banaras Sunrise Boat, Kaal Bhairav, Sarnath & Departure',
        highlights: [
          'Early morning Subah-e-Banaras sunrise boat ride (Assi Ghat to Manikarnika Ghat).',
          'Vedic rituals, morning chants & visit to Akhada.',
          'Kotwal of Kashi Baba Kaal Bhairav Mandir darshan.',
          'Excursion to Sarnath: Dhamek Stupa, Mulgandha Kuti Vihar & Museum.',
          'Live master artisan Banarasi Silk saree weaving workshop.',
          'Timely chauffeur drop at Airport / Railway Station with holy blessings.',
        ],
      ),
    ],
    'Prayagraj Sangam Express Excursion (2D1N)': const [
      _ItineraryPlan(
        title: 'Day 1: Varanasi Arrival & Kashi Vishwanath Darshan',
        highlights: [
          'Pickup from Varanasi & hotel check-in.',
          'Kashi Vishwanath VIP Sugam Darshan & Evening Ganga Aarti boat.',
          'Overnight Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 2: Prayagraj Sangam Holy Dip & Departure',
        highlights: [
          'Morning highway drive to Prayagraj Triveni Sangam.',
          'Holy boat ride to Sangam point for sacred snan.',
          'Bade Hanuman Ji Mandir (Reclining idol) & Alopi Devi Shaktipeeth.',
          'Return drive & departure transfer from Varanasi.',
        ],
      ),
    ],
    'Varanasi 3D2N Spiritual Essence (Bestseller)': const [
      _ItineraryPlan(
        title: 'Day 1: Sacred Arrival, Kashi Vishwanath Jyotirlinga & Grand Ganga Aarti',
        highlights: [
          'Chauffeur welcome at Airport / Cantt Railway Station with personalized placard.',
          'Smooth check-in at chosen accommodation.',
          'VIP Sugam Darshan at Shri Kashi Vishwanath Golden Temple (Gate 4 Priority).',
          'Maa Annapurna Swarn Mandir & Vishalakshi Shaktipeeth darshan.',
          'Reserved prime deck on private Bajra boat for the spectacular Dashashwamedh Ganga Aarti.',
          'Overnight stay in Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 2: Subah-e-Banaras Sunrise Cruise, Ancient City Temples & Silk Trail',
        highlights: [
          '5:30 AM Subah-e-Banaras sunrise boat ride from Assi to Manikarnika Ghat.',
          'Experience live Vedic chanting, morning Ganga snan and cremation ghat philosophy.',
          'Darshan at Sankat Mochan Hanuman Mandir (established by Goswami Tulsidas).',
          'Maa Durga Mandir (Durga Kund) & marble-engraved Tulsi Manas Mandir.',
          'Banaras Hindu University (BHU) campus & New Kashi Vishwanath Temple (Birla Mandir).',
          'Guided visit to heritage Banarasi Silk Handloom weavers colony.',
          'Evening Banarasi food crawl (Kashi Chaat Bhandar, Tamatar Chaat & Malaiyo).',
          'Overnight stay in Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 3: Baba Kaal Bhairav, Sarnath Heritage & Chauffeur Departure',
        highlights: [
          'Darshan at Baba Kaal Bhairav (Kotwal of Kashi) - compulsory blessing for pilgrims.',
          'Drive to Sarnath - sacred site of Lord Buddha\'s First Sermon (Dharmachakra).',
          'Explore ancient Dhamek Stupa, Chaukhandi Stupa & Archaeological Museum (Ashoka Lion Capital).',
          'Last-minute souvenir shopping (holy Ganga Jal brass vessels, Banarasi sarees).',
          'Chauffeur drop at Varanasi Airport / Railway Station.',
        ],
      ),
    ],
    'Dev Deepawali 2026 Special 3D2N Allocation': const [
      _ItineraryPlan(
        title: 'Day 1: Welcome to the City of Light & Kashi Vishwanath Darshan',
        highlights: [
          'Arrival transfer & priority check-in.',
          'VIP Sugam Darshan at Kashi Vishwanath Corridor.',
          'Evening Ghat walking tour & preliminary illuminations.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 2: The Grand Dev Deepawali Festival - 1 Million Earthen Lamps',
        highlights: [
          'Subah-e-Banaras morning sunrise boat & city temple circuit.',
          'Afternoon briefing & embarkation on reserved VIP Dev Deepawali Boat.',
          'Panoramic cruise witnessing 84 ghats bathed in over 1,000,000 glowing diyas.',
          'Special Maha Aarti at Dashashwamedh Ghat & laser show at Chet Singh Fort.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 3: Sarnath, Kaal Bhairav & Departure Drop',
        highlights: [
          'Kaal Bhairav blessings, Sarnath excursion & airport/station drop.',
        ],
      ),
    ],
    'Ayodhya Ram Mandir & Kashi 3D2N Fast-Track': const [
      _ItineraryPlan(
        title: 'Day 1: Varanasi Arrival, Kashi Vishwanath & Ganga Aarti',
        highlights: [
          'Varanasi arrival, VIP Sugam Darshan & Evening Bajra Aarti Boat.',
          'Overnight Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 2: Express Ayodhya Ram Janmabhoomi Darshan & Return',
        highlights: [
          'Early 6:00 AM AC highway drive to Ayodhya Dham (3.5 hrs via Purvanchal).',
          'Shri Ram Janmabhoomi Mandir Darshan.',
          'Hanumangarhi, Kanak Bhawan & Saryu Ghat.',
          'Drive back to Varanasi for overnight stay.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 3: Kaal Bhairav, Subah-e-Banaras & Varanasi Departure',
        highlights: [
          'Subah-e-Banaras boat ride, Kaal Bhairav blessings & airport transfer.',
        ],
      ),
    ],
    'Varanasi + Ayodhya Ram Mandir 4D3N Circuit': const [
      _ItineraryPlan(
        title: 'Day 1: Arrival Varanasi, Kashi Vishwanath VIP & Ganga Aarti Boat',
        highlights: [
          'Arrival pickup at Varanasi Airport / Cantt Railway Station.',
          'Kashi Vishwanath VIP Sugam Darshan passes (Gate 4 Priority).',
          'Annapurna & Vishalakshi Shaktipeeth.',
          'Dashashwamedh Ghat Grand Evening Ganga Aarti on private Bajra boat deck.',
          'Night stay Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 2: Subah-e-Banaras Sunrise, Sarnath & Highway Transfer to Ayodhya',
        highlights: [
          'Subah-e-Banaras morning sunrise boat (Assi to Manikarnika Ghat).',
          'Baba Kaal Bhairav Darshan (Kotwal of Kashi).',
          'Sarnath Buddhist heritage park & Dhamek Stupa.',
          'Scenic AC drive to holy city of Ayodhya (3.5 hours).',
          'Check-in at Ayodhya hotel. Evening Saryu Aarti at Ram Ki Paidi & laser spectacle.',
          'Overnight stay in Ayodhya.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 3: Ayodhya Shri Ram Janmabhoomi VIP Darshan & Return to Kashi',
        highlights: [
          'VIP Darshan at grand Shri Ram Janmabhoomi Mandir.',
          'Hanumangarhi Temple blessings (guard deity of Ayodhya).',
          'Kanak Bhawan (palace gifted to Mata Sita) & Dashrath Mahal.',
          'Afternoon highway drive back to Varanasi.',
          'Overnight stay in Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 4: Sankat Mochan, BHU Birla Mandir & Varanasi Departure',
        highlights: [
          'Morning darshan at Sankat Mochan Hanuman Mandir & Durga Kund.',
          'BHU New Vishwanath Temple.',
          'Banarasi Silk loom weaving tour & souvenir shopping.',
          'Chauffeur drop at Varanasi Airport / Railway Station.',
        ],
      ),
    ],
    'Varanasi + Prayagraj Triveni Sangam 4D3N Circuit': const [
      _ItineraryPlan(
        title: 'Day 1: Arrival Varanasi, Check-in & Evening Ganga Aarti',
        highlights: [
          'Arrival pickup & transfer to Varanasi hotel.',
          'Dashashwamedh Ghat Ganga Aarti on private Bajra boat.',
          'Overnight Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 2: Kashi Vishwanath VIP, Subah-e-Banaras & Sarnath',
        highlights: [
          'Sunrise boat cruise, Kashi Vishwanath VIP Sugam Darshan & Kaal Bhairav.',
          'Afternoon excursion to Sarnath Dhamek Stupa & Archaeological Museum.',
          'Overnight Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 3: Prayagraj Triveni Sangam Snan, Bade Hanuman Ji & Alopi Devi',
        highlights: [
          'Early morning 2-hour drive to holy Prayagraj.',
          'Holy boat ride & holy dip at Triveni Sangam (confluence of Ganga, Yamuna & Saraswati).',
          'Bade Hanuman Ji Mandir (miraculous reclining idol) & Alopi Devi Shaktipeeth.',
          'Anand Bhavan & Swaraj Bhavan.',
          'Evening return drive to Varanasi. Overnight stay in Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 4: City Temples, Silk Shopping & Departure Drop',
        highlights: [
          'Sankat Mochan, Durga Mandir & Banarasi Silk handlooms.',
          'Timely drop at Varanasi Airport / Railway Station.',
        ],
      ),
    ],
    'Kashi - Gaya - Bodhgaya 4D3N Pind Daan Circuit': const [
      _ItineraryPlan(
        title: 'Day 1: Varanasi Arrival, Kashi Vishwanath & Ganga Aarti',
        highlights: [
          'Pickup, Kashi Vishwanath VIP Sugam Darshan & Evening Ganga Aarti boat.',
          'Overnight Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 2: Drive to Bodhgaya & UNESCO Mahabodhi Temple',
        highlights: [
          'Morning 4-hour scenic drive across Bihar border to Bodhgaya.',
          'Check-in & visit UNESCO World Heritage Mahabodhi Temple.',
          'Sit beneath the sacred Bodhi Tree & visit 80ft Great Buddha Statue.',
          'Overnight stay in Bodhgaya.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 3: Sacred Pind Daan at Gaya Vishnupad & Return to Varanasi',
        highlights: [
          'Early morning sacred ancestral Pind Daan / Shradh rituals at Vishnupad Temple on Falgu River.',
          'Maa Mangla Gauri Shaktipeeth darshan.',
          'Afternoon drive back to Varanasi (4.5 hrs).',
          'Overnight stay in Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 4: Kaal Bhairav, Sarnath & Varanasi Departure',
        highlights: [
          'Subah-e-Banaras morning boat ride, Kaal Bhairav darshan & Sarnath.',
          'Drop at Varanasi Airport / Railway Station.',
        ],
      ),
    ],
    'The Holy Trinity: Varanasi - Prayagraj - Ayodhya 5D4N': const [
      _ItineraryPlan(
        title: 'Day 1: Varanasi Arrival, Kashi Vishwanath Jyotirlinga & Ganga Aarti',
        highlights: [
          'Airport / Station pickup in comfortable AC fleet.',
          'Check-in & refresh.',
          'Kashi Vishwanath VIP Sugam Darshan (Gate 4 Priority - Zero waiting).',
          'Annapurna Temple & Vishalakshi Shaktipeeth.',
          'Evening Ganga Aarti from reserved Bajra boat deck at Dashashwamedh Ghat.',
          'Overnight stay in Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 2: Subah-e-Banaras, Sacred City Temples & Sarnath',
        highlights: [
          '5:30 AM Subah-e-Banaras sunrise boat cruise from Assi to Manikarnika Ghat.',
          'Kotwal of Kashi Baba Kaal Bhairav Mandir.',
          'Sankat Mochan Hanuman Temple & Durga Kund.',
          'Sarnath (First Sermon Deer Park & Dhamek Stupa).',
          'Authentic Banarasi Silk Handloom weavers workshop.',
          'Overnight stay in Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 3: Prayagraj Triveni Sangam Snan -> Highway to Ayodhya Dham',
        highlights: [
          'Early morning 7:00 AM drive to Prayagraj (2.5 hrs).',
          'Private boat to holy Triveni Sangam for sacred snan (Ganga, Yamuna, Saraswati).',
          'Shri Bade Hanuman Ji (reclining idol) & Alopi Devi Shaktipeeth.',
          'Scenic afternoon drive to Sri Ayodhya Dham (3 hours).',
          'Check-in at Ayodhya hotel. Mesmerizing Saryu Aarti at Ram Ki Paidi & laser show.',
          'Overnight stay in Ayodhya.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 4: Ayodhya Shri Ram Janmabhoomi VIP Darshan -> Return to Varanasi',
        highlights: [
          'VIP Darshan at the magnificent Shri Ram Janmabhoomi Mandir.',
          'Hanumangarhi Temple & Kanak Bhawan.',
          'Dashrath Mahal & Ramkot.',
          'Relaxed highway drive back to Varanasi (3.5 hrs).',
          'Overnight stay in Varanasi.',
        ],
      ),
      _ItineraryPlan(
        title: 'Day 5: BHU New Vishwanath, Souvenir Trail & Chauffeur Departure',
        highlights: [
          'Banaras Hindu University (BHU) New Vishwanath Temple.',
          'Local food delicacies trail & shopping for souvenirs.',
          'Chauffeur drop at Varanasi Airport / Railway Station with holy prasad.',
        ],
      ),
    ],
    'Grand Spiritual Yatra: Kashi - Bodhgaya - Ayodhya 5D4N': const [
      _ItineraryPlan(
        title: 'Day 1: Varanasi Arrival & Kashi Vishwanath VIP',
        highlights: ['Arrival, Kashi Vishwanath VIP Darshan & Evening Ganga Aarti boat.', 'Overnight Varanasi.'],
      ),
      _ItineraryPlan(
        title: 'Day 2: Bodhgaya UNESCO Mahabodhi Temple & Great Buddha',
        highlights: ['Highway drive to Bodhgaya.', 'Visit Mahabodhi Temple, Bodhi Tree & Great Buddha.', 'Overnight Bodhgaya.'],
      ),
      _ItineraryPlan(
        title: 'Day 3: Gaya Vishnupad Pind Daan & Transfer to Varanasi',
        highlights: ['Vishnupad Temple ancestral rituals & Mangla Gauri Shaktipeeth.', 'Return to Varanasi for night stay.'],
      ),
      _ItineraryPlan(
        title: 'Day 4: Excursion to Ayodhya Shri Ram Janmabhoomi Mandir',
        highlights: ['Highway drive to Ayodhya.', 'Ram Janmabhoomi VIP Darshan, Hanumangarhi & Kanak Bhawan.', 'Return to Varanasi.'],
      ),
      _ItineraryPlan(
        title: 'Day 5: Subah-e-Banaras Boat, Sarnath & Varanasi Departure',
        highlights: ['Sunrise boat ride, Kaal Bhairav, Sarnath & departure drop.'],
      ),
    ],
  };

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

      _autoSelectFleetForPax(_pax);

      // Guess duration & circuit from lead destination or text
      final destLower = lead.destination.toLowerCase();
      if (destLower.contains('5d') || (destLower.contains('ayodhya') && destLower.contains('prayagraj'))) {
        _setDuration(5, 4);
      } else if (destLower.contains('4d') || destLower.contains('ayodhya') || destLower.contains('gaya')) {
        _setDuration(4, 3);
      } else if (destLower.contains('2d') || destLower.contains('local') || destLower.contains('1n')) {
        _setDuration(2, 1);
      } else {
        _setDuration(3, 2);
      }
    } else {
      _travelDate = DateTime.now().add(const Duration(days: 7));
      _autoSelectFleetForPax(_pax);
    }
  }

  void _setDuration(int days, int nights) {
    setState(() {
      _selectedDays = days;
      _selectedNights = nights;
      final circuits = _circuitsByDays[days] ?? _circuitsByDays[3]!;
      _selectedCircuit = circuits[0];
    });
  }

  void _autoSelectFleetForPax(int pax) {
    if (pax <= 3) {
      _cabType = 'Swift Dzire AC';
    } else if (pax <= 6) {
      _cabType = 'Innova Crysta';
    } else if (pax <= 12) {
      _cabType = '12S Force Tempo Traveller';
    } else {
      _cabType = 'Force Urbania Luxury';
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

    // Base pricing based on duration and circuit
    double basePerPax = 6800;
    if (_selectedDays == 2) basePerPax = 4200;
    if (_selectedDays == 3) basePerPax = 6800;
    if (_selectedDays == 4) basePerPax = 11500;
    if (_selectedDays == 5) basePerPax = 14500;

    if (_selectedCircuit.contains('Dev Deepawali')) basePerPax = 19500;
    if (_selectedCircuit.contains('Pind Daan') || _selectedCircuit.contains('Gaya')) basePerPax += 1500;

    // Hotel calculation: based on rooms needed ceil(pax / 2) * nights
    final roomsCount = (_pax / 2).ceil();
    double hotelPerRoomPerNight = 4200;
    if (_hotelCategory.contains('5-Star')) hotelPerRoomPerNight = 8500;
    if (_hotelCategory.contains('4-Star')) hotelPerRoomPerNight = 4200;
    if (_hotelCategory.contains('3-Star')) hotelPerRoomPerNight = 2500;
    if (_hotelCategory.contains('Cab Only')) hotelPerRoomPerNight = 0;

    final hotelCost = hotelPerRoomPerNight * roomsCount * _selectedNights;

    // Dedicated Fleet calculation for full tour duration
    double cabCost = 4500;
    if (_cabType.contains('Dzire')) {
      cabCost = _selectedDays == 2 ? 3800 : (_selectedDays == 3 ? 5500 : (_selectedDays == 4 ? 9500 : 13500));
    } else if (_cabType.contains('Innova')) {
      cabCost = _selectedDays == 2 ? 5800 : (_selectedDays == 3 ? 8500 : (_selectedDays == 4 ? 14500 : 19500));
    } else if (_cabType.contains('Tempo')) {
      cabCost = _selectedDays == 2 ? 9500 : (_selectedDays == 3 ? 14000 : (_selectedDays == 4 ? 22000 : 28500));
    } else if (_cabType.contains('Urbania')) {
      cabCost = _selectedDays == 2 ? 14000 : (_selectedDays == 3 ? 19500 : (_selectedDays == 4 ? 31000 : 39500));
    }

    // VIP Spiritual Inclusions
    double vipPasses = 0;
    if (_includeSugamDarshan) vipPasses += 350 * _pax;
    if (_includeAartiBoat) vipPasses += 750 * _pax;
    if (_includeSubahEBanaras) vipPasses += 400 * _pax;
    if (_includePandaShastri) vipPasses += 1500;

    double subtotal = (basePerPax * _pax) + hotelCost + cabCost + vipPasses;
    if (_isB2bMode) {
      return (subtotal * 0.88).roundToDouble(); // 12% wholesale net discount for B2B partners
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
      buffer.writeln('📋 *CONFIDENTIAL B2B NET WHOLESALE TARIFF & ITINERARY*');
      buffer.writeln('Circuit: *$_selectedCircuit* ($_selectedDays Days / $_selectedNights Nights)');
    } else {
      buffer.writeln('🙏 *Namaste $name! Greetings from TripCosmos Varanasi.*');
      buffer.writeln('Here is your personalized pilgrimage proposal for *$_selectedCircuit* ($_selectedDays Days / $_selectedNights Nights):');
    }

    buffer.writeln('');
    buffer.writeln('📅 *Travel Date:* $dateStr');
    buffer.writeln('👥 *Travelers:* $_pax Pax');
    buffer.writeln('🏨 *Hotel Category:* $_hotelCategory ${_hotelNameCtrl.text.trim().isNotEmpty ? "(${_hotelNameCtrl.text.trim()})" : ""} ($_selectedNights Nights)');
    buffer.writeln('🚗 *Dedicated AC Cab:* $_cabType (Pickup to Drop throughout)');
    buffer.writeln('');
    buffer.writeln('✨ *VIP Spiritual Inclusions:*');
    if (_includeSugamDarshan) buffer.writeln('• *Kashi Vishwanath Sugam Darshan Passes:* Priority entry via Gate 4 (Zero line waiting)');
    if (_includeAartiBoat) buffer.writeln('• *Dashashwamedh Ghat Ganga Aarti:* Reserved prime viewing deck on Bajra boat');
    if (_includeSubahEBanaras) buffer.writeln('• *Subah-e-Banaras Sunrise Boat Ride:* Assi Ghat to Manikarnika Ghat with Vedic chanting');
    if (_includePandaShastri) buffer.writeln('• *Vedic Shastri / Teerth Purohit:* Personal guide for Sankalp, Abhishek & Temple rituals');
    if (_includeAirportPickup) buffer.writeln('• *Airport / Cantt Railway Station Transfers:* AC Chauffeur meet & assist with placard');
    if (_customInclusionsCtrl.text.trim().isNotEmpty) buffer.writeln('• ${_customInclusionsCtrl.text.trim()}');

    // Day-by-Day Itinerary insertion
    if (_includeDayWiseItinerary) {
      final itinerary = _itineraryCatalog[_selectedCircuit];
      if (itinerary != null && itinerary.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('🗓️ *Day-by-Day Sacred Tour Itinerary:*');
        for (int i = 0; i < itinerary.length; i++) {
          final day = itinerary[i];
          buffer.writeln('');
          buffer.writeln('📍 *${day.title}*');
          for (final h in day.highlights) {
            buffer.writeln('  ▫️ $h');
          }
        }
      }
    }

    buffer.writeln('');
    buffer.writeln('💰 *Total Package Investment:* *$total* ($perPax per person)');
    buffer.writeln('💳 *Advance Booking Token:* *$advance* to lock dates, VIP darshan passes & vehicle fleet.');
    buffer.writeln('⚖️ *Balance:* Payable on check-in arrival in Varanasi.');
    buffer.writeln('');
    buffer.writeln('📞 *TripCosmos Operations Desk:* +91 93361 16210 | support@tripcosmos.co');
    buffer.writeln('🌐 *Registered Office:* D 59/103-E-1-R, Shivpurva, Mahmoorganj, Varanasi 221010');
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
                  if (mounted) {
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

  Widget _buildDurationPill({required int days, required int nights, required String label, required String sublabel}) {
    final isSelected = _selectedDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setDuration(days, nights),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentGold.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accentGold : Colors.white12,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppColors.accentGold : AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.accentGold.withValues(alpha: 0.9) : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final availableCircuits = _circuitsByDays[_selectedDays] ?? _circuitsByDays[3]!;
    final currentItinerary = _itineraryCatalog[_selectedCircuit] ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('⚡ Quotation & Proposal Desk', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            icon: Icon(_showLivePreview ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
            tooltip: _showLivePreview ? 'Hide Live Preview' : 'Show Live Preview',
            onPressed: () => setState(() => _showLivePreview = !_showLivePreview),
          ),
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
              // 1. Duration Selector Header: 2D, 3D, 4D, 5D
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '1. TOUR DURATION & PILGRIMAGE DAYS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$_selectedDays Days / $_selectedNights Nights',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildDurationPill(days: 2, nights: 1, label: '2 Days', sublabel: '1 Night'),
                        const SizedBox(width: 8),
                        _buildDurationPill(days: 3, nights: 2, label: '3 Days', sublabel: '2 Nights ⭐'),
                        const SizedBox(width: 8),
                        _buildDurationPill(days: 4, nights: 3, label: '4 Days', sublabel: '3 Nights'),
                        const SizedBox(width: 8),
                        _buildDurationPill(days: 5, nights: 4, label: '5 Days', sublabel: '4 Nights (Trinity)'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Client Header Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('2. TRAVELER / B2B PROFILE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5)),
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

              // 3. Circuit & Dates
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('3. CIRCUIT & DATES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: availableCircuits.contains(_selectedCircuit) ? _selectedCircuit : availableCircuits[0],
                      decoration: const InputDecoration(labelText: 'Pilgrimage Circuit', prefixIcon: Icon(Icons.temple_hindu_rounded, size: 18)),
                      isExpanded: true,
                      items: availableCircuits.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
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
                                onPressed: _pax > 1
                                    ? () {
                                        setState(() {
                                          _pax--;
                                          _autoSelectFleetForPax(_pax);
                                        });
                                      }
                                    : null,
                              ),
                              Text('$_pax Pax', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _pax++;
                                    _autoSelectFleetForPax(_pax);
                                  });
                                },
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

              // 4. Vehicle & Hotel
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('4. FLEET & ACCOMMODATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5)),
                        Text(
                          '${(_pax / 2).ceil()} Room(s) • $_selectedNights Nights',
                          style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _cabType,
                            decoration: const InputDecoration(labelText: 'AC Dedicated Fleet', prefixIcon: Icon(Icons.directions_car_rounded, size: 18)),
                            items: const [
                              DropdownMenuItem(value: 'Swift Dzire AC', child: Text('Swift Dzire (1-3 Pax)', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 'Innova Crysta', child: Text('Innova Crysta (4-6 Pax)', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: '12S Force Tempo Traveller', child: Text('Force Tempo (7-12 Pax)', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 'Force Urbania Luxury', child: Text('Force Urbania (13-17 Pax)', style: TextStyle(fontSize: 12.5))),
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

              // 5. VIP Spiritual Inclusions Checklist
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('5. VIP SPIRITUAL INCLUSIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5)),
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
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeAirportPickup,
                      activeColor: AppColors.accentGold,
                      title: const Text('Airport / Cantt Railway Station Placard Meet & Greet', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      onChanged: (v) => setState(() => _includeAirportPickup = v ?? false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 6. Day-by-Day Sacred Itinerary Preview
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '6. DAY-BY-DAY ITINERARY',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGold, letterSpacing: 0.5),
                        ),
                        Row(
                          children: [
                            const Text('Include in Quote', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Switch(
                              value: _includeDayWiseItinerary,
                              activeColor: AppColors.accentGold,
                              onChanged: (v) => setState(() => _includeDayWiseItinerary = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (currentItinerary.isEmpty)
                      const Text('Custom itinerary will be configured during dispatch.', style: TextStyle(fontSize: 12, color: Colors.white54))
                    else
                      Column(
                        children: currentItinerary.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final day = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentGold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Day ${idx + 1}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.accentGold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        day.title,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...day.highlights.map(
                                  (h) => Padding(
                                    padding: const EdgeInsets.only(left: 6, top: 3),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(color: AppColors.accentGold, fontSize: 12)),
                                        Expanded(child: Text(h, style: const TextStyle(fontSize: 11.5, color: Colors.white70))),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Live Message Preview (Optional toggle)
              if (_showLivePreview) ...[
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.mark_chat_unread_rounded, size: 16, color: AppColors.whatsappGreen),
                              SizedBox(width: 6),
                              Text('LIVE WHATSAPP PROPOSAL PREVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.whatsappGreen)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() => _showLivePreview = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B1E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.whatsappGreen.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _generateProposalText(),
                          style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: Colors.white70, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 7. Real-Time Total Calculation Box
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
