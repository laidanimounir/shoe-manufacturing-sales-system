import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../data/production_order_model.dart';
import '../data/production_order_repository.dart';

class ProductionOrderListScreen extends ConsumerStatefulWidget {
  const ProductionOrderListScreen({super.key});

  @override
  ConsumerState<ProductionOrderListScreen> createState() => _ProductionOrderListScreenState();
}

class _ProductionOrderListScreenState extends ConsumerState<ProductionOrderListScreen> {
  bool _isLoading = true;
  List<ProductionOrder> _orders = [];
  String _selectedStatus = 'all';

  static const _statusLabels = {
    'all': 'Tous',
    'pending': 'En attente',
    'in_progress': 'En cours',
    'completed': 'Terminé',
    'cancelled': 'Annulé',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final data = await ProductionOrderRepository.getAll(
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
    context.push('/production/new').then((_) => _loadData());
  }

  void _onDetail(ProductionOrder o) {
    context.push('/production/${o.id}').then((_) => _loadData());
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
                                Text('Ordres de production', style: theme.textTheme.headlineMedium),
                                const SizedBox(height: 4),
                                Text('Gestion de la production', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          if (isDesktop)
                            OutlinedButton.icon(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nouvel ordre'),
                            )
                          else
                            IconButton.filled(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add),
                              tooltip: 'Nouvel ordre',
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
          ),
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
                  '${_orders.length} ordre${_orders.length > 1 ? 's' : ''}',
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
                    DataColumn(label: Text('Ordre #')),
                    DataColumn(label: Text('Produit')),
                    DataColumn(label: Text('Dépôt')),
                    DataColumn(label: Text('Qté commandée'), numeric: true),
                    DataColumn(label: Text('Produite'), numeric: true),
                    DataColumn(label: Text('Statut')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _orders.map((o) {
                    final statusLabel = AppStrings.productionStatusFr[o.status] ?? o.status;
                    return DataRow(
                      onSelectChanged: (_) => _onDetail(o),
                      cells: [
                        DataCell(Text(o.id.substring(0, 8), style: GoogleFonts.jetBrainsMono(fontSize: 11))),
                        DataCell(Text(o.productName ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(o.warehouseName ?? '-', style: theme.textTheme.bodySmall)),
                        DataCell(Text('${o.orderedQty}', style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                        DataCell(Text('${o.producedQty}', style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                        DataCell(_buildStatusChip(o.status, statusLabel, isDark)),
                        DataCell(Text(AppDateUtils.formatDate(o.createdAt), style: theme.textTheme.bodySmall)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                              tooltip: 'Détails',
                              onPressed: () => _onDetail(o),
                            ),
                          ],
                        )),
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
            final statusLabel = AppStrings.productionStatusFr[o.status] ?? o.status;
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
                        child: Icon(Icons.precision_manufacturing, size: 20,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.productName ?? '-',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text('${o.orderedQty} paires', style: theme.textTheme.labelSmall),
                                if (o.warehouseName != null) ...[
                                  const SizedBox(width: 8),
                                  Text(o.warehouseName!, style: theme.textTheme.labelSmall),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(o.status, statusLabel, isDark),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 20),
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

  Widget _buildStatusChip(String status, String label, bool isDark) {
    Color color;
    switch (status) {
      case 'pending':
        color = isDark ? AppColors.darkWarning : AppColors.lightWarning;
      case 'in_progress':
        color = isDark ? AppColors.darkInfo : AppColors.lightInfo;
      case 'completed':
        color = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
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
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.precision_manufacturing_outlined, size: 48, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 12),
              Text('Aucun ordre de production', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Créez votre premier ordre de production', style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouvel ordre'),
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
