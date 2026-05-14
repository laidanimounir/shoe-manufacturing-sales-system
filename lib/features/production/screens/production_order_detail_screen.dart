import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../data/production_order_model.dart';
import '../data/production_order_repository.dart';

class ProductionOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ProductionOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<ProductionOrderDetailScreen> createState() => _ProductionOrderDetailScreenState();
}

class _ProductionOrderDetailScreenState extends ConsumerState<ProductionOrderDetailScreen> {
  ProductionOrder? _order;
  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic>? _costSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ProductionOrderRepository.getById(widget.orderId),
        ProductionOrderRepository.getLogs(widget.orderId),
        ProductionOrderRepository.getCostSummary(widget.orderId),
      ]);

      if (mounted) {
        setState(() {
          _order = results[0] as ProductionOrder?;
          _logs = results[1] as List<Map<String, dynamic>>;
          _costSummary = results[2] as Map<String, dynamic>?;
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

  Future<void> _updateStatus(String status) async {
    try {
      final label = AppStrings.productionStatusFr[status] ?? status;
      await ProductionOrderRepository.updateStatus(widget.orderId, status, label.toLowerCase());
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour : $label'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null
            ? 'Ordre ${_order!.id.substring(0, 8)}'
            : 'Détail de l\'ordre'),
        actions: [
          if (_order != null && _order!.status == 'pending')
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'in_progress', child: Text('Démarrer la production')),
                const PopupMenuItem(value: 'cancelled', child: Text('Annuler')),
              ],
              onSelected: (v) => _updateStatus(v),
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer(isDark)
          : _order == null
              ? const Center(child: Text('Ordre introuvable'))
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
                          _buildActionButtons(theme, isDark),
                          const SizedBox(height: 16),
                          _buildCostSummary(theme, isDark),
                          const SizedBox(height: 16),
                          _buildLogsSection(theme, isDark, isDesktop),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildOrderInfo(ThemeData theme, bool isDark, bool isDesktop) {
    final o = _order!;
    final statusLabel = AppStrings.productionStatusFr[o.status] ?? o.status;

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
                child: Icon(Icons.precision_manufacturing, size: 18,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Ordre #${o.id.substring(0, 8)}', style: theme.textTheme.titleMedium)),
              _buildStatusChip(o.status, statusLabel, isDark),
            ],
          ),
          const SizedBox(height: 16),
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _infoTile(theme, 'Produit', o.productName ?? '-')),
                Expanded(child: _infoTile(theme, 'Recette', o.recipeName ?? '-')),
                Expanded(child: _infoTile(theme, 'Dépôt', o.warehouseName ?? '-')),
              ],
            ),
          if (!isDesktop) ...[
            _infoTile(theme, 'Produit', o.productName ?? '-'),
            const SizedBox(height: 8),
            _infoTile(theme, 'Recette', o.recipeName ?? '-'),
            const SizedBox(height: 8),
            _infoTile(theme, 'Dépôt', o.warehouseName ?? '-'),
          ],
          const SizedBox(height: 8),
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _infoTile(theme, 'Quantité commandée', '${o.orderedQty} paires')),
                Expanded(child: _infoTile(theme, 'Produite', '${o.producedQty} paires')),
                Expanded(child: _infoTile(theme, 'En stock', '${o.enteredStockQty} paires')),
              ],
            )
          else ...[
            _infoTile(theme, 'Quantité commandée', '${o.orderedQty} paires'),
            const SizedBox(height: 8),
            _infoTile(theme, 'Produite', '${o.producedQty} paires'),
            const SizedBox(height: 8),
            _infoTile(theme, 'En stock', '${o.enteredStockQty} paires'),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (o.targetDate != null)
                _infoTile(theme, 'Date cible', AppDateUtils.formatDate(o.targetDate)),
              const SizedBox(width: 16),
              _infoTile(theme, 'Créé le', AppDateUtils.formatDate(o.createdAt)),
            ],
          ),
          if (o.notes != null && o.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoTile(theme, 'Notes', o.notes!),
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

  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    final o = _order!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          if (o.status == 'in_progress')
            FilledButton.icon(
              onPressed: () => context.push('/production/${widget.orderId}/log').then((_) => _loadData()),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter production'),
            ),
          if (o.producedQty > 0)
            FilledButton.icon(
              onPressed: () => context.push('/production/${widget.orderId}/entry').then((_) => _loadData()),
              icon: const Icon(Icons.inventory, size: 18),
              label: const Text('Entrée en stock'),
            ),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/production/${widget.orderId}/costs'),
            icon: const Icon(Icons.account_balance_wallet, size: 18),
            label: const Text('Coûts'),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary(ThemeData theme, bool isDark) {
    if (_costSummary == null) return const SizedBox.shrink();

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
              Icon(Icons.account_balance_wallet, size: 18,
                  color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
              const SizedBox(width: 8),
              Text('Récapitulatif des coûts', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text('Coût unitaire: ${CurrencyFormatter.format((_costSummary!['unit_cost'] as num?)?.toDouble() ?? 0)}',
              style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Coût total: ${CurrencyFormatter.format((_costSummary!['total_cost'] as num?)?.toDouble() ?? 0)}',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildLogsSection(ThemeData theme, bool isDark, bool isDesktop) {
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
              Text('Journal de production', style: theme.textTheme.titleSmall),
              const Spacer(),
              Text('${_logs.length} entrée${_logs.length > 1 ? 's' : ''}', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          if (_logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Aucune production enregistrée', style: theme.textTheme.bodySmall),
              ),
            )
          else
            Column(
              children: _logs.map((log) {
                final workerName = log['profiles'] is Map
                    ? (log['profiles'] as Map)['full_name'] as String?
                    : null;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${log['quantity']} paires', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text(workerName ?? 'Inconnu', style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                      Text(
                        log['log_date'] != null
                            ? AppDateUtils.formatDate(DateTime.tryParse(log['log_date'].toString()))
                            : '-',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      if (log['notes'] != null && (log['notes'] as String).isNotEmpty)
                        Tooltip(
                          message: log['notes'] as String,
                          child: Icon(Icons.info_outline, size: 16, color: theme.textTheme.bodySmall?.color),
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
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
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
