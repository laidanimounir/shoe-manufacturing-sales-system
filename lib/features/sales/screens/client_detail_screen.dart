import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/client_model.dart';
import '../data/client_repository.dart';
import '../data/invoice_repository.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  Client? _client;
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ClientRepository.getById(widget.clientId),
        InvoiceRepository.getAll(clientId: widget.clientId),
      ]);
      if (mounted) { setState(() { _client = results[0] as Client?; _invoices = results[1] is List<Map<String, dynamic>> ? (results[1] as List<Map<String, dynamic>>).take(20).toList() : []; _isLoading = false; }); }
    } catch (e) { if (mounted) { setState(() => _isLoading = false); _showError('Erreur: $e'); } }
  }

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18), const SizedBox(width: 8), Expanded(child: Text(message))]), behavior: SnackBarBehavior.floating));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(title: Text(_client?.fullName ?? 'Client'),
        actions: [if (_client != null) IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Modifier', onPressed: () { context.push('/clients/new', extra: _client).then((_) => _loadData()); })]),
      body: _isLoading ? _buildShimmer(isDark) : _client == null ? const Center(child: Text('Client introuvable'))
        : SingleChildScrollView(padding: EdgeInsets.all(isDesktop ? 24 : 16), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildInfoCard(theme, isDark, isDesktop),
          const SizedBox(height: 16),
          _buildInvoicesSection(theme, isDark),
        ])))),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark, bool isDesktop) {
    final c = _client!;
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person, size: 20, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.fullName, style: theme.textTheme.titleMedium), Text(c.clientTypeLabel, style: theme.textTheme.labelSmall)])),
        if (c.totalDebt > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text('Dette: ${CurrencyFormatter.format(c.totalDebt)}', style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkError : AppColors.lightError))),
      ]),
      const SizedBox(height: 16),
      if (isDesktop) Row(children: [
        Expanded(child: _infoTile(theme, 'Téléphone', c.phone ?? '-')),
        Expanded(child: _infoTile(theme, 'Email', c.email ?? '-')),
        Expanded(child: _infoTile(theme, 'Ville', c.city ?? '-')),
      ]) else ...[
        _infoTile(theme, 'Téléphone', c.phone ?? '-'), const SizedBox(height: 8),
        _infoTile(theme, 'Email', c.email ?? '-'), const SizedBox(height: 8),
        _infoTile(theme, 'Ville', c.city ?? '-'), const SizedBox(height: 8),
        _infoTile(theme, 'Adresse', c.address ?? '-'),
      ],
    ]));
  }

  Widget _infoTile(ThemeData theme, String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.textTheme.bodySmall?.color)), const SizedBox(height: 2), Text(value, style: theme.textTheme.bodyMedium)]);

  Widget _buildInvoicesSection(ThemeData theme, bool isDark) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text('Historique des factures', style: theme.textTheme.titleSmall), const Spacer(), Text('${_invoices.length} facture${_invoices.length > 1 ? 's' : ''}', style: theme.textTheme.labelSmall)]),
    const SizedBox(height: 12),
    if (_invoices.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Aucune facture', style: theme.textTheme.bodySmall)))
    else Column(children: _invoices.map((inv) {
      final status = inv['payment_status'] as String? ?? 'unpaid';
      final total = (inv['total_amount'] as num?)?.toDouble() ?? 0;
      final paid = (inv['paid_amount'] as num?)?.toDouble() ?? 0;
      final debt = total - paid;
      return Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)))), child: InkWell(
        onTap: () => context.push('/sales/${inv['id']}').then((_) => _loadData()),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(inv['invoice_number'] as String? ?? '-', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text('${CurrencyFormatter.format(total)} | Payé: ${CurrencyFormatter.format(paid)}', style: theme.textTheme.labelSmall),
          ])),
          if (debt > 0) Text(CurrencyFormatter.format(debt), style: GoogleFonts.jetBrainsMono(fontSize: 12, color: isDark ? AppColors.darkError : AppColors.lightError)),
          const SizedBox(width: 8), _statusChip(status, isDark), const SizedBox(width: 4), const Icon(Icons.chevron_right, size: 18),
        ]),
      ));
    }).toList()),
  ]));

  Widget _statusChip(String status, bool isDark) {
    Color c; String l;
    switch (status) { case 'paid': c = isDark ? AppColors.darkSuccess : AppColors.lightSuccess; l = 'Payée'; case 'partial': c = isDark ? AppColors.darkInfo : AppColors.lightInfo; l = 'Partielle'; case 'unpaid': default: c = isDark ? AppColors.darkError : AppColors.lightError; l = 'Impayée'; }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(l, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c)));
  }

  Widget _buildShimmer(bool isDark) => Shimmer.fromColors(baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8), highlightColor: isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA), child: Padding(padding: const EdgeInsets.all(24), child: Column(children: List.generate(4, (_) => Container(margin: const EdgeInsets.only(bottom: 12), height: 80, decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : AppColors.lightSurface, borderRadius: BorderRadius.circular(8)))))));
}
