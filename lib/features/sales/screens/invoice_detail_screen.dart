import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../data/invoice_model.dart';
import '../data/invoice_item_model.dart';
import '../data/invoice_repository.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  Invoice? _invoice;
  List<InvoiceItem> _items = [];
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        InvoiceRepository.getById(widget.invoiceId),
        InvoiceRepository.getItems(widget.invoiceId),
        InvoiceRepository.getPayments(widget.invoiceId),
      ]);
      if (mounted) { setState(() { _invoice = results[0] as Invoice?; _items = results[1] as List<InvoiceItem>; _payments = results[2] as List<Map<String, dynamic>>; _isLoading = false; }); }
    } catch (e) { if (mounted) { setState(() => _isLoading = false); _showError('Erreur: $e'); } }
  }

  void _showError(String m) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18), const SizedBox(width: 8), Expanded(child: Text(m))]), behavior: SnackBarBehavior.floating));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(title: Text(_invoice != null ? _invoice!.invoiceNumber : 'Facture')),
      body: _isLoading ? _buildShimmer(isDark) : _invoice == null ? const Center(child: Text('Facture introuvable'))
        : SingleChildScrollView(padding: EdgeInsets.all(isDesktop ? 24 : 16), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(theme, isDark, isDesktop),
          const SizedBox(height: 16),
          _buildItemsTable(theme, isDark),
          const SizedBox(height: 16),
          _buildPaymentsSection(theme, isDark),
          const SizedBox(height: 16),
          _buildActionBar(theme, isDark),
        ])))),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, bool isDesktop) {
    final i = _invoice!;
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.receipt_long, size: 18, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
        const SizedBox(width: 12),
        Expanded(child: Text(i.invoiceNumber, style: theme.textTheme.titleMedium)),
        _statusChip(i.status, isDark),
      ]),
      const SizedBox(height: 16),
      if (isDesktop) Row(children: [
        Expanded(child: _infoTile(theme, 'Client', i.clientName ?? 'Au comptoir')),
        Expanded(child: _infoTile(theme, 'Dépôt', i.warehouseName ?? '-')),
        Expanded(child: _infoTile(theme, 'Vendeur', i.soldByName ?? '-')),
      ]) else ...[
        _infoTile(theme, 'Client', i.clientName ?? 'Au comptoir'), const SizedBox(height: 8),
        _infoTile(theme, 'Dépôt', i.warehouseName ?? '-'), const SizedBox(height: 8),
        _infoTile(theme, 'Vendeur', i.soldByName ?? '-'),
      ],
      const SizedBox(height: 8),
      if (isDesktop) Row(children: [
        Expanded(child: _infoTile(theme, 'Total', CurrencyFormatter.format(i.totalAmount))),
        Expanded(child: _infoTile(theme, 'Payé', CurrencyFormatter.format(i.paidAmount))),
        Expanded(child: _infoTile(theme, 'Reste', CurrencyFormatter.format(i.remainingDebt), debtColor: i.remainingDebt > 0)),
        Expanded(child: _infoTile(theme, 'Date', i.formattedDate)),
      ]) else ...[
        _infoTile(theme, 'Total', CurrencyFormatter.format(i.totalAmount)), const SizedBox(height: 8),
        _infoTile(theme, 'Payé', CurrencyFormatter.format(i.paidAmount)), const SizedBox(height: 8),
        _infoTile(theme, 'Reste', CurrencyFormatter.format(i.remainingDebt), debtColor: i.remainingDebt > 0),
      ],
    ]));
  }

  Widget _infoTile(ThemeData theme, String label, String value, {bool debtColor = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.textTheme.bodySmall?.color)), const SizedBox(height: 2), Text(value, style: TextStyle(color: debtColor ? (theme.brightness == Brightness.dark ? AppColors.darkError : AppColors.lightError) : null))]);

  Widget _buildItemsTable(ThemeData theme, bool isDark) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Articles', style: theme.textTheme.titleSmall), const SizedBox(height: 12),
    if (_items.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Aucun article', style: theme.textTheme.bodySmall)))
    else Column(children: _items.map((item) => Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)))), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.productName ?? '', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        Text('${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}, Coût: ${CurrencyFormatter.format(item.unitCost)}', style: theme.textTheme.labelSmall),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(CurrencyFormatter.format(item.subtotal), style: GoogleFonts.jetBrainsMono(fontSize: 13)),
        if (item.marginPercent > 0) Text('(+${item.marginPercent.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess)),
      ]),
    ]))).toList()),
    const SizedBox(height: 8),
    Align(alignment: Alignment.centerRight, child: Text('Total: ${CurrencyFormatter.format(_invoice!.totalAmount)}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
  ]));

  Widget _buildPaymentsSection(ThemeData theme, bool isDark) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text('Paiements', style: theme.textTheme.titleSmall), const Spacer(), Text('${_payments.length} paiement${_payments.length > 1 ? 's' : ''}', style: theme.textTheme.labelSmall)]),
    if (_payments.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Aucun paiement', style: theme.textTheme.bodySmall)))
    else Column(children: _payments.map((p) => Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)))), child: Row(children: [
      Expanded(child: Text('${CurrencyFormatter.format((p['amount'] as num?)?.toDouble() ?? 0)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
      Text(p['payment_date'] != null ? AppDateUtils.formatDate(DateTime.tryParse(p['payment_date'].toString())) : '-', style: theme.textTheme.bodySmall),
    ]))).toList()),
  ]));

  Widget _buildActionBar(ThemeData theme, bool isDark) {
    final i = _invoice!;
    if (i.status != 'paid' && i.remainingDebt > 0) {
      return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.3))), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Montant restant', style: theme.textTheme.labelSmall), Text(CurrencyFormatter.format(i.remainingDebt), style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkError : AppColors.lightError))])),
        FilledButton.icon(onPressed: () => context.push('/sales/${widget.invoiceId}/payment', extra: i).then((_) => _loadData()), icon: const Icon(Icons.payment, size: 18), label: const Text('Payer')),
      ]));
    }
    if (i.status == 'paid') {
      return Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.3))), child: Row(children: [Icon(Icons.check_circle, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess, size: 20), const SizedBox(width: 8), Text('Entièrement payée ✓', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess))]));
    }
    return const SizedBox.shrink();
  }

  Widget _statusChip(String status, bool isDark) {
    Color c; String l;
    switch (status) { case 'paid': c = isDark ? AppColors.darkSuccess : AppColors.lightSuccess; l = 'Payée ✓'; case 'partial': c = isDark ? AppColors.darkInfo : AppColors.lightInfo; l = 'Partielle'; case 'unpaid': default: c = isDark ? AppColors.darkError : AppColors.lightError; l = 'Impayée'; }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(l, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c)));
  }

  Widget _buildShimmer(bool isDark) => Shimmer.fromColors(baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8), highlightColor: isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA), child: Padding(padding: const EdgeInsets.all(24), child: Column(children: List.generate(4, (_) => Container(margin: const EdgeInsets.only(bottom: 12), height: 80, decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : AppColors.lightSurface, borderRadius: BorderRadius.circular(8)))))));
}
