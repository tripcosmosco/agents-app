import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/financial_hub_model.dart';
import '../models/lead_model.dart';
import '../providers/lead_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class FinanceHubScreen extends StatefulWidget {
  final int initialTabIndex;

  const FinanceHubScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<FinanceHubScreen> createState() => _FinanceHubScreenState();
}

class _FinanceHubScreenState extends State<FinanceHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingBank = false;
  bool _isLoadingZoho = false;
  bool _isLoadingGAds = false;

  String? _bankError;
  String? _zohoError;
  String? _gadsError;

  BankSummaryModel? _bankSummary;
  List<BankTransactionModel> _bankTransactions = [];
  String _selectedTxnFilter = 'all'; // all, credit, debit, pending

  Map<String, dynamic>? _zohoMetrics;
  List<ZohoInvoiceModel> _zohoInvoices = [];
  bool _zohoConnected = false;
  String _zohoHelp = '';

  Map<String, dynamic>? _gadsSummary;
  List<dynamic> _gadsCampaigns = [];
  List<GoogleAdsConversionModel> _gadsEvents = [];

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadBankData(),
      _loadZohoData(),
      _loadGoogleAdsData(),
    ]);
  }

  Future<void> _loadBankData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBank = true;
      _bankError = null;
    });
    try {
      final api = Provider.of<LeadProvider>(context, listen: false).apiService;
      final res = await api.fetchBankTransactions(limit: 100);
      if (mounted) {
        if (res != null && res['ok'] == true) {
          final summaryRaw = res['summary'] as Map<String, dynamic>?;
          final txnsRaw = res['transactions'] as List<dynamic>? ?? [];
          setState(() {
            if (summaryRaw != null) {
              _bankSummary = BankSummaryModel.fromJson(Map<String, dynamic>.from(summaryRaw));
            }
            _bankTransactions = txnsRaw.whereType<Map>().map((e) => BankTransactionModel.fromJson(Map<String, dynamic>.from(e))).toList();
            _isLoadingBank = false;
            _bankError = null;
          });
        } else {
          setState(() {
            _isLoadingBank = false;
            _bankError = res?['message']?.toString() ?? res?['error']?.toString() ?? 'Unable to fetch bank transactions.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBank = false;
          _bankError = 'Connection error: $e';
        });
      }
    }
  }

  Future<void> _loadZohoData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingZoho = true;
      _zohoError = null;
    });
    try {
      final api = Provider.of<LeadProvider>(context, listen: false).apiService;
      final res = await api.fetchZohoSummary();
      if (mounted) {
        if (res != null && (res['ok'] == true || res['success'] == true)) {
          final metrics = res['metrics'] as Map<String, dynamic>? ?? {};
          final invoicesRaw = res['invoices'] as List<dynamic>? ?? [];
          setState(() {
            _zohoConnected = res['connected'] == true;
            _zohoHelp = res['help']?.toString() ?? '';
            _zohoMetrics = metrics;
            _zohoInvoices = invoicesRaw.whereType<Map>().map((e) => ZohoInvoiceModel.fromJson(Map<String, dynamic>.from(e))).toList();
            _isLoadingZoho = false;
            _zohoError = _zohoConnected ? null : (res['message']?.toString() ?? 'Zoho Books credentials pending.');
          });
        } else {
          setState(() {
            _isLoadingZoho = false;
            _zohoError = res?['message']?.toString() ?? res?['error']?.toString() ?? 'Unable to fetch Zoho data.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingZoho = false;
          _zohoError = 'Connection error: $e';
        });
      }
    }
  }

  void _showZohoConnectSheet() {
    final api = Provider.of<LeadProvider>(context, listen: false).apiService;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ZohoConnectSheet(
        apiService: api,
        onConnected: () {
          _loadZohoData();
        },
      ),
    );
  }

  Future<void> _loadGoogleAdsData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingGAds = true;
      _gadsError = null;
    });
    try {
      final api = Provider.of<LeadProvider>(context, listen: false).apiService;
      final res = await api.fetchGoogleAdsConversions();
      if (mounted) {
        if (res != null && res['ok'] == true) {
          final summary = res['summary'] as Map<String, dynamic>? ?? {};
          final campaigns = res['by_campaign'] as List<dynamic>? ?? [];
          final eventsRaw = res['events'] as List<dynamic>? ?? [];
          setState(() {
            _gadsSummary = summary;
            _gadsCampaigns = campaigns;
            _gadsEvents = eventsRaw.whereType<Map>().map((e) => GoogleAdsConversionModel.fromJson(Map<String, dynamic>.from(e))).toList();
            _isLoadingGAds = false;
            _gadsError = null;
          });
        } else {
          setState(() {
            _isLoadingGAds = false;
            _gadsError = res?['message']?.toString() ?? res?['error']?.toString() ?? 'Unable to fetch Google Ads events.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGAds = false;
          _gadsError = 'Connection error: $e';
        });
      }
    }
  }

  Future<void> _syncZoho() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing with Zoho Books API...')),
    );
    final api = Provider.of<LeadProvider>(context, listen: false).apiService;
    final res = await api.syncZohoInvoices();
    if (mounted) {
      if (res != null && (res['ok'] == true || res['success'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('✓ Zoho Books invoices synced successfully!'),
          ),
        );
        _loadZohoData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange,
            content: Text(res?['message'] ?? res?['error'] ?? 'Zoho Books connection ready.'),
          ),
        );
      }
    }
  }

  void _showStatementUploadModal() {
    final textController = TextEditingController();
    const String bankName = 'State Bank of India (SBI)';
    const String accountNo = '';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.upload_file_rounded, color: AppColors.accentGold, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Import SBI Bank Statement',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(ctx),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paste your SBI NetBanking statement CSV lines below. Columns supported:\nTxn Date, Value Date, Description, Ref No, Debit, Credit, Balance',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: textController,
                  maxLines: 7,
                  decoration: InputDecoration(
                    hintText: "Txn Date,Description,Ref No,Debit,Credit,Balance\n20/10/2026,UPI/CR/529812938192/Amit Sharma,UPI529812938192,,12500,85400\n19/10/2026,HOTEL TAJ GANGES,CHQ001928,8500,,72900",
                    hintStyle: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.getTextPrimary(ctx)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.paste_rounded, size: 16),
                        label: const Text('Insert Sample', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          textController.text =
                              "Txn Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance\n"
                              "20/10/2026,20/10/2026,UPI/CR/992182049182/Rahul Verma/Kashi Yatra,UPI992182049182,,15000.00,100400.00\n"
                              "20/10/2026,20/10/2026,BOAT RENTAL ASSI TO DASHASHWAMEDH,TXN482019,2500.00,,97900.00\n"
                              "19/10/2026,19/10/2026,HOTEL SURYA KAISER PALACE ADVANCE,CHQ991024,12000.00,,85900.00\n"
                              "18/10/2026,18/10/2026,GOOGLE ADS CAMPAIGN PAYMENT,GADS19281,4500.00,,73900.00";
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(
                          isSubmitting ? 'Importing...' : 'Parse & Save',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final csvText = textController.text.trim();
                                if (csvText.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter CSV data to import.')),
                                  );
                                  return;
                                }
                                setModalState(() => isSubmitting = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(ctx);
                                final api = Provider.of<LeadProvider>(context, listen: false).apiService;
                                final res = await api.uploadBankStatement(
                                  csvData: csvText,
                                  bankName: bankName,
                                  accountNo: accountNo,
                                );
                                setModalState(() => isSubmitting = false);
                                if (mounted) {
                                  if (navigator.canPop()) {
                                    navigator.pop();
                                  }
                                  if (res != null && res['ok'] == true) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text(res['message'] ?? 'Statement uploaded successfully!'),
                                      ),
                                    );
                                    _loadBankData();
                                  } else {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text(res?['error'] ?? res?['message'] ?? 'Upload failed.'),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() => textController.dispose());
  }

  void _showReconcileDialog(BankTransactionModel txn) {
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    final bookingIdController = TextEditingController();

    // Smart Lead Recommendation Heuristic based on name/phone matching transaction description
    LeadModel? suggestedLead;
    final lowerDesc = txn.description.toLowerCase();
    for (final l in leadProvider.leads) {
      final nameParts = l.name.toLowerCase().split(' ');
      final cleanPhone = l.phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.length >= 10 && lowerDesc.contains(cleanPhone.substring(cleanPhone.length - 10))) {
        suggestedLead = l;
        break;
      }
      for (final part in nameParts) {
        if (part.length > 2 && lowerDesc.contains(part)) {
          suggestedLead = l;
          break;
        }
      }
      if (suggestedLead != null) break;
    }

    if (suggestedLead != null) {
      bookingIdController.text = suggestedLead.id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.link_rounded, color: AppColors.accentGold),
              SizedBox(width: 8),
              Text('Reconcile Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Amount: ₹${txn.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(txn.description, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                const SizedBox(height: 14),

                if (suggestedLead != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Auto-Detected Match:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.green)),
                              Text(
                                '${suggestedLead.name} (${suggestedLead.destination})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const Text('Select Lead / Enter Booking ID:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),

                // Lead quick-select dropdown
                if (leadProvider.leads.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Choose from Active Leads...', style: TextStyle(fontSize: 12)),
                        items: leadProvider.leads.take(15).map((l) {
                          return DropdownMenuItem<String>(
                            value: l.id,
                            child: Text(
                              '${l.name} • ${l.destination} (ID: ${l.id})',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDlgState(() {
                              bookingIdController.text = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                TextField(
                  controller: bookingIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Booking / Lead ID',
                    hintText: 'e.g. 104',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: AppColors.primaryDark),
              onPressed: () async {
                final bId = int.tryParse(bookingIdController.text.trim());
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                final api = Provider.of<LeadProvider>(context, listen: false).apiService;
                final res = await api.reconcileBankTransaction(transactionId: txn.id, bookingId: bId);
                if (mounted) {
                  navigator.pop();
                  if (res != null && res['ok'] == true) {
                    messenger.showSnackBar(
                      const SnackBar(backgroundColor: Colors.green, content: Text('✓ Transaction successfully reconciled!')),
                    );
                    _loadBankData();
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text(res?['error'] ?? res?['message'] ?? 'Reconciliation could not be completed.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Confirm Link', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ).whenComplete(() => bookingIdController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.getCard(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.getTextPrimary(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Intelligence Hub',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            Text(
              'SBI Bank • Zoho Books • Google Ads Attribution',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh All Data',
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(context)),
            onPressed: _loadAll,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.getBorder(context),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accentGold,
              labelColor: AppColors.accentGold,
              unselectedLabelColor: AppColors.getTextSecondary(context),
              tabs: const [
                Tab(icon: Icon(Icons.account_balance_rounded, size: 19), text: 'SBI Banking'),
                Tab(icon: Icon(Icons.receipt_long_rounded, size: 19), text: 'Zoho Books'),
                Tab(icon: Icon(Icons.track_changes_rounded, size: 19), text: 'Google Ads'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBankTab(),
          _buildZohoTab(),
          _buildGoogleAdsTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: SBI BANKING & STATEMENT IMPORTER
  // ---------------------------------------------------------------------------
  Widget _buildBankTab() {
    if (_isLoadingBank && _bankSummary == null && _bankTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accentGold),
            const SizedBox(height: 16),
            Text(
              'Connecting to SBI Bank Ledger...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ],
        ),
      );
    }

    final summary = _bankSummary;
    final totalCredits = (summary != null && summary.totalCredits > 0)
        ? summary.totalCredits
        : _bankTransactions.where((t) => t.type == 'credit').fold(0.0, (s, t) => s + t.amount);
    final totalDebits = (summary != null && summary.totalDebits > 0)
        ? summary.totalDebits
        : _bankTransactions.where((t) => t.type == 'debit').fold(0.0, (s, t) => s + t.amount);
    final balance = summary?.netBalance ?? (totalCredits - totalDebits);

    final filteredTxns = _bankTransactions.where((t) {
      if (_selectedTxnFilter == 'credit') return t.type == 'credit';
      if (_selectedTxnFilter == 'debit') return t.type == 'debit';
      if (_selectedTxnFilter == 'pending') return !t.reconciled && t.type == 'credit';
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadBankData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Net Balance Hero Card
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_rounded, color: AppColors.accentGold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'SBI NetBanking Cash Balance',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.green, size: 13),
                            SizedBox(width: 4),
                            Text('Live Feed', style: TextStyle(color: Colors.green, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currencyFormatter.format(balance),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.green),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Inflow (Credits)', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context))),
                            const SizedBox(height: 2),
                            Text(
                              '+${currencyFormatter.format(totalCredits)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 30, width: 1, color: AppColors.getBorder(context)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Outflow (Debits)', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context))),
                            const SizedBox(height: 2),
                            Text(
                              '-${currencyFormatter.format(totalDebits)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.file_upload_rounded, size: 18),
                    label: const Text('Upload / Paste SBI Statement CSV', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: _showStatementUploadModal,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Filters Row (Horizontal scrollable to prevent RenderFlex overflow)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All (${_bankTransactions.length})', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Inflow (Credits)', 'credit'),
                const SizedBox(width: 8),
                _buildFilterChip('Outflow (Debits)', 'debit'),
                const SizedBox(width: 8),
                _buildFilterChip('Unreconciled', 'pending'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Transaction List
          if (filteredTxns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_outlined, size: 48, color: AppColors.getTextMuted(context)),
                    const SizedBox(height: 12),
                    Text(
                      _bankError != null
                          ? 'Bank Statement Feed Notice'
                          : 'No transactions found in this view',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _bankError ?? 'Upload your SBI NetBanking CSV statement or pull down to refresh live records.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: AppColors.getTextSecondary(context)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry Feed'),
                          onPressed: _loadBankData,
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGold,
                            foregroundColor: AppColors.primaryDark,
                          ),
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Import SBI Statement'),
                          onPressed: _showStatementUploadModal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredTxns.map((t) => _buildTransactionCard(t)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedTxnFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedTxnFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold
              : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightSurfaceElevated),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : AppColors.getBorder(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primaryDark : AppColors.getTextPrimary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BankTransactionModel t) {
    final isCredit = t.type == 'credit';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isCredit ? Colors.green : Colors.redAccent).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isCredit ? Colors.green : Colors.redAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.description,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.getTextPrimary(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(t.txnDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            if (t.refNo.isNotEmpty) ...[
                              const Text(' • ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Expanded(
                                child: Text(
                                  'Ref: ${t.refNo}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isCredit ? "+" : "-"}${currencyFormatter.format(t.amount)}',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: isCredit ? Colors.green : Colors.redAccent,
                        ),
                      ),
                      if (t.balance != null)
                        Text(
                          'Bal: ${currencyFormatter.format(t.balance!)}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(t.category, style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(context))),
                  ),
                  const SizedBox(width: 8),
                  if (isCredit)
                    if (t.reconciled)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  t.bookingRef.isNotEmpty ? 'Linked: ${t.bookingRef}' : 'Reconciled',
                                  style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.link_rounded, size: 14),
                        label: const Text('Link Booking', style: TextStyle(fontSize: 11)),
                        onPressed: () => _showReconcileDialog(t),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: ZOHO BOOKS / INVOICES
  // ---------------------------------------------------------------------------
  Widget _buildZohoTab() {
    if (_isLoadingZoho && _zohoMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalInvoiced = double.tryParse(_zohoMetrics?['total_invoiced']?.toString() ?? '0') ?? 0.0;
    final totalPaid = double.tryParse(_zohoMetrics?['total_paid']?.toString() ?? '0') ?? 0.0;
    final totalBalance = double.tryParse(_zohoMetrics?['total_balance']?.toString() ?? '0') ?? 0.0;
    final overdueCount = int.tryParse(_zohoMetrics?['overdue_count']?.toString() ?? '0') ?? 0;

    return RefreshIndicator(
      onRefresh: _loadZohoData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection Card
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_zohoConnected ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _zohoConnected ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                          color: _zohoConnected ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zoho Books API v3 Integration',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.getTextPrimary(context)),
                            ),
                            Text(
                              _zohoConnected ? 'Connected & Token Active' : 'Not Connected • Tap to Link',
                              style: TextStyle(
                                fontSize: 11,
                                color: _zohoConnected ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_zohoConnected) ...[
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 20),
                          tooltip: 'Zoho Settings',
                          color: AppColors.getTextSecondary(context),
                          onPressed: _showZohoConnectSheet,
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGold,
                            foregroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.sync_rounded, size: 15),
                          label: const Text('Sync Now', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          onPressed: _syncZoho,
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGold,
                            foregroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.link_rounded, size: 16),
                          label: const Text('Connect Zoho', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          onPressed: _showZohoConnectSheet,
                        ),
                      ],
                    ],
                  ),
                  if (_zohoHelp.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_zohoHelp, style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context))),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // KPI Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Total Invoiced',
                  currencyFormatter.format(totalInvoiced),
                  Icons.receipt_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  'Total Collected',
                  currencyFormatter.format(totalPaid),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Outstanding Balance',
                  currencyFormatter.format(totalBalance),
                  Icons.pending_actions_rounded,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  'Overdue Invoices',
                  '$overdueCount',
                  Icons.warning_amber_rounded,
                  Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Invoices Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Zoho Invoices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(context))),
              Text('Auto GST Invoicing', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context))),
            ],
          ),
          const SizedBox(height: 10),

          if (_zohoInvoices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _zohoConnected ? Icons.receipt_long_outlined : Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: AppColors.accentGold.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _zohoError ?? (_zohoConnected ? 'No Zoho invoices created yet.' : 'Zoho Books is not connected yet. Connect your accounts.zoho.in account to view live invoices.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (!_zohoConnected)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: const Text('Connect Zoho Books', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _showZohoConnectSheet,
                      )
                    else
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('Trigger Zoho Sync'),
                        onPressed: _syncZoho,
                      ),
                  ],
                ),
              ),
            )
          else
            ..._zohoInvoices.map((inv) => _buildInvoiceCard(inv)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 10.5, color: AppColors.getTextSecondary(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(ZohoInvoiceModel inv) {
    Color statusColor = Colors.grey;
    if (inv.status == 'paid') statusColor = Colors.green;
    if (inv.status == 'overdue') statusColor = Colors.redAccent;
    if (inv.status == 'sent') statusColor = Colors.blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.invoiceNumber,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.getTextPrimary(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(inv.customerName, style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context))),
                    const SizedBox(height: 4),
                    Text('Date: ${inv.date} • Due: ${inv.dueDate}', style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(context))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormatter.format(inv.total),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.getTextPrimary(context)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      inv.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: GOOGLE ADS & CHATBOT CONVERSIONS
  // ---------------------------------------------------------------------------
  Widget _buildGoogleAdsTab() {
    if (_isLoadingGAds && _gadsSummary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalConversions = int.tryParse(_gadsSummary?['total_conversions']?.toString() ?? '0') ?? 0;
    final totalVal = double.tryParse(_gadsSummary?['total_value']?.toString() ?? '0') ?? 0.0;
    final gadsCount = int.tryParse(_gadsSummary?['google_ads_count']?.toString() ?? '0') ?? 0;
    final chatbotCount = int.tryParse(_gadsSummary?['chatbot_leads_count']?.toString() ?? '0') ?? 0;
    final waCount = int.tryParse(_gadsSummary?['whatsapp_clicks_count']?.toString() ?? '0') ?? 0;
    final callsCount = int.tryParse(_gadsSummary?['phone_calls_count']?.toString() ?? '0') ?? 0;

    return RefreshIndicator(
      onRefresh: _loadGoogleAdsData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Conversion Tracking Health Banner
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.ads_click_rounded, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Ads Conversion Cockpit',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.getTextPrimary(context)),
                            ),
                            const Text('GTM dataLayer • Chatbot Telemetry Active', style: TextStyle(fontSize: 11, color: Colors.green)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Live Tracking', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All events from the website AI Chatbot, WhatsApp booking clicks, and phone dialer are tagged with GCLID & UTM parameters and mirrored to X-Agents.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // KPI Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Total Conversions',
                  '$totalConversions',
                  Icons.flag_rounded,
                  AppColors.accentGold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  'Pipeline Value',
                  currencyFormatter.format(totalVal),
                  Icons.monetization_on_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Google Ads Clicks',
                  '$gadsCount',
                  Icons.campaign_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  'Chatbot Leads',
                  '$chatbotCount',
                  Icons.smart_toy_rounded,
                  Colors.purpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'WhatsApp Clicks',
                  '$waCount',
                  Icons.chat_bubble_rounded,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  'Direct Phone Calls',
                  '$callsCount',
                  Icons.phone_in_talk_rounded,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Campaigns Attribution
          if (_gadsCampaigns.isNotEmpty) ...[
            Text('Campaign Attribution Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(context))),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: _gadsCampaigns.map((c) {
                    final name = c['campaign_name']?.toString() ?? 'Direct';
                    final cnt = int.tryParse(c['count']?.toString() ?? '0') ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.campaign_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$cnt leads',
                              style: const TextStyle(fontSize: 11, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Live Event Stream
          Text('Live Conversion Stream (Attributed)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(context))),
          const SizedBox(height: 10),

          if (_gadsEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  _gadsError ?? 'No conversion events recorded yet.',
                  style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12),
                ),
              ),
            )
          else
            ..._gadsEvents.map((e) => _buildConversionEventCard(e)),
        ],
      ),
    );
  }

  Widget _buildConversionEventCard(GoogleAdsConversionModel e) {
    IconData icon = Icons.touch_app_rounded;
    Color iconColor = Colors.blue;
    if (e.eventType.contains('chatbot')) {
      icon = Icons.smart_toy_rounded;
      iconColor = Colors.purpleAccent;
    } else if (e.eventType.contains('whatsapp')) {
      icon = Icons.chat_bubble_rounded;
      iconColor = Colors.teal;
    } else if (e.eventType.contains('phone')) {
      icon = Icons.phone_in_talk_rounded;
      iconColor = Colors.amber;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.leadName.isNotEmpty ? e.leadName : (e.leadPhone.isNotEmpty ? e.leadPhone : 'Web Visitor'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Event: ${e.eventType.replaceAll('_', ' ')}',
                          style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w600),
                        ),
                        if (e.campaign.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('Campaign: ${e.campaign}', style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context))),
                        ],
                        if (e.gclid.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'GCLID: ${e.gclid.substring(0, e.gclid.length > 20 ? 20 : e.gclid.length)}...',
                            style: const TextStyle(fontSize: 10, color: Colors.blue, fontFamily: 'monospace'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (e.value > 0)
                        Text(
                          currencyFormatter.format(e.value),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        e.date.length > 16 ? e.date.substring(0, 16).replaceAll('T', ' ') : e.date,
                        style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZohoConnectSheet extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onConnected;

  const _ZohoConnectSheet({
    required this.apiService,
    required this.onConnected,
  });

  @override
  State<_ZohoConnectSheet> createState() => _ZohoConnectSheetState();
}

class _ZohoConnectSheetState extends State<_ZohoConnectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _orgIdController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  final _refreshTokenController = TextEditingController();

  String _datacenter = 'zoho.in';
  bool _obscureSecret = true;
  bool _isConnecting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    try {
      final config = await widget.apiService.fetchZohoConfig();
      if (config != null && mounted) {
        setState(() {
          final dc = config['datacenter']?.toString();
          if (dc != null && dc.isNotEmpty) {
            _datacenter = dc;
          }
          final org = config['org_id']?.toString();
          if (org != null && org.isNotEmpty) {
            _orgIdController.text = org;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _orgIdController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _refreshTokenController.dispose();
    super.dispose();
  }

  Future<void> _pasteTo(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        controller.text = data.text!.trim();
      });
    }
  }

  Future<void> _submitConnect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await widget.apiService.connectZoho(
      clientId: _clientIdController.text,
      clientSecret: _clientSecretController.text,
      refreshToken: _refreshTokenController.text,
      orgId: _orgIdController.text,
      datacenter: _datacenter,
    );

    if (!mounted) return;

    if (res != null && (res['ok'] == true || res['success'] == true)) {
      setState(() {
        _isConnecting = false;
        _successMessage = res['message']?.toString() ?? 'Connected to Zoho Books successfully!';
      });

      widget.onConnected();

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    } else {
      setState(() {
        _isConnecting = false;
        _errorMessage = res?['message']?.toString() ?? res?['error']?.toString() ?? 'Failed to authenticate with Zoho Books.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: AppColors.getCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.getTextMuted(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.accentGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect Zoho Books',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        Text(
                          'OAuth 2.0 Invoicing & Ledger API',
                          style: TextStyle(fontSize: 11.5, color: AppColors.getTextSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(
                'Data Center Region',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context)),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _datacenter,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.getElevated(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'zoho.in', child: Text('India (accounts.zoho.in)')),
                  DropdownMenuItem(value: 'zoho.com', child: Text('Global / US (accounts.zoho.com)')),
                  DropdownMenuItem(value: 'zoho.eu', child: Text('Europe (accounts.zoho.eu)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _datacenter = val);
                },
              ),
              const SizedBox(height: 14),

              Text(
                'Organization ID',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _orgIdController,
                style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. 60012345678',
                  filled: true,
                  fillColor: AppColors.getElevated(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded, size: 18),
                    tooltip: 'Paste',
                    onPressed: () => _pasteTo(_orgIdController),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Organization ID is required' : null,
              ),
              const SizedBox(height: 14),

              Text(
                'Client ID',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _clientIdController,
                style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. 1000.XXXXX',
                  filled: true,
                  fillColor: AppColors.getElevated(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded, size: 18),
                    tooltip: 'Paste',
                    onPressed: () => _pasteTo(_clientIdController),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Client ID is required' : null,
              ),
              const SizedBox(height: 14),

              Text(
                'Client Secret',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _clientSecretController,
                obscureText: _obscureSecret,
                style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Client Secret key',
                  filled: true,
                  fillColor: AppColors.getElevated(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_obscureSecret ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                      ),
                      IconButton(
                        icon: const Icon(Icons.paste_rounded, size: 18),
                        tooltip: 'Paste',
                        onPressed: () => _pasteTo(_clientSecretController),
                      ),
                    ],
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Client Secret is required' : null,
              ),
              const SizedBox(height: 14),

              Text(
                'OAuth Refresh Token',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextPrimary(context)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _refreshTokenController,
                maxLines: 2,
                style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '1000.XXXXX...',
                  filled: true,
                  fillColor: AppColors.getElevated(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded, size: 18),
                    tooltip: 'Paste',
                    onPressed: () => _pasteTo(_refreshTokenController),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Refresh token is required' : null,
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.accentGold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Generate tokens from api-console.zoho.in (Self Client) with scope: ZohoBooks.fullaccess.all',
                        style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isConnecting ? null : _submitConnect,
                  child: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                        )
                      : const Text(
                          'Test & Connect Zoho Books',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
