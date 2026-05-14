import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/production_cost_item_model.dart';
import '../data/production_cost_repository.dart';
import '../data/production_order_model.dart';
import '../data/production_order_repository.dart';

class ProductionCostScreen extends StatefulWidget {
  final String orderId;
  const ProductionCostScreen({super.key, required this.orderId});

  @override
  State<ProductionCostScreen> createState() => _ProductionCostScreenState();
}

class _ProductionCostScreenState extends State<ProductionCostScreen> {
  ProductionOrder? _order;
  List<ProductionCostItem> _costItems = [];
  double _sellingPrice = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final order = await ProductionOrderRepository.getById(widget.orderId);
      final items = await ProductionCostRepository.getCostItems(widget.orderId);

      double sellingPrice = 0;
      if (order?.productId != null) {
        final pId = order!.productId!;
        final productData = await SupabaseService.client
            .from('products')
            .select('selling_price')
            .eq('id', pId)
            .maybeSingle();
        sellingPrice = (productData?['selling_price'] as num?)?.toDouble() ?? 0;
      }

      if (mounted) {
        setState(() {
          _order = order;
          _costItems = items;
          _sellingPrice = sellingPrice;
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
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  Future<void> _showAddDialog(String costType) async {
    final labelController = TextEditingController();
    final amountController = TextEditingController();
    final label = ProductionCostItem(
      id: '',
      productionOrderId: '',
      costType: costType,
      label: '',
      amount: 0,
    ).costTypeLabel;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajouter $label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Libellé'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Montant'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result == true) {
      final labelText = labelController.text.trim();
      final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
      if (labelText.isEmpty || amount <= 0) return;

      await ProductionCostRepository.addCostItem(
        productionOrderId: widget.orderId,
        costType: costType,
        label: labelText,
        amount: amount,
      );
      await _refresh();
    }
  }

  Future<void> _showEditDialog(ProductionCostItem item) async {
    final amountController = TextEditingController(text: item.amount.toStringAsFixed(2));
    final labelController = TextEditingController(text: item.label);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier ${item.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Libellé'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Montant'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
      final labelText = labelController.text.trim();
      await ProductionCostRepository.updateCostItem(
        id: item.id,
        amount: amount,
        label: labelText.isNotEmpty ? labelText : null,
      );
      await _refresh();
    }
  }

  Future<void> _showDeleteConfirm(ProductionCostItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer "${item.label}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ProductionCostRepository.deleteCostItem(item.id);
      await _refresh();
    }
  }

  double _sectionSubtotal(List<ProductionCostItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final materials = _costItems.where((i) => i.costType == 'material').toList();
    final labors = _costItems.where((i) => i.costType == 'labor').toList();
    final others = _costItems.where((i) => i.costType == 'other').toList();

    final totalCost = _sectionSubtotal(materials) +
        _sectionSubtotal(labors) +
        _sectionSubtotal(others);
    final producedQty = _order?.producedQty ?? 0;
    final unitCost = producedQty > 0 ? totalCost / producedQty : 0.0;
    final margin = _sellingPrice > 0 && unitCost > 0
        ? ((_sellingPrice - unitCost) / unitCost) * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null
            ? 'Coût de revient — ${_order!.productName ?? ""} (${_order!.producedQty} paires)'
            : 'Coût de revient'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Ordre introuvable'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(theme, isDark, 'material', materials),
                          const SizedBox(height: 16),
                          _buildSection(theme, isDark, 'labor', labors),
                          const SizedBox(height: 16),
                          _buildSection(theme, isDark, 'other', others),
                          const SizedBox(height: 16),
                          _buildSummary(theme, isDark, unitCost, margin),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    bool isDark,
    String costType,
    List<ProductionCostItem> items,
  ) {
    final label = items.isNotEmpty
        ? items.first.costTypeLabel
        : ProductionCostItem(
            id: '',
            productionOrderId: '',
            costType: costType,
            label: '',
            amount: 0,
          ).costTypeLabel;
    final subtotal = _sectionSubtotal(items);

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
              Expanded(
                child: Text(label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 32,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddDialog(costType),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Aucun élément', style: theme.textTheme.bodySmall),
              ),
            )
          else
            ...items.map((item) => _buildItemRow(theme, isDark, item)),
          if (items.isNotEmpty) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sous-total', style: theme.textTheme.labelSmall),
                Text(
                  CurrencyFormatter.format(subtotal),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(
    ThemeData theme,
    bool isDark,
    ProductionCostItem item,
  ) {
    final unitStr = item.unitAmount != null && item.quantity != null
        ? '${CurrencyFormatter.formatNumber(item.unitAmount)}/unité × ${CurrencyFormatter.formatNumber(item.quantity)}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          if (item.isAuto)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Tooltip(
                message: 'Calculé automatiquement',
                child: Text('🔄',
                    style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark ? AppColors.darkInfo : AppColors.lightInfo)),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: theme.textTheme.bodyMedium),
                if (unitStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(unitStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              CurrencyFormatter.format(item.amount),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (item.isEditable)
            SizedBox(
              height: 28,
              child: IconButton(
                onPressed: () => _showEditDialog(item),
                icon: const Text('✏️', style: TextStyle(fontSize: 14)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 14,
              ),
            ),
          if (item.isEditable && !item.isAuto)
            SizedBox(
              height: 28,
              child: IconButton(
                onPressed: () => _showDeleteConfirm(item),
                icon: const Text('🗑️', style: TextStyle(fontSize: 14)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    ThemeData theme,
    bool isDark,
    double unitCost,
    double margin,
  ) {
    final marginColor = margin >= 0
        ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
        : (isDark ? AppColors.darkError : AppColors.lightError);

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
              Icon(Icons.account_balance_wallet,
                  size: 18,
                  color:
                      isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
              const SizedBox(width: 8),
              Text('Récapitulatif', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          _summaryRow(
              theme, 'Coût total unitaire', CurrencyFormatter.format(unitCost)),
          const SizedBox(height: 6),
          _summaryRow(
              theme, 'Prix de vente', CurrencyFormatter.format(_sellingPrice)),
          const SizedBox(height: 6),
          _summaryRow(theme, 'Marge', '${margin.toStringAsFixed(1)}%',
              valueColor: marginColor),
        ],
      ),
    );
  }

  Widget _summaryRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
