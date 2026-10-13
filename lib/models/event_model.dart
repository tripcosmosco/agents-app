class EventModel {
  final int id;
  final String eventType;
  final String severity;
  final String title;
  final String subtitle;
  final Map<String, dynamic> details;
  final String channel;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.channel,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at']?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return EventModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      eventType: json['event_type']?.toString() ?? 'generic',
      severity: json['severity']?.toString() ?? 'info',
      title: json['title']?.toString() ?? 'Activity Alert',
      subtitle: json['subtitle']?.toString() ?? '',
      details: json['details'] is Map ? Map<String, dynamic>.from(json['details']) : {},
      channel: json['channel']?.toString() ?? 'web',
      createdAt: parsedDate,
    );
  }

  bool get isLeadCapture => eventType == 'lead_captured';
  bool get isVisitorLanding => eventType == 'visitor_landing';
  bool get isCallQueued => eventType == 'jio_outbound_call';
}
