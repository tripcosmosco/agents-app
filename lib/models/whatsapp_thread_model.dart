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
    this.assignedAgent = 'Nishkarsh AI',
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

  factory WhatsAppThread.fromJson(Map<String, dynamic> json) {
    List<WhatsAppMessage> parsedMsgs = [];
    if (json['messages'] is List) {
      parsedMsgs = (json['messages'] as List)
          .map((m) => WhatsAppMessage.fromJson(
              m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map)))
          .toList();
    }

    return WhatsAppThread(
      id: json['id']?.toString() ?? '',
      contactId: int.tryParse(json['contact_id']?.toString() ?? '0') ?? 0,
      remoteJid: json['remote_jid']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Traveler',
      profilePicUrl: json['profile_pic_url']?.toString() ?? '',
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageFromMe: json['last_message_from_me'] == true,
      lastMessageStatus: json['last_message_status']?.toString() ?? 'read',
      timeAgo: json['time_ago']?.toString() ?? '',
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      isAiAssisted: json['is_ai_assisted'] == true,
      assignedAgent: json['assigned_agent']?.toString() ?? 'Nishkarsh AI',
      circuit: json['circuit']?.toString() ?? 'Varanasi Pilgrimage',
      stage: json['stage']?.toString() ?? 'new',
      dealValue: double.tryParse(json['deal_value']?.toString() ?? '0') ?? 0.0,
      sourceChannel: json['source_channel']?.toString() ?? 'whatsapp',
      hasWhatsappChat: json['has_whatsapp_chat'] != false,
      isB2b: json['is_b2b'] == true,
      nextFollowUpAt: json['next_follow_up_at'] != null
          ? DateTime.tryParse(json['next_follow_up_at'].toString())
          : null,
      callCount: int.tryParse(json['call_count']?.toString() ?? '0') ?? 0,
      messages: parsedMsgs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_id': contactId,
      'remote_jid': remoteJid,
      'customer_phone': customerPhone,
      'customer_name': customerName,
      'profile_pic_url': profilePicUrl,
      'last_message': lastMessage,
      'last_message_from_me': lastMessageFromMe,
      'last_message_status': lastMessageStatus,
      'time_ago': timeAgo,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
      'is_ai_assisted': isAiAssisted,
      'assigned_agent': assignedAgent,
      'circuit': circuit,
      'stage': stage,
      'deal_value': dealValue,
      'source_channel': sourceChannel,
      'has_whatsapp_chat': hasWhatsappChat,
      'is_b2b': isB2b,
      'next_follow_up_at': nextFollowUpAt?.toIso8601String(),
      'call_count': callCount,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

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

  String get displayName {
    final clean = customerName.trim();
    final lower = clean.toLowerCase();
    if (clean.isEmpty ||
        lower == 'nobody' ||
        lower == 'null' ||
        lower == 'unknown' ||
        RegExp(r'^\+?[0-9]{7,15}$').hasMatch(clean)) {
      if (circuit.isNotEmpty && circuit != 'Spiritual Circuit' && circuit != 'Varanasi Pilgrimage') {
        return 'Traveler ($circuit)';
      }
      final numOnly = customerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
      return numOnly.isNotEmpty ? 'Traveler ($numOnly)' : 'Traveler';
    }
    return clean;
  }

  String get initials {
    final clean = displayName.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'TC';
  }
}

