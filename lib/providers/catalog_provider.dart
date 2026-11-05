import 'package:flutter/material.dart';
import '../models/catalog_item_model.dart';
import '../services/api_service.dart';

class CatalogProvider extends ChangeNotifier {
  final List<CatalogItem> _items = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = false;

  CatalogProvider() {
    _initDefaultItems();
    syncWithBackend();
  }

  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<CatalogItem> get items {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == 'all' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase() ||
          item.destination.toLowerCase().contains(_selectedCategory.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.destination.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> get categories {
    final Set<String> cats = {'all'};
    for (var item in _items) {
      if (item.destination.trim().isNotEmpty) {
        cats.add(item.destination.trim());
      }
      if (item.category.trim().isNotEmpty) {
        cats.add(item.category.trim());
      }
    }
    return cats.toList();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> syncWithBackend() async {
    _isLoading = true;
    notifyListeners();
    try {
      final remote = await ApiService().fetchCatalog();
      if (remote.isNotEmpty) {
        for (final r in remote) {
          final item = CatalogItem.fromJson(r);
          final idx = _items.indexWhere((i) => i.id == item.id);
          if (idx != -1) {
            _items[idx] = item;
          } else {
            _items.add(item);
          }
        }
      }
    } catch (e) {
      debugPrint('Sync catalog error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initDefaultItems() {
    _items.addAll([
      const CatalogItem(
        id: 'trav_kashi_vip',
        title: '3-Day Kashi Divya Darshan VIP Itinerary',
        category: 'Pilgrimage Circuit',
        destination: 'Varanasi',
        basePrice: 14500,
        pricingUnit: 'per_person',
        badge: 'Best Seller',
        description: 'VIP Sugam Darshan passes, private evening Ganga Aarti motorboat, 4-star cantonment stay, and dedicated airport transfers.',
        features: ['Kashi Vishwanath VIP', 'Private Aarti Boat', 'Deluxe AC Cab', 'Dedicated Pandit'],
      ),
      const CatalogItem(
        id: 'trav_dev_diwali_bajra',
        title: 'Dev Diwali 2026 VIP Double-Decker Bajra Charter',
        category: 'Exclusive Charter',
        destination: 'Varanasi Ghats',
        basePrice: 285000,
        pricingUnit: 'fixed',
        badge: 'Exclusive',
        description: 'Prime mid-stream Dashashwamedh positioning, live classical shehnai, pure sattvic Banarasi banquet, and 75-guest capacity.',
        features: ['Prime Mid-Stream Slot', 'Banarasi Banquet', 'Live Shehnai & Sound', 'VIP Security'],
      ),
      const CatalogItem(
        id: 'trav_ayodhya_prayagraj',
        title: 'Kashi - Ayodhya Ram Mandir - Prayagraj Sangam (4D/3N)',
        category: 'Pilgrimage Circuit',
        destination: 'Triangle Circuit',
        basePrice: 24500,
        pricingUnit: 'per_person',
        badge: 'High Demand',
        description: 'Ram Janmabhoomi Sugam Darshan, Triveni Sangam boat snan, Kashi Vishwanath corridor, and Innova Crysta highway transit.',
        features: ['Ram Mandir VIP', 'Sangam Snan Boat', 'Innova Crysta AC', 'Hotel Stays'],
      ),
      const CatalogItem(
        id: 'trav_innova_outstation',
        title: 'Toyota Innova Crysta Outstation Cab (3-Day Circuit)',
        category: 'Cab Fleet',
        destination: 'Outstation',
        basePrice: 22500,
        pricingUnit: 'per_trip',
        badge: 'Fleet Verified',
        description: 'Varanasi - Ayodhya - Prayagraj 3-day round trip. Clean AC cabin, experienced highway chauffeur, toll & parking inclusive.',
        features: ['6+1 Captain Seats', 'Luggage Carrier', 'Verified Chauffeur', '24/7 Support'],
      ),
      const CatalogItem(
        id: 'trav_urbania_group',
        title: 'Force Urbania 17-Seater Luxury Maharaja Van',
        category: 'Cab Fleet',
        destination: 'Outstation Group',
        basePrice: 36000,
        pricingUnit: 'per_trip',
        badge: 'Group Special',
        description: 'Ultimate luxury group pilgrimage transit. Pushback recliner seats, ambient lighting, dual AC, large luggage boot.',
        features: ['17 Recliner Seats', 'Dual Chiller AC', 'Smooth Suspension', 'Highway Chauffeur'],
      ),
      const CatalogItem(
        id: 'trav_brijrama_suite',
        title: 'BrijRama Palace Heritage Ghat Suite (2 Nights)',
        category: 'Luxury Hotel',
        destination: 'Varanasi',
        basePrice: 65000,
        pricingUnit: 'fixed',
        badge: 'Heritage',
        description: '210-year-old palace on Darbhanga Ghat. Private bajra pickup, Thali dining at Chota Kolkatta, and private morning yoga.',
        features: ['Riverfront Heritage', 'Private Boat Transfer', 'Royal Breakfast', 'Butler Service'],
      ),
    ]);
  }
}
