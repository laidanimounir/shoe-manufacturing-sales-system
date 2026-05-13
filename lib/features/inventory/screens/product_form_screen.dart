import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../data/product_model.dart';
import '../data/product_repository.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _materialController = TextEditingController();
  final _priceController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;

  static const _categories = [
    'Homme', 'Femme', 'Enfant', 'Sport', 'Sandales', 'Bottes', 'Mocassins', 'Tongs', 'Autre',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _categoryController.text = p.category ?? '';
      _sizeController.text = p.size ?? '';
      _colorController.text = p.color ?? '';
      _materialController.text = p.material ?? '';
      _priceController.text = p.sellingPrice > 0 ? p.sellingPrice.toStringAsFixed(2) : '';
      _skuController.text = p.sku ?? '';
      _barcodeController.text = p.barcode ?? '';
      _isActive = p.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _generateSku() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 100000;
    _skuController.text = 'PRD-$random';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text;
      final category = _categoryController.text;
      final size = _sizeController.text;
      final color = _colorController.text;
      final material = _materialController.text;
      final sku = _skuController.text;
      final barcode = _barcodeController.text;
      final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;

      if (widget.isEditing) {
        await ProductRepository.update(
          id: widget.product!.id,
          name: name,
          category: category.isEmpty ? null : category,
          size: size.isEmpty ? null : size,
          color: color.isEmpty ? null : color,
          material: material.isEmpty ? null : material,
          sku: sku.isEmpty ? null : sku,
          barcode: barcode.isEmpty ? null : barcode,
          sellingPrice: price,
          isActive: _isActive,
        );
      } else {
        await ProductRepository.create(
          name: name,
          category: category.isEmpty ? null : category,
          size: size.isEmpty ? null : size,
          color: color.isEmpty ? null : color,
          material: material.isEmpty ? null : material,
          sku: sku.isEmpty ? null : sku,
          barcode: barcode.isEmpty ? null : barcode,
          sellingPrice: price,
          isActive: _isActive,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Produit modifié avec succès' : 'Produit créé avec succès'),
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
        title: Text(widget.isEditing ? 'Modifier le produit' : 'Nouveau produit'),
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
                                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.inventory_2, size: 18,
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                            ),
                            const SizedBox(width: 12),
                            Text('Informations du produit', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildNameField(),
                                    const SizedBox(height: 16),
                                    _buildSizeField(),
                                    const SizedBox(height: 16),
                                    _buildMaterialField(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildCategoryField(),
                                    const SizedBox(height: 16),
                                    _buildColorField(),
                                    const SizedBox(height: 16),
                                    _buildPriceField(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildNameField(),
                          const SizedBox(height: 16),
                          _buildCategoryField(),
                          const SizedBox(height: 16),
                          _buildSizeField(),
                          const SizedBox(height: 16),
                          _buildColorField(),
                          const SizedBox(height: 16),
                          _buildMaterialField(),
                          const SizedBox(height: 16),
                          _buildPriceField(),
                        ],
                        const SizedBox(height: 16),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildSkuField()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildBarcodeField()),
                            ],
                          )
                        else ...[
                          _buildSkuField(),
                          const SizedBox(height: 16),
                          _buildBarcodeField(),
                        ],
                        const SizedBox(height: 20),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Produit actif'),
                          subtitle: Text(
                            _isActive
                                ? 'Disponible à la vente et à la production'
                                : 'Produit désactivé',
                            style: theme.textTheme.bodySmall,
                          ),
                          value: _isActive,
                          activeTrackColor: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                          onChanged: _isSaving ? null : (value) => setState(() => _isActive = value),
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
                                : 'Un nouveau produit sera créé et enregistré dans l\'historique.',
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

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      autofocus: true,
      decoration: const InputDecoration(
        labelText: 'Nom du produit *',
        hintText: 'Ex: Chaussure Sport Homme 42',
        prefixIcon: Icon(Icons.label, size: 20),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Le nom est obligatoire';
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildCategoryField() {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return _categories;
        return _categories.where((c) => c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      initialValue: TextEditingValue(text: _categoryController.text),
      onSelected: (value) => _categoryController.text = value,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Catégorie',
            hintText: 'Ex: Homme, Femme, Sport...',
            prefixIcon: Icon(Icons.category, size: 20),
          ),
          onFieldSubmitted: (_) => onSubmitted(),
          textInputAction: TextInputAction.next,
        );
      },
    );
  }

  Widget _buildSizeField() {
    return TextFormField(
      controller: _sizeController,
      decoration: const InputDecoration(
        labelText: 'Taille',
        hintText: 'Ex: 42, 43, M, L...',
        prefixIcon: Icon(Icons.straighten, size: 20),
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildColorField() {
    return TextFormField(
      controller: _colorController,
      decoration: const InputDecoration(
        labelText: 'Couleur',
        hintText: 'Ex: Noir, Blanc, Bleu...',
        prefixIcon: Icon(Icons.palette, size: 20),
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildMaterialField() {
    return TextFormField(
      controller: _materialController,
      decoration: const InputDecoration(
        labelText: 'Matière',
        hintText: 'Ex: Cuir, Synthétique, Tissu...',
        prefixIcon: Icon(Icons.texture, size: 20),
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Prix de vente *',
        hintText: 'Ex: 2500.00',
        prefixIcon: Icon(Icons.attach_money, size: 20),
        prefixText: 'DZD ',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Le prix est obligatoire';
        if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Prix invalide';
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildSkuField() {
    return TextFormField(
      controller: _skuController,
      decoration: InputDecoration(
        labelText: 'SKU',
        hintText: 'Code produit unique',
        prefixIcon: const Icon(Icons.qr_code, size: 20),
        suffixIcon: IconButton(
          icon: const Icon(Icons.auto_fix_high, size: 18),
          tooltip: 'Générer automatiquement',
          onPressed: _generateSku,
        ),
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildBarcodeField() {
    return TextFormField(
      controller: _barcodeController,
      decoration: const InputDecoration(
        labelText: 'Code-barres',
        hintText: 'Optionnel',
        prefixIcon: Icon(Icons.scanner, size: 20),
      ),
      textInputAction: TextInputAction.done,
    );
  }
}
