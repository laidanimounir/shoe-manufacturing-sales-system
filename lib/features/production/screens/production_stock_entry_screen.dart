import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
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
  ProductionOrder? _order;
  double _unitCost = 0;
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
        ProductionOrderRepository.getCostSummary(widget.orderId),
      ]);

      final order = results[0] as ProductionOrder?;
      final costSummary = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _order = order;
          _unitCost = (costSummary?['unit_cost'] as num?)?.toDouble() ?? 0;
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

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_unitCost <= 0) {
      _showError('Aucun coût unitaire calculé. Finalisez d\'abord les coûts de production.');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrée en stock'),
      ),
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
                            Container(
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
                                          color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.inventory, size: 18,
                                            color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Entrée en stock', style: theme.textTheme.titleMedium),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _infoRow(theme, 'Produit', _order!.productName ?? '-'),
                                  const SizedBox(height: 4),
                                  _infoRow(theme, 'Dépôt', _order!.warehouseName ?? '-'),
                                  const SizedBox(height: 4),
                                  _infoRow(theme, 'Produit (paires)', '${_order!.producedQty}'),
                                  const SizedBox(height: 4),
                                  _infoRow(theme, 'Déjà en stock', '${_order!.enteredStockQty}'),
                                  if (_unitCost > 0) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Text('Coût unitaire: ',
                                              style: theme.textTheme.bodyMedium),
                                          Text(
                                            CurrencyFormatter.format(_unitCost),
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.darkInfo : AppColors.lightInfo,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
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
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: _isSaving ? null : _save,
                                icon: _isSaving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.inventory),
                                label: Text(_isSaving ? 'Traitement...' : 'Valider l\'entrée en stock'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
