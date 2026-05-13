import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../data/recipe_model.dart';
import '../data/recipe_repository.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;
  const RecipeFormScreen({super.key, this.recipe});

  bool get isEditing => recipe != null;

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedProductId;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _rawMaterials = [];

  List<_RecipeItemRow> _items = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    if (widget.recipe != null) {
      final r = widget.recipe!;
      _nameController.text = r.name;
      _selectedProductId = r.productId;
      _notesController.text = r.notes ?? '';
    }
  }

  Future<void> _loadData() async {
    try {
      final client = SupabaseService.client;
      final results = await Future.wait([
        client.from('products').select('id, name').eq('is_active', true).order('name'),
        client.from('raw_materials').select('id, name, unit').order('name'),
      ]);

      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(results[0] as List);
          _rawMaterials = List<Map<String, dynamic>>.from(results[1] as List);
        });

        if (widget.recipe != null) {
          _loadItems();
        }
      }
    } catch (e) {
      debugPrint('recipe_form_screen _loadData error: $e');
    }
  }

  Future<void> _loadItems() async {
    try {
      final items = await RecipeRepository.getItems(widget.recipe!.id);
      if (mounted) {
        setState(() {
          _items = items.map((item) => _RecipeItemRow(
            rawMaterialId: item.rawMaterialId,
            quantityPerUnit: item.quantityPerUnit,
            unit: item.unit,
          )).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_RecipeItemRow(
        rawMaterialId: null,
        quantityPerUnit: 1,
        unit: 'قطعة',
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      _showError('Veuillez sélectionner un produit');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final items = _items.map((item) => {
        'raw_material_id': item.rawMaterialId,
        'quantity_per_unit': item.quantityPerUnit,
        'unit': item.unit,
      }).toList();

      if (widget.isEditing) {
        await RecipeRepository.update(
          id: widget.recipe!.id,
          productId: _selectedProductId!,
          name: _nameController.text,
          notes: _notesController.text,
          items: items,
        );
      } else {
        await RecipeRepository.create(
          productId: _selectedProductId!,
          name: _nameController.text,
          notes: _notesController.text,
          items: items,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Recette modifiée avec succès' : 'Recette créée avec succès'),
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
        title: Text(widget.isEditing ? 'Modifier la recette' : 'Nouvelle recette'),
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
                                color: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.menu_book, size: 18,
                                  color: isDark ? AppColors.darkInfo : AppColors.lightInfo),
                            ),
                            const SizedBox(width: 12),
                            Text('Informations', style: theme.textTheme.titleMedium),
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
                          onChanged: (v) => setState(() => _selectedProductId = v),
                          validator: (v) => v == null ? 'Sélectionnez un produit' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom de la recette *',
                            hintText: 'Ex: Recette Classique A1',
                            prefixIcon: Icon(Icons.label, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Le nom est obligatoire' : null,
                          textInputAction: TextInputAction.next,
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
                            Expanded(child: Text('Matières premières', style: theme.textTheme.titleMedium)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              tooltip: 'Ajouter une matière',
                              onPressed: _addItem,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text('Aucune matière. Cliquez sur + pour ajouter.',
                                  style: theme.textTheme.bodySmall),
                            ),
                          )
                        else
                          Column(
                            children: List.generate(_items.length, (index) {
                              return _buildItemRow(index, theme, isDark);
                            }),
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
                                ? 'Les modifications seront enregistrées dans l\'historique d\'audit.'
                                : 'Une nouvelle recette sera créée et enregistrée dans l\'historique.',
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

  Widget _buildItemRow(int index, ThemeData theme, bool isDark) {
    final item = _items[index];
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
                child: DropdownButtonFormField<String>(
                  initialValue: item.rawMaterialId,
                  decoration: const InputDecoration(
                    labelText: 'Matière *',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _rawMaterials.map((rm) => DropdownMenuItem(
                    value: rm['id'] as String,
                    child: Text(rm['name'] as String, style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      final rm = _rawMaterials.firstWhere(
                        (rm) => rm['id'] == v,
                        orElse: () => {'unit': 'قطعة'},
                      );
                      setState(() {
                        item.rawMaterialId = v;
                        item.unit = rm['unit'] as String? ?? 'قطعة';
                      });
                    }
                  },
                  validator: (v) => v == null ? 'Obligatoire' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.quantityPerUnit.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Qté/unité',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixText: item.unit,
                  ),
                  onChanged: (v) {
                    item.quantityPerUnit = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obligatoire';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Invalide';
                    return null;
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
        ],
      ),
    );
  }
}

class _RecipeItemRow {
  String? rawMaterialId;
  double quantityPerUnit;
  String unit;

  _RecipeItemRow({
    this.rawMaterialId,
    this.quantityPerUnit = 1,
    this.unit = 'قطعة',
  });
}
