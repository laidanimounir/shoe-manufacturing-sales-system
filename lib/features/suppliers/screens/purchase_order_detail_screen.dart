import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../data/purchase_order_model.dart';
import '../data/purchase_order_item_model.dart';
import '../data/purchase_order_repository.dart';

class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const PurchaseOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState
    extends ConsumerState<PurchaseOrderDetailScreen> {
  PurchaseOrder? _order;
  List<PurchaseOrderItem> _items = [];
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
        PurchaseOrderRepository.getById(widget.orderId),
        PurchaseOrderRepository.getItems(widget.orderId),
        PurchaseOrderRepository.getPayments(widget.orderId),
      ]);

      if (mounted) {
        setState(() {
          _order = results[0] as PurchaseOrder?;
          _items = results[1] as List<PurchaseOrderItem>;
          _payments = results[2] as List<Map<String, dynamic>>;
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

  Future<void> _showReceivePreviewDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    List<Map<String, dynamic>> previews;

    try {
      previews = await PurchaseOrderRepository.getReceivePreview(widget.orderId);
    } catch (e) {
      _showError('Erreur de chargement: $e');
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation de réception'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Les stocks seront mis à jour avec les nouveaux coûts (WACC) :',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                ...previews.map((p) {
                  final isRM = p['item_type'] == 'raw_material';
                  final name = p['name'] as String;
                  final currentQty = p['current_qty'] as double;
                  final purchaseQty = p['purchase_qty'] as double;
                  final oldCost = p['old_unit_cost'] as double;
                  final newCost = p['new_unit_cost'] as double;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isRM ? Icons.inventory_2 : Icons.inventory,
                              size: 16,
                              color: isRM
                                  ? (isDark ? AppColors.darkWarning : AppColors.lightWarning)
                                  : (isDark ? AppColors.darkInfo : AppColors.lightInfo),
                            ),
                            const SizedBox(width: 8),
                            Text(name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isRM) ...[
                          _previewRow('Qté actuelle', currentQty.toStringAsFixed(1)),
                          _previewRow('+ Achat', '+${purchaseQty.toStringAsFixed(1)}'),
                          _previewRow('Ancien coût/unit', CurrencyFormatter.format(oldCost)),
                          _previewRow(
                            'Nouveau coût/unit (WACC)',
                            CurrencyFormatter.format(newCost),
                            highlight: true,
                          ),
                        ] else ...[
                          _previewRow('Qté à ajouter', '+${purchaseQty.toStringAsFixed(0)} paires'),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16,
                          color: isDark ? AppColors.darkWarning : AppColors.lightWarning),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'WACC: nouvelle moyenne pondérée du coût unitaire après cet achat.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await PurchaseOrderRepository.receive(
                  orderId: widget.orderId,
                  warehouseId: _order!.warehouseId,
                );
                await _loadData();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Commande reçue et stock mis à jour'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Confirmer la réception'),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSuccess
                      : AppColors.lightSuccess)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null
            ? 'Commande #${_order!.id.substring(0, 8)}'
            : 'Détail commande'),
        actions: [
          if (_order != null && _order!.status == 'pending')
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Annuler la commande',
              onPressed: () async {
                try {
                  await PurchaseOrderRepository.updateStatus(
                      widget.orderId, 'cancelled', 'annulée');
                  await _loadData();
                } catch (e) {
                  _showError('Erreur: $e');
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer(isDark)
          : _order == null
              ? const Center(child: Text('Commande introuvable'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOrderInfo(theme, isDark, isDesktop),
                          const SizedBox(height: 16),
                          _buildItemsTable(theme, isDark),
                          const SizedBox(height: 16),
                          _buildPaymentsSection(theme, isDark, isDesktop),
                          const SizedBox(height: 16),
                          _buildActionBar(theme, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildOrderInfo(ThemeData theme, bool isDark, bool isDesktop) {
    final o = _order!;
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long, size: 18,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Commande #${o.id.substring(0, 8)}',
                      style: theme.textTheme.titleMedium)),
              _buildStatusChip(o.status, o.statusLabel, isDark),
            ],
          ),
          const SizedBox(height: 16),
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _infoTile(theme, 'Fournisseur', o.supplierName ?? '-')),
                Expanded(child: _infoTile(theme, 'Dépôt', o.warehouseName ?? '-')),
                Expanded(
                    child: _infoTile(theme, 'Type',
                        o.orderType == 'raw_material' ? 'Matière première' : 'Produit fini')),
              ],
            )
          else ...[
            _infoTile(theme, 'Fournisseur', o.supplierName ?? '-'),
            const SizedBox(height: 8),
            _infoTile(theme, 'Dépôt', o.warehouseName ?? '-'),
            const SizedBox(height: 8),
            _infoTile(theme, 'Type',
                o.orderType == 'raw_material' ? 'Matière première' : 'Produit fini'),
          ],
          const SizedBox(height: 8),
          if (isDesktop)
            Row(
              children: [
                Expanded(
                    child: _infoTile(theme, 'Total',
                        CurrencyFormatter.format(o.totalAmount))),
                Expanded(
                    child: _infoTile(theme, 'Payé',
                        CurrencyFormatter.format(o.paidAmount))),
                Expanded(
                    child: _infoTile(
                        theme, 'Dette', CurrencyFormatter.format(o.debtAmount),
                        debtColor: o.debtAmount > 0)),
                Expanded(
                    child: _infoTile(theme, 'Date commande',
                        o.orderDate != null ? AppDateUtils.formatDate(o.orderDate) : '-')),
              ],
            )
          else ...[
            _infoTile(theme, 'Total', CurrencyFormatter.format(o.totalAmount)),
            const SizedBox(height: 8),
            _infoTile(theme, 'Payé', CurrencyFormatter.format(o.paidAmount)),
            const SizedBox(height: 8),
            _infoTile(theme, 'Dette', CurrencyFormatter.format(o.debtAmount),
                debtColor: o.debtAmount > 0),
          ],
          if (o.notes != null && o.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoTile(theme, 'Notes', o.notes!),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(ThemeData theme, String label, String value,
      {bool debtColor = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.textTheme.bodySmall?.color)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: debtColor
                ? (theme.brightness == Brightness.dark
                    ? AppColors.darkError
                    : AppColors.lightError)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(ThemeData theme, bool isDark) {
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
          Text('Articles', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Aucun article', style: theme.textTheme.bodySmall),
              ),
            )
          else
            Column(
              children: _items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.itemName,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text('${item.quantity} x ${CurrencyFormatter.format(item.unitCost)}',
                                style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                      Text(CurrencyFormatter.format(item.totalCost),
                          style: GoogleFonts.jetBrainsMono(fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ${CurrencyFormatter.format(_order!.totalAmount)}',
              style:
                  theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection(
      ThemeData theme, bool isDark, bool isDesktop) {
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
              Text('Paiements', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (_order!.debtAmount > 0)
                TextButton.icon(
                  onPressed: () {
                    context
                        .push('/purchases/${widget.orderId}/payment',
                            extra: _order)
                        .then((_) => _loadData());
                  },
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Enregistrer paiement'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_payments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Aucun paiement enregistré',
                    style: theme.textTheme.bodySmall),
              ),
            )
          else
            Column(
              children: _payments.map((p) {
                final method = p['payment_method'] as String? ?? '';
                final methodLabel = method == 'cash'
                    ? 'Espèces'
                    : method == 'bank_transfer'
                        ? 'Virement'
                        : 'Chèque';
                final userName = p['profiles'] is Map
                    ? (p['profiles'] as Map)['full_name'] as String?
                    : null;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                CurrencyFormatter.format((p['amount'] as num?)?.toDouble() ?? 0),
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text('$methodLabel${userName != null ? " - $userName" : ""}',
                                style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                      Text(
                        p['payment_date'] != null
                            ? AppDateUtils.formatDate(
                                DateTime.tryParse(p['payment_date'].toString()))
                            : '-',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme, bool isDark) {
    final o = _order!;
    if (o.status == 'pending') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: _showReceivePreviewDialog,
          icon: const Icon(Icons.check_circle, size: 20),
          label: const Text('Confirmer la réception'),
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
          ),
        ),
      );
    }

    if (o.status == 'received' && o.debtAmount > 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Montant restant',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color)),
                  Text(CurrencyFormatter.format(o.debtAmount),
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkError : AppColors.lightError)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                context.push('/purchases/${widget.orderId}/payment', extra: o)
                    .then((_) => _loadData());
              },
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Payer'),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkInfo : AppColors.lightInfo,
              ),
            ),
          ],
        ),
      );
    }

    if (o.status == 'received' && o.debtAmount <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle,
                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess, size: 20),
            const SizedBox(width: 8),
            Text('Entièrement payé ✓',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess)),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
