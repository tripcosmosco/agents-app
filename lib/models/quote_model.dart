class QuoteModel {
  final String destination;
  final String packageTitle;
  final int pax;
  final String rateType; // b2c (retail) or b2b (net)
  final int pricing;
  final int retailPrice;
  final int netPrice;
  final int commission;
  final int advanceRequired;
  final String quoteText;

  QuoteModel({
    required this.destination,
    required this.packageTitle,
    required this.pax,
    required this.rateType,
    required this.pricing,
    required this.retailPrice,
    required this.netPrice,
    required this.commission,
    required this.advanceRequired,
    required this.quoteText,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      destination: json['destination'] ?? 'Varanasi',
      packageTitle: json['package_title'] ?? 'Spiritual Tour Package',
      pax: int.tryParse(json['pax']?.toString() ?? '2') ?? 2,
      rateType: json['rate_type'] ?? 'b2c',
      pricing: int.tryParse(json['pricing']?.toString() ?? '0') ?? 0,
      retailPrice: int.tryParse(json['retail_price']?.toString() ?? '0') ?? 0,
      netPrice: int.tryParse(json['net_price']?.toString() ?? '0') ?? 0,
      commission: int.tryParse(json['commission']?.toString() ?? '0') ?? 0,
      advanceRequired:
          int.tryParse(json['advance_required']?.toString() ?? '0') ?? 1500,
      quoteText: json['quote_text'] ?? '',
    );
  }
}
