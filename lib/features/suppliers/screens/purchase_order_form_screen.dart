import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../data/purchase_order_repository.dart';

class PurchaseOrderFormScreen extends StatefulWidget {
  const PurchaseOrderFormScreen({super.key});

  @override
  State<PurchaseOrderFormScreen> createState() => _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _selectedSupplierId;
  String? _selectedWarehouseId;
  String _orderType = 'raw_material';

  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _warehouses = [];
  final List<Map<String, dynamic>> _itemsList = [];
  bool _isSaving = false;
  String _paymentOption = 'none';
  final _partialAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final client = SupabaseService.client;
      final results = await Future.wait([
        client.from('suppliers').select('id, name').order('name'),
        client.from('warehouses').select('id, name').eq('is_active', true).order('name'),
      ]);

      if (mounted) {
        setState(() {
          _suppliers = List<Map<String, dynamic>>.from(results[0] as List);
          _warehouses = List<Map<String, dynamic>>.from(results[1] as List);
        });
      }
    } catch (e) {
      debugPrint('purchase_order_form _loadData: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _partialAmountController.dispose();
    super.dispose();
  }

  void _addItem() {
    final itemType = _orderType == 'finished_product' ? 'product' : 'raw_material';
    setState(() {
      _itemsList.add({
        'item_type': itemType,
        if (itemType == 'raw_material') 'raw_material_id': null,
        if (itemType == 'product') 'product_id': null,
        'quantity': 1,
        'unit_cost': 0,
      });
    });
  }

  void _removeItem(int index) {
    setState(() => _itemsList.removeAt(index));
  }

  double _calcTotal() {
    double total = 0;
    for (final item in _itemsList) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
      final cost = (item['unit_cost'] as num?)?.toDouble() ?? 0;
      total += qty * cost;
    }
    return total;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) { _showError('Sélectionnez un fournisseur'); return; }
    if (_itemsList.isEmpty) { _showError('Ajoutez au moins un article'); return; }

    final total = _calcTotal();
    final paidAmount = _paymentOption == 'full'
        ? total
        : _paymentOption == 'partial'
            ? (double.tryParse(_partialAmountController.text.replaceAll(',', '.')) ?? 0)
            : 0.0;

    setState(() => _isSaving = true);

    try {
      await PurchaseOrderRepository.create(
        supplierId: _selectedSupplierId!,
        warehouseId: _selectedWarehouseId,
        orderType: _orderType,
        totalAmount: total,
        paidAmount: paidAmount,
        notes: _notesController.text,
        items: _itemsList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bon de commande créé avec succès'),
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
        title: const Text('Nouveau bon de commande'),
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
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoSection(theme, isDark),
                  const SizedBox(height: 16),
                  _buildItemsSection(theme, isDark),
                  const SizedBox(height: 16),
                  _buildTotalSection(theme, isDark),
                  const SizedBox(height: 16),
                  _buildPaymentSection(theme, isDark),
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
              Text('Informations', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedSupplierId,
            decoration: const InputDecoration(
              labelText: 'Fournisseur *',
              prefixIcon: Icon(Icons.local_shipping, size: 20),
            ),
            items: _suppliers.map((s) => DropdownMenuItem(
              value: s['id'] as String,
              child: Text(s['name'] as String),
            )).toList(),
            onChanged: (v) => setState(() => _selectedSupplierId = v),
            validator: (v) => v == null ? 'Sélectionnez un fournisseur' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _orderType,
            decoration: const InputDecoration(
              labelText: "Type d'ordre *",
              prefixIcon: Icon(Icons.category, size: 20),
            ),
            items: const [
              DropdownMenuItem(value: 'raw_material', child: Text('Matière première')),
              DropdownMenuItem(value: 'finished_product', child: Text('Produit fini')),
            ],
            onChanged: (v) {
              setState(() {
                _orderType = v!;
                _itemsList.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedWarehouseId,
            decoration: const InputDecoration(
              labelText: 'Dépôt',
              prefixIcon: Icon(Icons.warehouse, size: 20),
            ),
            items: _warehouses.map((w) => DropdownMenuItem(
              value: w['id'] as String,
              child: Text(w['name'] as String),
            )).toList(),
            onChanged: (v) => setState(() => _selectedWarehouseId = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Remarques...',
              prefixIcon: Icon(Icons.notes, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(ThemeData theme, bool isDark) {
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
                  color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.list, size: 18,
                    color: isDark ? AppColors.darkWarning : AppColors.lightWarning),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Articles', style: theme.textTheme.titleMedium)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: 'Ajouter un article',
                onPressed: _addItem,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_itemsList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Aucun article. Cliquez sur + pour ajouter.',
                    style: theme.textTheme.bodySmall),
              ),
            )
          else
            Column(
              children: List.generate(_itemsList.length, (index) {
                return _buildItemRow(index, theme, isDark);
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, ThemeData theme, bool isDark) {
    final item = _itemsList[index];
    final itemType = item['item_type'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: itemType == 'raw_material'
                    ? _buildRawMaterialDropdown(item, theme)
                    : _buildProductDropdown(item, theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: '${item['quantity']}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qté',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) {
                    item['quantity'] = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: '${item['unit_cost']}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prix unitaire',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) {
                    item['unit_cost'] = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                    setState(() {});
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline, size: 20,
                    color: isDark ? AppColors.darkError : AppColors.lightError),
                tooltip: 'Supprimer',
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          if ((item['quantity'] as num?)?.toDouble() != null &&
              (item['unit_cost'] as num?)?.toDouble() != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Sous-total: ${((item['quantity'] as num?)?.toDouble() ?? 0) * ((item['unit_cost'] as num?)?.toDouble() ?? 0)} DZD',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRawMaterialDropdown(Map<String, dynamic> item, ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.client.from('raw_materials').select('id, name').order('name'),
      builder: (ctx, snapshot) {
        final materials = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          initialValue: item['raw_material_id'] as String?,
          decoration: const InputDecoration(
            labelText: 'Matière *',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: materials.map((m) => DropdownMenuItem(
            value: m['id'] as String,
            child: Text(m['name'] as String, style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: (v) => setState(() => item['raw_material_id'] = v),
          validator: (v) => v == null ? 'Obligatoire' : null,
        );
      },
    );
  }

  Widget _buildProductDropdown(Map<String, dynamic> item, ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.client.from('products').select('id, name').eq('is_active', true).order('name'),
      builder: (ctx, snapshot) {
        final products = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          initialValue: item['product_id'] as String?,
          decoration: const InputDecoration(
            labelText: 'Produit *',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: products.map((p) => DropdownMenuItem(
            value: p['id'] as String,
            child: Text(p['name'] as String, style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: (v) => setState(() => item['product_id'] = v),
          validator: (v) => v == null ? 'Obligatoire' : null,
        );
      },
    );
  }

  Widget _buildPaymentSection(ThemeData theme, bool isDark) {
    final total = _calcTotal();
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
                  color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payment, size: 18,
                    color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
              ),
              const SizedBox(width: 12),
              Text('Paiement', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _paymentOption,
            onChanged: (v) => setState(() => _paymentOption = v!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Aucun paiement'),
                  subtitle: Text('Dette de $total DZD', style: theme.textTheme.labelSmall),
                  value: 'none',
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Paiement complet'),
                  subtitle: Text('$total DZD payé', style: theme.textTheme.labelSmall),
                  value: 'full',
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Paiement partiel'),
                  value: 'partial',
                  dense: true,
                ),
              ],
            ),
          ),
          if (_paymentOption == 'partial')
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: TextFormField(
                controller: _partialAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant payé',
                  prefixText: 'DZD ',
                  hintText: 'Ex: ${(total / 2).toStringAsFixed(0)}',
                ),
                validator: (v) {
                  if (_paymentOption != 'partial') return null;
                  if (v == null || v.trim().isEmpty) return 'Le montant est obligatoire';
                  final amount = double.tryParse(v.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) return 'Montant invalide';
                  if (amount > total) return 'Ne peut pas dépasser $total DZD';
                  return null;
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(ThemeData theme, bool isDark) {
    final total = _calcTotal();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total estimé', style: theme.textTheme.titleSmall),
          Text('$total DZD',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
