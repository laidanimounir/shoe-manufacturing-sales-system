import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/supabase_service.dart';
import '../data/production_order_model.dart';
import '../data/production_order_repository.dart';

class ProductionStockEntryScreen extends StatefulWidget {
  final String orderId;
  const ProductionStockEntryScreen({super.key, required this.orderId});

  @override
  State<ProductionStockEntryScreen> createState() => _ProductionStockEntryScreenState();
}

class _ProductionStockEntryScreenState extends State<ProductionStockEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;
  bool _isCalculating = false;
  ProductionOrder? _order;
  double _unitCost = 0;
  double _totalMaterialCost = 0;
  int _totalProduced = 0;
  List<Map<String, dynamic>> _recipeBreakdown = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndCalculate());
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAndCalculate() async {
    setState(() => _isCalculating = true);
    try {
      await ProductionOrderRepository.calculateAndSaveCost(widget.orderId);

      final results = await Future.wait([
        ProductionOrderRepository.getById(widget.orderId),
        ProductionOrderRepository.getCostSummary(widget.orderId),
      ]);

      final order = results[0] as ProductionOrder?;
      final costSummary = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _order = order;
          _unitCost = (costSummary?['unit_cost'] as num?)?.toDouble() ?? 0;
          _totalMaterialCost = (costSummary?['total_material_cost'] as num?)?.toDouble() ?? 0;
          _totalProduced = (costSummary?['total_pairs_produced'] as num?)?.toInt() ?? 0;
          _isCalculating = false;
          _isLoading = false;
        });
        await _loadRecipeBreakdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _isLoading = false;
        });
        _showError('Erreur: $e');
      }
    }
  }

  Future<void> _loadRecipeBreakdown() async {
    if (_order?.recipeId == null) return;
    try {
      final client = SupabaseService.client;
      final items = await client
          .from('recipe_items')
          .select('quantity_per_unit, unit, raw_materials!inner(name, unit_cost)')
          .eq('recipe_id', _order!.recipeId);
      if (mounted) {
        setState(() {
          _recipeBreakdown = (items as List).map((item) {
            final rm = item['raw_materials'] as Map;
            final qtyPerUnit = (item['quantity_per_unit'] as num?)?.toDouble() ?? 0;
            final rmCost = (rm['unit_cost'] as num?)?.toDouble() ?? 0;
            return {
              'name': rm['name'] as String? ?? '',
              'qty_per_unit': qtyPerUnit,
              'unit': item['unit'] as String? ?? '',
              'unit_cost': rmCost,
              'line_cost': qtyPerUnit * rmCost,
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_unitCost <= 0) {
      _showError('Aucun coût unitaire calculé.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final qty = int.tryParse(_qtyController.text) ?? 0;

      await ProductionOrderRepository.enterStock(
        orderId: widget.orderId,
        warehouseId: _order?.warehouseId,
        productId: _order?.productId,
        quantity: qty,
        unitCost: _unitCost,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$qty paires ajoutées au stock. Coût unitaire: ${CurrencyFormatter.format(_unitCost)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Erreur: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrée en stock')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Ordre introuvable'))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isDesktop ? 32 : 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isCalculating)
                              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                            else ...[
                              _buildInfoSection(theme, isDark),
                              const SizedBox(height: 16),
                              if (_unitCost > 0) _buildCostCard(theme, isDark),
                              const SizedBox(height: 16),
                              _buildEntryForm(theme, isDark),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 48,
                                child: FilledButton.icon(
                                  onPressed: _isSaving ? null : _save,
                                  icon: _isSaving
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.inventory),
                                  label: Text(_isSaving ? 'Traitement...' : "Valider l'entrée en stock"),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, bool isDark) {
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
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory, size: 18, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
            ),
            const SizedBox(width: 12),
            Text('Entrée en stock', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 16),
          _infoRow(theme, 'Produit', _order!.productName ?? '-'),
          const SizedBox(height: 4),
          _infoRow(theme, 'Dépôt', _order!.warehouseName ?? '-'),
          const SizedBox(height: 4),
          _infoRow(theme, 'Produit (paires)', '${_order!.producedQty}'),
          const SizedBox(height: 4),
          _infoRow(theme, 'Déjà en stock', '${_order!.enteredStockQty}'),
        ],
      ),
    );
  }

  Widget _buildCostCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.account_balance_wallet, size: 20, color: isDark ? AppColors.darkInfo : AppColors.lightInfo),
            const SizedBox(width: 8),
            Text('Coût de production calculé', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          if (_recipeBreakdown.isNotEmpty) ...[
            ..._recipeBreakdown.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${item['name']} (${item['qty_per_unit']} ${item['unit']} × ${CurrencyFormatter.format(item['unit_cost'])})',
                      style: const TextStyle(fontSize: 12))),
                  Text(CurrencyFormatter.format(item['line_cost']),
                      style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                ],
              ),
            )),
            const Divider(height: 16),
          ],
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Matières premières', style: theme.textTheme.bodyMedium),
            Text('${CurrencyFormatter.format(_unitCost)}/unité',
                style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkInfo : AppColors.lightInfo)),
          ]),
          const SizedBox(height: 2),
          _infoRow(theme, 'Main d\'œuvre', '0,00 DZD/u'),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Coût unitaire total', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(CurrencyFormatter.format(_unitCost),
                style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 2),
          _infoRow(theme, 'Quantité produite', '$_totalProduced paires'),
          _infoRow(theme, 'Coût total', CurrencyFormatter.format(_totalMaterialCost)),
        ],
      ),
    );
  }

  Widget _buildEntryForm(ThemeData theme, bool isDark) {
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
          TextFormField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Quantité à ajouter *',
              hintText: 'Ex: 100',
              prefixIcon: Icon(Icons.numbers, size: 20),
              suffixText: 'paires',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'La quantité est obligatoire';
              final qty = int.tryParse(v);
              if (qty == null || qty <= 0) return 'Quantité invalide';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          if (_unitCost > 0 && _qtyController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(theme, 'Coût total estimé',
                CurrencyFormatter.format(_unitCost * (int.tryParse(_qtyController.text) ?? 0))),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Remarques sur l\'entrée en stock',
              prefixIcon: Icon(Icons.notes, size: 20),
            ),
            textInputAction: TextInputAction.newline,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
