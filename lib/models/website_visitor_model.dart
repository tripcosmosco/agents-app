class WebsiteVisitor {
  final String id;
  final String ip;
  final String city;
  final String country;
  final String flag;
  final String currentPage;
  final String pageTitle;
  final String referrer;
  final int durationSeconds;
  final int scrollDepth;
  final int intentScore; // 1 - 100
  final String intentLabel; // 'High Intent', 'Pricing Evaluation', 'Engaged Prospect', 'Casual Browsing'
  final String device;
  final bool isOnline;
  final DateTime lastActive;

  const WebsiteVisitor({
    required this.id,
    required this.ip,
    required this.city,
    required this.country,
    required this.flag,
    required this.currentPage,
    required this.pageTitle,
    required this.referrer,
    required this.durationSeconds,
    required this.scrollDepth,
    required this.intentScore,
    required this.intentLabel,
    required this.device,
    required this.isOnline,
    required this.lastActive,
  });

  WebsiteVisitor copyWith({
    String? id,
    String? ip,
    String? city,
    String? country,
    String? flag,
    String? currentPage,
    String? pageTitle,
    String? referrer,
    int? durationSeconds,
    int? scrollDepth,
    int? intentScore,
    String? intentLabel,
    String? device,
    bool? isOnline,
    DateTime? lastActive,
  }) {
    return WebsiteVisitor(
      id: id ?? this.id,
      ip: ip ?? this.ip,
      city: city ?? this.city,
      country: country ?? this.country,
      flag: flag ?? this.flag,
      currentPage: currentPage ?? this.currentPage,
      pageTitle: pageTitle ?? this.pageTitle,
      referrer: referrer ?? this.referrer,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      scrollDepth: scrollDepth ?? this.scrollDepth,
      intentScore: intentScore ?? this.intentScore,
      intentLabel: intentLabel ?? this.intentLabel,
      device: device ?? this.device,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
