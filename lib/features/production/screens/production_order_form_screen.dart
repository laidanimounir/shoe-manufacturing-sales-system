import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../data/production_order_model.dart';
import '../data/production_order_repository.dart';

class ProductionOrderFormScreen extends StatefulWidget {
  final ProductionOrder? order;
  const ProductionOrderFormScreen({super.key, this.order});

  bool get isEditing => order != null;

  @override
  State<ProductionOrderFormScreen> createState() => _ProductionOrderFormScreenState();
}

class _ProductionOrderFormScreenState extends State<ProductionOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _targetDate;
  String? _selectedProductId;
  String? _selectedRecipeId;
  String? _selectedWarehouseId;

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _warehouses = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    if (widget.order != null) {
      final o = widget.order!;
      _selectedProductId = o.productId;
      _selectedRecipeId = o.recipeId;
      _selectedWarehouseId = o.warehouseId;
      _qtyController.text = o.orderedQty.toString();
      _targetDate = o.targetDate;
      _notesController.text = o.notes ?? '';
    }
  }

  Future<void> _loadData() async {
    try {
      final client = SupabaseService.client;
      final results = await Future.wait([
        client.from('products').select('id, name').eq('is_active', true).order('name'),
        client.from('recipes').select('id, name, product_id, products!inner(name)').eq('is_active', true).order('name'),
        client.from('warehouses').select('id, name').eq('is_active', true).order('name'),
      ]);

      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(results[0] as List);
          _recipes = List<Map<String, dynamic>>.from(results[1] as List);
          _warehouses = List<Map<String, dynamic>>.from(results[2] as List);
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _getFilteredRecipes() {
    if (_selectedProductId == null) return [];
    return _recipes.where((r) => r['product_id'] == _selectedProductId).toList();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) { _showError('Veuillez sélectionner un produit'); return; }
    if (_selectedRecipeId == null) { _showError('Veuillez sélectionner une recette'); return; }
    if (_selectedWarehouseId == null) { _showError('Veuillez sélectionner un dépôt'); return; }

    setState(() => _isSaving = true);

    try {
      await ProductionOrderRepository.create(
        warehouseId: _selectedWarehouseId,
        productId: _selectedProductId,
        recipeId: _selectedRecipeId,
        orderedQty: int.tryParse(_qtyController.text) ?? 0,
        targetDate: _targetDate,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordre de production créé avec succès'),
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
        title: const Text('Nouvel ordre de production'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Enregistrer'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
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
                                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.precision_manufacturing, size: 18,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                            ),
                            const SizedBox(width: 12),
                            Text('Détails de l\'ordre', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedProductId,
                          decoration: const InputDecoration(
                            labelText: 'Produit *',
                            prefixIcon: Icon(Icons.inventory_2, size: 20),
                          ),
                          items: _products.map((p) => DropdownMenuItem(
                            value: p['id'] as String,
                            child: Text(p['name'] as String),
                          )).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedProductId = v;
                              _selectedRecipeId = null;
                            });
                          },
                          validator: (v) => v == null ? 'Sélectionnez un produit' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRecipeId,
                          decoration: const InputDecoration(
                            labelText: 'Recette *',
                            prefixIcon: Icon(Icons.menu_book, size: 20),
                          ),
                          items: _getFilteredRecipes().map((r) => DropdownMenuItem(
                            value: r['id'] as String,
                            child: Text(r['name'] as String),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedRecipeId = v),
                          validator: (v) => v == null ? 'Sélectionnez une recette' : null,
                          disabledHint: Text('Choisissez d\'abord un produit',
                              style: theme.textTheme.bodySmall),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedWarehouseId,
                          decoration: const InputDecoration(
                            labelText: 'Dépôt *',
                            prefixIcon: Icon(Icons.warehouse, size: 20),
                          ),
                          items: _warehouses.map((wh) => DropdownMenuItem(
                            value: wh['id'] as String,
                            child: Text(wh['name'] as String),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedWarehouseId = v),
                          validator: (v) => v == null ? 'Sélectionnez un dépôt' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantité commandée *',
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
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date cible',
                              prefixIcon: const Icon(Icons.calendar_today, size: 20),
                              suffixIcon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                            ),
                            child: Text(
                              _targetDate != null
                                  ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                                  : 'Sélectionner une date',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            hintText: 'Instructions, remarques...',
                            prefixIcon: Icon(Icons.notes, size: 20),
                          ),
                          textInputAction: TextInputAction.newline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18,
                            color: isDark ? AppColors.darkWarning : AppColors.lightWarning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Un nouvel ordre de production sera créé et enregistré dans l\'historique.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isDesktop) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
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
}
