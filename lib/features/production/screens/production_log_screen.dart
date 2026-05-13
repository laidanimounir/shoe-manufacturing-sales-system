import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../data/production_order_model.dart';
import '../data/production_order_repository.dart';

class ProductionLogScreen extends StatefulWidget {
  final String orderId;
  const ProductionLogScreen({super.key, required this.orderId});

  @override
  State<ProductionLogScreen> createState() => _ProductionLogScreenState();
}

class _ProductionLogScreenState extends State<ProductionLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  ProductionOrder? _order;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrder());
  }

  Future<void> _loadOrder() async {
    final order = await ProductionOrderRepository.getById(widget.orderId);
    if (mounted) {
      setState(() => _order = order);
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

    setState(() => _isSaving = true);

    try {
      final profile = await SupabaseService.getCurrentProfile();
      final workerId = profile?['id'] as String?;
      final warehouseId = _order?.warehouseId;

      await ProductionOrderRepository.addWorkerLog(
        orderId: widget.orderId,
        workerId: workerId,
        warehouseId: warehouseId,
        quantity: int.tryParse(_qtyController.text) ?? 0,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Production enregistrée avec succès'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter production${_order != null ? ' - ${_order!.productName ?? ""}' : ''}'),
      ),
      body: Center(
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
                              child: Icon(Icons.factory, size: 18,
                                  color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
                            ),
                            const SizedBox(width: 12),
                            Text('Production du jour', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_order != null) ...[
                          _infoRow(theme, 'Produit', _order!.productName ?? '-'),
                          const SizedBox(height: 4),
                          _infoRow(theme, 'Restant à produire',
                              '${_order!.orderedQty - _order!.producedQty} paires'),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Quantité produite *',
                            hintText: 'Ex: 50',
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            hintText: 'Remarques sur la production du jour',
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
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer la production'),
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
