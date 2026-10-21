class BankTransactionModel {
  final int id;
  final String txnDate;
  final String description;
  final String refNo;
  final double amount;
  final String type; // 'credit' | 'debit'
  final double? balance;
  final String bankName;
  final String accountNo;
  final String category;
  final bool reconciled;
  final int? bookingId;
  final String bookingRef;
  final String bookingCustomer;

  BankTransactionModel({
    required this.id,
    required this.txnDate,
    required this.description,
    required this.refNo,
    required this.amount,
    required this.type,
    this.balance,
    required this.bankName,
    required this.accountNo,
    required this.category,
    required this.reconciled,
    this.bookingId,
    required this.bookingRef,
    required this.bookingCustomer,
  });

  factory BankTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawAmt = json['amount']?.toString().replaceAll(',', '') ?? '0';
    final rawBal = json['balance']?.toString().replaceAll(',', '');

    return BankTransactionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      txnDate: json['txn_date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      refNo: json['ref_no']?.toString() ?? '',
      amount: double.tryParse(rawAmt) ?? 0.0,
      type: json['type']?.toString().toLowerCase() ?? 'credit',
      balance: rawBal != null && rawBal.isNotEmpty ? double.tryParse(rawBal) : null,
      bankName: json['bank_name']?.toString() ?? 'State Bank of India (SBI)',
      accountNo: json['account_no']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      reconciled: json['reconciled'] == true || json['reconciled'] == 1 || json['reconciled'] == '1',
      bookingId: int.tryParse(json['booking_id']?.toString() ?? ''),
      bookingRef: json['booking_ref']?.toString() ?? '',
      bookingCustomer: json['booking_customer']?.toString() ?? '',
    );
  }
}

class BankSummaryModel {
  final double totalCredits;
  final double totalDebits;
  final double netBalance;
  final int reconciledCount;
  final int pendingReconcileCount;

  BankSummaryModel({
    required this.totalCredits,
    required this.totalDebits,
    required this.netBalance,
    required this.reconciledCount,
    required this.pendingReconcileCount,
  });

  factory BankSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawCredits = json['total_credits']?.toString().replaceAll(',', '') ?? '0';
    final rawDebits = json['total_debits']?.toString().replaceAll(',', '') ?? '0';
    final rawBal = json['net_balance']?.toString().replaceAll(',', '') ?? '0';

    return BankSummaryModel(
      totalCredits: double.tryParse(rawCredits) ?? 0.0,
      totalDebits: double.tryParse(rawDebits) ?? 0.0,
      netBalance: double.tryParse(rawBal) ?? 0.0,
      reconciledCount: int.tryParse(json['reconciled_count']?.toString() ?? '0') ?? 0,
      pendingReconcileCount: int.tryParse(json['pending_reconcile_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class ZohoInvoiceModel {
  final String invoiceId;
  final String invoiceNumber;
  final String customerName;
  final String date;
  final String dueDate;
  final double total;
  final double balance;
  final String status;

  ZohoInvoiceModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerName,
    required this.date,
    required this.dueDate,
    required this.total,
    required this.balance,
    required this.status,
  });

  factory ZohoInvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total']?.toString().replaceAll(',', '') ?? '0';
    final rawBal = json['balance']?.toString().replaceAll(',', '') ?? '0';

    return ZohoInvoiceModel(
      invoiceId: json['invoice_id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Traveler',
      date: json['date']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      total: double.tryParse(rawTotal) ?? 0.0,
      balance: double.tryParse(rawBal) ?? 0.0,
      status: json['status']?.toString().toLowerCase() ?? 'draft',
    );
  }
}

class GoogleAdsConversionModel {
  final int id;
  final String eventType;
  final String channel;
  final String source;
  final String gclid;
  final String campaign;
  final String keyword;
  final String leadName;
  final String leadPhone;
  final String destination;
  final double value;
  final String date;

  GoogleAdsConversionModel({
    required this.id,
    required this.eventType,
    required this.channel,
    required this.source,
    required this.gclid,
    required this.campaign,
    required this.keyword,
    required this.leadName,
    required this.leadPhone,
    required this.destination,
    required this.value,
    required this.date,
  });

  factory GoogleAdsConversionModel.fromJson(Map<String, dynamic> json) {
    final rawVal = json['value']?.toString().replaceAll(',', '') ?? '0';

    return GoogleAdsConversionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      eventType: json['event_type']?.toString() ?? 'conversion',
      channel: json['channel']?.toString() ?? 'web_chatbot',
      source: json['source']?.toString() ?? 'google_ads',
      gclid: json['gclid']?.toString() ?? '',
      campaign: json['campaign']?.toString() ?? '',
      keyword: json['keyword']?.toString() ?? '',
      leadName: json['lead_name']?.toString() ?? '',
      leadPhone: json['lead_phone']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      value: double.tryParse(rawVal) ?? 0.0,
      date: json['date']?.toString() ?? '',
    );
  }
}
