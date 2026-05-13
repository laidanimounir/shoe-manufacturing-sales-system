import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../data/supplier_model.dart';
import '../data/supplier_repository.dart';
import '../data/purchase_order_repository.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  final String supplierId;
  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierDetailScreen> createState() =>
      _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  Supplier? _supplier;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupplierRepository.getById(widget.supplierId),
        PurchaseOrderRepository.getOrdersBySupplier(widget.supplierId),
      ]);

      if (mounted) {
        setState(() {
          _supplier = results[0] as Supplier?;
          _orders = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur: $e');
      }
    }
  }

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(_supplier?.name ?? 'Fournisseur'),
        actions: [
          if (_supplier != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () {
                context.push('/suppliers/new', extra: _supplier).then((_) => _loadData());
              },
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer(isDark)
          : _supplier == null
              ? const Center(child: Text('Fournisseur introuvable'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(theme, isDark, isDesktop),
                          const SizedBox(height: 16),
                          _buildOrdersSection(theme, isDark, isDesktop),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark, bool isDesktop) {
    final s = _supplier!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_shipping, size: 20,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: theme.textTheme.titleMedium),
                    Text(s.supplyTypeLabel, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              if (s.totalDebt > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Dette: ${CurrencyFormatter.format(s.totalDebt)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkError : AppColors.lightError,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _infoTile(theme, 'Téléphone', s.phone ?? '-')),
                Expanded(child: _infoTile(theme, 'Ville', s.city ?? '-')),
                Expanded(child: _infoTile(theme, 'Créé le', s.formattedDate)),
              ],
            )
          else ...[
            _infoTile(theme, 'Téléphone', s.phone ?? '-'),
            const SizedBox(height: 8),
            _infoTile(theme, 'Ville', s.city ?? '-'),
            const SizedBox(height: 8),
            _infoTile(theme, 'Adresse', s.address ?? '-'),
            const SizedBox(height: 8),
            _infoTile(theme, 'Créé le', s.formattedDate),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.textTheme.bodySmall?.color)),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildOrdersSection(ThemeData theme, bool isDark, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Bons de commande', style: theme.textTheme.titleSmall),
              const Spacer(),
              Text('${_orders.length} commande${_orders.length > 1 ? 's' : ''}',
                  style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          if (_orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Aucune commande', style: theme.textTheme.bodySmall),
              ),
            )
          else
            Column(
              children: _orders.map((o) {
                final status = o['status'] as String? ?? '';
                final statusLabel = _statusLabel(status);
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => context.push('/purchases/${o['id']}').then((_) => _loadData()),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${(o['total_amount'] as num?)?.toDouble() ?? 0} DZD',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                o['order_date'] != null
                                    ? AppDateUtils.formatDate(DateTime.tryParse(o['order_date'].toString()))
                                    : '-',
                                style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ),
                        _buildStatusChip(status, statusLabel, isDark),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'received':
        return 'Reçu';
      case 'partial':
        return 'Partiel';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Widget _buildStatusChip(String status, String label, bool isDark) {
    Color color;
    switch (status) {
      case 'pending':
        color = isDark ? AppColors.darkWarning : AppColors.lightWarning;
      case 'received':
        color = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      case 'partial':
        color = isDark ? AppColors.darkInfo : AppColors.lightInfo;
      case 'cancelled':
        color = isDark ? AppColors.darkError : AppColors.lightError;
      default:
        color = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
      highlightColor: isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: List.generate(4, (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(8),
            ),
          )),
        ),
      ),
    );
  }
}
