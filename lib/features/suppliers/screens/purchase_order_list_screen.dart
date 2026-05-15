import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../data/purchase_order_model.dart';
import '../data/purchase_order_repository.dart';

class PurchaseOrderListScreen extends ConsumerStatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  ConsumerState<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState
    extends ConsumerState<PurchaseOrderListScreen> {
  bool _isLoading = true;
  List<PurchaseOrder> _orders = [];
  String _selectedStatus = 'all';

  static const _statusLabels = {
    'all': 'Tous',
    'pending': 'En attente',
    'received': 'Reçu',
    'partial': 'Partiel',
    'cancelled': 'Annulé',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final data = await PurchaseOrderRepository.getAll(
        status: _selectedStatus != 'all' ? _selectedStatus : null,
      );
      if (mounted) {
        setState(() {
          _orders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur de chargement: $e');
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

  void _onAdd() {
    context.push('/purchases/new').then((_) => _loadData());
  }

  void _onDetail(PurchaseOrder o) {
    context.push('/purchases/${o.id}').then((_) => _loadData());
  }

  void _onPay(PurchaseOrder o) {
    context.push('/purchases/${o.id}/payment', extra: o).then((_) => _loadData());
  }

  Future<void> _showReceivePreviewDialog(PurchaseOrder order) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    List<Map<String, dynamic>> previews;

    try {
      previews = await PurchaseOrderRepository.getReceivePreview(order.id);
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
                          _previewRow(currentQty.toStringAsFixed(1), 'Qté actuelle'),
                          _previewRow('+${purchaseQty.toStringAsFixed(1)}', '+ Achat'),
                          _previewRow(CurrencyFormatter.format(oldCost), 'Ancien coût/unit'),
                          _previewRow(CurrencyFormatter.format(newCost), 'Nouveau coût/unit (WACC)', highlight: true),
                        ] else ...[
                          _previewRow('+${purchaseQty.toStringAsFixed(0)} paires', 'Qté à ajouter'),
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
                  orderId: order.id,
                  warehouseId: order.warehouseId,
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

  Widget _previewRow(String value, String label, {bool highlight = false}) {
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
      body: CallbackShortcuts(
        bindings: {
          if (isDesktop)
            const SingleActivator(LogicalKeyboardKey.keyN, control: true): _onAdd,
        },
        child: Focus(
          autofocus: true,
          child: RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bons de commande', style: theme.textTheme.headlineMedium),
                                const SizedBox(height: 4),
                                Text('Gestion des achats', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          if (isDesktop)
                            OutlinedButton.icon(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nouveau bon'),
                            )
                          else
                            IconButton.filled(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add),
                              tooltip: 'Nouveau bon de commande',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFilterChips(theme, isDark),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                _buildShimmerList(isDark, isDesktop)
              else if (_orders.isEmpty)
                _buildEmptyState(theme)
              else if (isDesktop)
                _buildDesktopTable(theme, isDark)
              else
                _buildMobileCards(theme, isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusLabels.entries.map((entry) {
          final selected = _selectedStatus == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  _selectedStatus = entry.key;
                  _isLoading = true;
                });
                _loadData();
              },
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: theme.colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopTable(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Text(
                  '${_orders.length} commande${_orders.length > 1 ? 's' : ''}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 44,
                  headingRowHeight: 36,
                  columns: const [
                    DataColumn(label: Text('Commande #')),
                    DataColumn(label: Text('Fournisseur')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Total'), numeric: true),
                    DataColumn(label: Text('Payé'), numeric: true),
                    DataColumn(label: Text('Dette'), numeric: true),
                    DataColumn(label: Text('Statut')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _orders.map((o) {
                    return DataRow(
                      onSelectChanged: (_) => _onDetail(o),
                      cells: [
                        DataCell(Text(o.id.substring(0, 8),
                            style: GoogleFonts.jetBrainsMono(fontSize: 11))),
                        DataCell(Text(o.supplierName ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(o.orderType == 'raw_material' ? 'MP' : 'PF',
                            style: theme.textTheme.bodySmall)),
                        DataCell(Text(CurrencyFormatter.format(o.totalAmount),
                            style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                        DataCell(Text(CurrencyFormatter.format(o.paidAmount),
                            style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                        DataCell(Text(
                          CurrencyFormatter.format(o.debtAmount),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: o.debtAmount > 0
                                ? (isDark ? AppColors.darkError : AppColors.lightError)
                                : null,
                          ),
                        )),
                        DataCell(_buildStatusChip(o.status, o.statusLabel, isDark)),
                        DataCell(Text(AppDateUtils.formatDate(o.createdAt),
                            style: theme.textTheme.bodySmall)),
                        DataCell(_buildActionButtons(o, theme, isDark)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCards(ThemeData theme, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final o = _orders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _onDetail(o),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.receipt_long, size: 20,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.supplierName ?? '-',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(CurrencyFormatter.format(o.totalAmount),
                                    style: theme.textTheme.labelSmall),
                                if (o.debtAmount > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(CurrencyFormatter.format(o.debtAmount),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkError : AppColors.lightError,
                                      )),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(o.status, o.statusLabel, isDark),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        itemBuilder: (_) {
                          final items = <PopupMenuEntry<String>>[];
                          if (o.status == 'pending') {
                            items.add(const PopupMenuItem(
                                value: 'receive',
                                child: Row(children: [
                                  Icon(Icons.check_circle, size: 18, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Recevoir'),
                                ])));
                          }
                          if (o.status == 'received' && o.debtAmount > 0) {
                            items.add(const PopupMenuItem(
                                value: 'pay',
                                child: Row(children: [
                                  Icon(Icons.payment, size: 18, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Payer'),
                                ])));
                          }
                          items.add(const PopupMenuItem(
                              value: 'detail',
                              child: Row(children: [
                                Icon(Icons.visibility_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Détails'),
                              ])));
                          return items;
                        },
                        onSelected: (value) {
                          if (value == 'receive') {
                            _showReceivePreviewDialog(o);
                          } else if (value == 'pay') {
                            _onPay(o);
                          } else if (value == 'detail') {
                            _onDetail(o);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _orders.length,
        ),
      ),
    );
  }

  Widget _buildActionButtons(PurchaseOrder o, ThemeData theme, bool isDark) {
    final children = <Widget>[];

    if (o.status == 'pending') {
      children.add(
        SizedBox(
          height: 30,
          child: FilledButton.tonalIcon(
            onPressed: () => _showReceivePreviewDialog(o),
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Recevoir', style: TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              backgroundColor: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.15),
              foregroundColor: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
      );
      children.add(const SizedBox(width: 4));
    }

    if (o.status == 'received' && o.debtAmount > 0) {
      children.add(
        SizedBox(
          height: 30,
          child: FilledButton.tonalIcon(
            onPressed: () => _onPay(o),
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('Payer', style: TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              backgroundColor: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.15),
              foregroundColor: isDark ? AppColors.darkInfo : AppColors.lightInfo,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
      );
      children.add(const SizedBox(width: 4));
    }

    children.add(
      IconButton(
        icon: const Icon(Icons.visibility_outlined, size: 18),
        tooltip: 'Détails',
        onPressed: () => _onDetail(o),
      ),
    );

    return Row(mainAxisSize: MainAxisSize.min, children: children);
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

  Widget _buildEmptyState(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 48,
                  color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 12),
              Text('Aucun bon de commande', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Créez votre premier bon de commande',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau bon'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(bool isDark, bool isDesktop) {
    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
        highlightColor: isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
          child: Column(
            children: List.generate(5, (_) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(8),
              ),
            )),
          ),
        ),
      ),
    );
  }
}
