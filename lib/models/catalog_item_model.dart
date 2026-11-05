class CatalogItem {
  final String id;
  final String title;
  final String category; // 'package', 'cab_circuit', 'boat_charter', 'vip_darshan', 'hotel'
  final String destination;
  final double basePrice;
  final String pricingUnit; // 'fixed', 'per_person', 'per_day', 'per_trip'
  final String badge;
  final String description;
  final List<String> features;
  final String imageUrl;
  final bool isAvailable;

  const CatalogItem({
    required this.id,
    required this.title,
    required this.category,
    this.destination = '',
    required this.basePrice,
    this.pricingUnit = 'fixed',
    this.badge = '',
    required this.description,
    this.features = const [],
    this.imageUrl = '',
    this.isAvailable = true,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    final dest = json['destination']?.toString() ?? '';
    final cat = (dest.isNotEmpty)
        ? dest
        : (json['category']?.toString() ?? 'Tour Package');

    return CatalogItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: cat,
      destination: dest,
      basePrice: (json['base_price'] is num)
          ? (json['base_price'] as num).toDouble()
          : (double.tryParse(json['base_price']?.toString() ?? '0') ?? 0.0),
      pricingUnit: json['pricing_unit']?.toString() ?? 'fixed',
      badge: json['badge']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageUrl: json['image_url']?.toString() ?? '',
      isAvailable: json['is_available'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'destination': destination,
        'base_price': basePrice,
        'pricing_unit': pricingUnit,
        'badge': badge,
        'description': description,
        'features': features,
        'image_url': imageUrl,
        'is_available': isAvailable,
      };

  String get formattedPrice {
    final formatted = '₹${basePrice.toStringAsFixed(0)}';
    if (pricingUnit == 'fixed') return formatted;
    if (pricingUnit == 'per_person') return '$formatted / person';
    if (pricingUnit == 'per_day') return '$formatted / day';
    if (pricingUnit == 'per_trip') return '$formatted / trip';
    return '$formatted ($pricingUnit)';
  }
}
