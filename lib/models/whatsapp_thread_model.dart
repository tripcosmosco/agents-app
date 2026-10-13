class WhatsAppMessage {
  final String id;
  final String text;
  final bool isFromCustomer;
  final DateTime timestamp;
  final String status; // 'sent', 'delivered', 'read', 'saved'
  final String? mediaUrl;
  final String? mediaType; // 'image', 'pdf', 'audio'
  final bool isInternalNote;
  final bool isCallEvent;
  final String channel; // 'whatsapp', 'web', 'call', 'note'
  final String? authorName;

  WhatsAppMessage({
    required this.id,
    required this.text,
    required this.isFromCustomer,
    required this.timestamp,
    this.status = 'delivered',
    this.mediaUrl,
    this.mediaType,
    this.isInternalNote = false,
    this.isCallEvent = false,
    this.channel = 'whatsapp',
    this.authorName,
  });

  factory WhatsAppMessage.fromJson(Map<String, dynamic> json) {
    return WhatsAppMessage(
      id: json['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: (json['text'] ?? json['message'] ?? json['body'] ?? '').toString(),
      isFromCustomer: json['is_from_customer'] == true ||
          (json['is_from_customer'] == null && (json['sender'] == 'customer' || json['from'] != 'me')),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      status: (json['status'] ?? 'delivered').toString(),
      mediaUrl: json['media_url']?.toString(),
      mediaType: (json['media_type'] ?? json['media'])?.toString(),
      isInternalNote: json['is_internal_note'] == true,
      isCallEvent: json['is_call_event'] == true,
      channel: (json['channel'] ?? 'whatsapp').toString(),
      authorName: json['author_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'is_from_customer': isFromCustomer,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    'media_url': mediaUrl,
    'media_type': mediaType,
    'is_internal_note': isInternalNote,
    'is_call_event': isCallEvent,
    'channel': channel,
    'author_name': authorName,
  };
}

class WhatsAppThread {
  final String id;
  final int contactId;
  final String remoteJid;
  final String customerPhone;
  final String customerName;
  final String profilePicUrl;
  final String lastMessage;
  final bool lastMessageFromMe;
  final String lastMessageStatus;
  final String timeAgo;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isAiAssisted;
  final String assignedAgent;
  final String circuit;
  final String stage;
  final double dealValue;
  final String sourceChannel;
  final bool hasWhatsappChat;
  final bool isB2b;
  final DateTime? nextFollowUpAt;
  final int callCount;
  final List<WhatsAppMessage> messages;

  WhatsAppThread({
    required this.id,
    this.contactId = 0,
    this.remoteJid = '',
    required this.customerPhone,
    required this.customerName,
    this.profilePicUrl = '',
    required this.lastMessage,
    this.lastMessageFromMe = false,
    this.lastMessageStatus = 'read',
    this.timeAgo = '',
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isAiAssisted = false,
    this.assignedAgent = 'Santosh Yadav',
    this.circuit = 'Varanasi Pilgrimage',
    this.stage = 'new',
    this.dealValue = 0.0,
    this.sourceChannel = 'whatsapp',
    this.hasWhatsappChat = true,
    this.isB2b = false,
    this.nextFollowUpAt,
    this.callCount = 0,
    this.messages = const [],
  });

  String get stageLabel {
    switch (stage.toLowerCase()) {
      case 'new':
      case 'inquiry':
        return 'New';
      case 'contacted':
        return 'Contacted';
      case 'qualified':
        return 'Qualified';
      case 'quote_sent':
        return 'Quote Sent';
      case 'advance_received':
      case 'advance_paid':
        return 'Advance Paid';
      case 'won':
        return 'Won';
      case 'b2b_partner':
        return 'B2B Partner';
      case 'lost':
        return 'Lost';
      default:
        return stage.isEmpty ? 'New' : stage;
    }
  }

  WhatsAppThread copyWith({
    int? contactId,
    String? remoteJid,
    String? customerName,
    String? profilePicUrl,
    String? lastMessage,
    bool? lastMessageFromMe,
    String? lastMessageStatus,
    String? timeAgo,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isAiAssisted,
    String? assignedAgent,
    String? circuit,
    String? stage,
    double? dealValue,
    String? sourceChannel,
    bool? hasWhatsappChat,
    bool? isB2b,
    DateTime? nextFollowUpAt,
    bool clearFollowUp = false,
    int? callCount,
    List<WhatsAppMessage>? messages,
  }) {
    return WhatsAppThread(
      id: id,
      contactId: contactId ?? this.contactId,
      remoteJid: remoteJid ?? this.remoteJid,
      customerPhone: customerPhone,
      customerName: customerName ?? this.customerName,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageFromMe: lastMessageFromMe ?? this.lastMessageFromMe,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      timeAgo: timeAgo ?? this.timeAgo,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isAiAssisted: isAiAssisted ?? this.isAiAssisted,
      assignedAgent: assignedAgent ?? this.assignedAgent,
      circuit: circuit ?? this.circuit,
      stage: stage ?? this.stage,
      dealValue: dealValue ?? this.dealValue,
      sourceChannel: sourceChannel ?? this.sourceChannel,
      hasWhatsappChat: hasWhatsappChat ?? this.hasWhatsappChat,
      isB2b: isB2b ?? this.isB2b,
      nextFollowUpAt: clearFollowUp ? null : (nextFollowUpAt ?? this.nextFollowUpAt),
      callCount: callCount ?? this.callCount,
      messages: messages ?? this.messages,
    );
  }

  String get initials {
    final clean = customerName.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'WA';
  }
}
