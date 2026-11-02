class CabTariffItem {
  final String id;
  String name;
  String capacity;
  int packageSurcharge; // Added to standard itinerary quote package price
  double ratePerKm;     // Outstation rate per km (e.g. ₹12, ₹15, ₹19, ₹25, ₹32)
  int local8h80k;       // 8 hours 80 km local sightseeing rate
  int airportTransfer;  // Flat airport/station pickup/drop transfer rate
  int driverDa;         // Daily driver allowance / bata
  bool isActive;

  CabTariffItem({
    required this.id,
    required this.name,
    this.capacity = '4 Passengers + Driver',
    this.packageSurcharge = 0,
    this.ratePerKm = 12.0,
    this.local8h80k = 1800,
    this.airportTransfer = 1100,
    this.driverDa = 400,
    this.isActive = true,
  });

  factory CabTariffItem.fromJson(Map<String, dynamic> json) {
    return CabTariffItem(
      id: json['id']?.toString() ?? 'cab_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Vehicle',
      capacity: json['capacity']?.toString() ?? '4 Pax',
      packageSurcharge: int.tryParse(json['package_surcharge']?.toString() ?? '0') ?? 0,
      ratePerKm: double.tryParse(json['rate_per_km']?.toString() ?? '12') ?? 12.0,
      local8h80k: int.tryParse(json['local_8h80k']?.toString() ?? '1800') ?? 1800,
      airportTransfer: int.tryParse(json['airport_transfer']?.toString() ?? '1100') ?? 1100,
      driverDa: int.tryParse(json['driver_da']?.toString() ?? '400') ?? 400,
      isActive: json['is_active'] == null || json['is_active'] == true || json['is_active'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'package_surcharge': packageSurcharge,
      'rate_per_km': ratePerKm,
      'local_8h80k': local8h80k,
      'airport_transfer': airportTransfer,
      'driver_da': driverDa,
      'is_active': isActive,
    };
  }

  CabTariffItem copyWith({
    String? id,
    String? name,
    String? capacity,
    int? packageSurcharge,
    double? ratePerKm,
    int? local8h80k,
    int? airportTransfer,
    int? driverDa,
    bool? isActive,
  }) {
    return CabTariffItem(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      packageSurcharge: packageSurcharge ?? this.packageSurcharge,
      ratePerKm: ratePerKm ?? this.ratePerKm,
      local8h80k: local8h80k ?? this.local8h80k,
      airportTransfer: airportTransfer ?? this.airportTransfer,
      driverDa: driverDa ?? this.driverDa,
      isActive: isActive ?? this.isActive,
    );
  }
}
