import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/invoice_model.dart';
import '../data/invoice_repository.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  String? _warehouseFilter;
  List<Invoice> _invoices = [];
  List<Invoice> _todayInvoices = [];
  Map<String, dynamic> _dailySummary = {};
  List<Map<String, dynamic>> _warehouses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final client = SupabaseService.client;
      final whData = await client.from('warehouses').select('id, name').eq('is_active', true).order('name');
      final results = await Future.wait([
        InvoiceRepository.getAll(status: _statusFilter != 'all' ? _statusFilter : null, warehouseId: _warehouseFilter, search: _searchController.text.isNotEmpty ? _searchController.text : null),
        InvoiceRepository.getTodaySales(warehouseId: _warehouseFilter),
        InvoiceRepository.getDailySummary(warehouseId: _warehouseFilter),
      ]);
      if (mounted) {
        setState(() {
          _warehouses = List<Map<String, dynamic>>.from(whData as List);
          _invoices = results[0] as List<Invoice>;
          _todayInvoices = results[1] as List<Invoice>;
          _dailySummary = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); _showError('Erreur: $e'); }
    }
  }

  void _showError(String m) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18), const SizedBox(width: 8), Expanded(child: Text(m))]), behavior: SnackBarBehavior.floating));
    });
  }

  void _onDetail(Invoice i) => context.push('/sales/${i.id}').then((_) => _loadData());

  @override
  void dispose() { _searchController.dispose(); _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventes'),
        actions: [
          DropdownButtonHideUnderline(child: DropdownButton<String?>(
            value: _warehouseFilter,
            hint: const Text('Dépôt', style: TextStyle(fontSize: 12)),
            style: theme.textTheme.bodySmall,
            items: [const DropdownMenuItem<String?>(value: null, child: Text('Tous', style: TextStyle(fontSize: 12))), ..._warehouses.map((w) => DropdownMenuItem<String?>(value: w['id'] as String, child: Text(w['name'] as String, style: const TextStyle(fontSize: 12))))],
            onChanged: (v) { setState(() { _warehouseFilter = v; _isLoading = true; }); _loadData(); },
          )),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Toutes les ventes'), Tab(text: "Ventes du jour")]),
      ),
      body: TabBarView(controller: _tabController, children: [
        _buildAllSalesTab(theme, isDark, isDesktop),
        _buildTodaySalesTab(theme, isDark, isDesktop),
      ]),
    );
  }

  Widget _buildAllSalesTab(ThemeData theme, bool isDark, bool isDesktop) {
    return Column(children: [
      Padding(padding: EdgeInsets.all(isDesktop ? 16 : 12), child: Row(children: [
        Expanded(child: TextField(
          controller: _searchController,
          decoration: InputDecoration(hintText: 'Rechercher facture ou client...', prefixIcon: const Icon(Icons.search, size: 20), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); _loadData(); }) : null, contentPadding: const EdgeInsets.symmetric(vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          onSubmitted: (_) => _loadData(),
        )),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/sales/new'), tooltip: 'Nouvelle vente', style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer)),
      ])),
      _buildStatusFilter(theme),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: _isLoading
              ? _buildShimmer(isDark, isDesktop)
              : _invoices.isEmpty
                  ? _buildEmpty(theme)
                  : _buildTable(_invoices, theme, isDark, isDesktop),
        ),
      ),
    ]);
  }

  Widget _buildTodaySalesTab(ThemeData theme, bool isDark, bool isDesktop) {
    final s = _dailySummary;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        _summaryCard('Chiffre d\'aff.', CurrencyFormatter.format(s['totalRevenue'] as double? ?? 0), isDark ? AppColors.darkSuccess : AppColors.lightSuccess, theme, isDark),
        const SizedBox(width: 8), _summaryCard('Encaissé', CurrencyFormatter.format(s['totalPaid'] as double? ?? 0), isDark ? AppColors.darkInfo : AppColors.lightInfo, theme, isDark),
        const SizedBox(width: 8), _summaryCard('Crédit', CurrencyFormatter.format(s['totalDebt'] as double? ?? 0), isDark ? AppColors.darkError : AppColors.lightError, theme, isDark),
        const SizedBox(width: 8), _summaryCard('Nb ventes', '${s['count'] ?? 0}', isDark ? AppColors.darkWarning : AppColors.lightWarning, theme, isDark),
      ])),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: _isLoading
              ? _buildShimmer(isDark, isDesktop)
              : _todayInvoices.isEmpty
                  ? _buildEmpty(theme, isToday: true)
                  : _buildTable(_todayInvoices, theme, isDark, isDesktop),
        ),
      ),
    ]);
  }

  Widget _summaryCard(String label, String value, Color color, ThemeData theme, bool isDark) => Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: theme.textTheme.labelSmall), const SizedBox(height: 4),
    Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
  ])));

  Widget _buildStatusFilter(ThemeData theme) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
    children: const [{'k': 'all', 'l': 'Toutes'}, {'k': 'paid', 'l': 'Payées'}, {'k': 'partial', 'l': 'Partielles'}, {'k': 'unpaid', 'l': 'Impayées'}].map((e) {
      final sel = _statusFilter == e['k'];
      return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(e['l']!), selected: sel, onSelected: (v) { setState(() { _statusFilter = e['k']!; _isLoading = true; }); _loadData(); }, selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15), checkmarkColor: theme.colorScheme.primary));
    }).toList(),
  )));

  Widget _buildTable(List<Invoice> invoices, ThemeData theme, bool isDark, bool isDesktop) {
    if (isDesktop) {
      return SingleChildScrollView(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Text('${invoices.length} vente${invoices.length > 1 ? 's' : ''}', style: theme.textTheme.labelLarge)),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 14, dataRowMinHeight: 44, dataRowMaxHeight: 44, headingRowHeight: 36,
          columns: const [DataColumn(label: Text('Facture #')), DataColumn(label: Text('Client')), DataColumn(label: Text('Total'), numeric: true), DataColumn(label: Text('Payé'), numeric: true), DataColumn(label: Text('Reste'), numeric: true), DataColumn(label: Text('Statut')), DataColumn(label: Text('Date')), DataColumn(label: Text('Actions'))],
          rows: invoices.map((i) => DataRow(onSelectChanged: (_) => _onDetail(i), cells: [
            DataCell(Text(i.invoiceNumber, style: GoogleFonts.jetBrainsMono(fontSize: 11))),
            DataCell(Text(i.clientName ?? 'Au comptoir', style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(CurrencyFormatter.format(i.totalAmount), style: GoogleFonts.jetBrainsMono(fontSize: 12))),
            DataCell(Text(CurrencyFormatter.format(i.paidAmount), style: GoogleFonts.jetBrainsMono(fontSize: 12))),
            DataCell(Text(CurrencyFormatter.format(i.remainingDebt), style: GoogleFonts.jetBrainsMono(fontSize: 12, color: i.remainingDebt > 0 ? (isDark ? AppColors.darkError : AppColors.lightError) : null))),
            DataCell(_statusChip(i.status, isDark)),
            DataCell(Text(i.formattedDate, style: theme.textTheme.bodySmall)),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () => _onDetail(i)),
              if (i.status != 'paid') IconButton(icon: Icon(Icons.payment, size: 18, color: isDark ? AppColors.darkInfo : AppColors.lightInfo), onPressed: () => context.push('/sales/${i.id}/payment', extra: i).then((_) => _loadData())),
            ])),
          ])).toList(),
        )),
      ]))));
    }
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: invoices.length, itemBuilder: (ctx, idx) {
      final i = invoices[idx];
      return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: InkWell(borderRadius: BorderRadius.circular(8), onTap: () => _onDetail(i), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(i.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text('${i.clientName ?? "Au comptoir"} | ${CurrencyFormatter.format(i.totalAmount)}', style: theme.textTheme.labelSmall),
        ])),
        _statusChip(i.status, isDark),
        const SizedBox(width: 4), const Icon(Icons.chevron_right, size: 20),
      ]))));
    });
  }

  Widget _statusChip(String status, bool isDark) {
    Color c; String l;
    switch (status) { case 'paid': c = isDark ? AppColors.darkSuccess : AppColors.lightSuccess; l = 'Payée ✓'; case 'partial': c = isDark ? AppColors.darkInfo : AppColors.lightInfo; l = 'Partielle'; case 'unpaid': default: c = isDark ? AppColors.darkError : AppColors.lightError; l = 'Impayée'; }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(l, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c)));
  }

  Widget _buildEmpty(ThemeData theme, {bool isToday = false}) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.receipt_long_outlined, size: 48, color: theme.textTheme.bodySmall?.color), const SizedBox(height: 12),
    Text(isToday ? 'Aucune vente aujourd\'hui' : 'Aucune vente', style: theme.textTheme.titleMedium),
  ]));

  Widget _buildShimmer(bool isDark, bool isDesktop) => Shimmer.fromColors(baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8), highlightColor: isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: List.generate(5, (_) => Container(margin: const EdgeInsets.only(bottom: 8), height: 56, decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : AppColors.lightSurface, borderRadius: BorderRadius.circular(8)))))));
}
