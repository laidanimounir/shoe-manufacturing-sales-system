import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../data/raw_material_model.dart';
import '../data/raw_material_repository.dart';

class RawMaterialFormScreen extends StatefulWidget {
  final RawMaterial? material;

  const RawMaterialFormScreen({super.key, this.material});

  bool get isEditing => material != null;

  @override
  State<RawMaterialFormScreen> createState() => _RawMaterialFormScreenState();
}

class _RawMaterialFormScreenState extends State<RawMaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _minQtyController = TextEditingController();
  final _costController = TextEditingController();
  String _selectedUnit = 'قطعة';
  String? _selectedWarehouseId;
  List<Map<String, dynamic>> _warehouses = [];
  bool _isSaving = false;

  static const _units = ['متر', 'كغ', 'قطعة', 'رول', 'لتر', 'أخرى'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWarehouses());
    if (widget.material != null) {
      final m = widget.material!;
      _nameController.text = m.name;
      _selectedUnit = m.unit;
      _selectedWarehouseId = m.warehouseId;
      _qtyController.text = m.quantity.toString();
      _minQtyController.text = m.minQuantity.toString();
      _costController.text = m.unitCost.toString();
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      final client = SupabaseService.client;
      final data = await client.from('warehouses').select('id, name').eq('is_active', true).order('name');
      if (mounted) {
        setState(() => _warehouses = List<Map<String, dynamic>>.from(data as List));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _minQtyController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text;
      final qty = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;
      final minQty = double.tryParse(_minQtyController.text.replaceAll(',', '.')) ?? 0;
      final cost = double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0;

      if (widget.isEditing) {
        await RawMaterialRepository.update(
          id: widget.material!.id,
          name: name,
          unit: _selectedUnit,
          warehouseId: _selectedWarehouseId,
          quantity: qty,
          minQuantity: minQty,
          unitCost: cost,
        );
      } else {
        await RawMaterialRepository.create(
          name: name,
          unit: _selectedUnit,
          warehouseId: _selectedWarehouseId,
          quantity: qty,
          minQuantity: minQty,
          unitCost: cost,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Matière modifiée avec succès' : 'Matière créée avec succès'),
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
        title: Text(widget.isEditing ? 'Modifier la matière' : 'Nouvelle matière'),
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
                                color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.inventory, size: 18,
                                  color: isDark ? AppColors.darkWarning : AppColors.lightWarning),
                            ),
                            const SizedBox(width: 12),
                            Text('Informations', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Nom de la matière *',
                            hintText: 'Ex: Cuir Noir, Colle, Lacets...',
                            prefixIcon: Icon(Icons.label, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Le nom est obligatoire' : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unité *',
                            prefixIcon: Icon(Icons.square_foot, size: 20),
                          ),
                          items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v!),
                          validator: (v) => v == null ? 'Sélectionnez une unité' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedWarehouseId,
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
                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(child: _buildQtyField()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMinQtyField()),
                            ],
                          )
                        else ...[
                          _buildQtyField(),
                          const SizedBox(height: 16),
                          _buildMinQtyField(),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _costController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Coût unitaire *',
                            hintText: 'Ex: 500',
                            prefixIcon: Icon(Icons.attach_money, size: 20),
                            prefixText: 'DZD ',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Le coût est obligatoire';
                            if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Coût invalide';
                            return null;
                          },
                          textInputAction: TextInputAction.done,
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
                            widget.isEditing
                                ? 'La modification sera enregistrée dans l\'historique d\'audit.'
                                : 'Une nouvelle matière sera créée et enregistrée dans l\'historique.',
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

  Widget _buildQtyField() {
    return TextFormField(
      controller: _qtyController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Quantité actuelle',
        hintText: 'Ex: 100',
        prefixIcon: const Icon(Icons.numbers, size: 20),
        suffixText: _selectedUnit,
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildMinQtyField() {
    return TextFormField(
      controller: _minQtyController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Quantité minimale',
        hintText: 'Ex: 10',
        prefixIcon: const Icon(Icons.warning_amber, size: 20),
        suffixText: _selectedUnit,
      ),
      textInputAction: TextInputAction.next,
    );
  }
}
