import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/warehouse_model.dart';
import '../data/warehouse_repository.dart';
import 'package:go_router/go_router.dart';

class WarehouseFormScreen extends StatefulWidget {
  final Warehouse? warehouse;

  const WarehouseFormScreen({super.key, this.warehouse});

  bool get isEditing => warehouse != null;

  @override
  State<WarehouseFormScreen> createState() => _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends State<WarehouseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.warehouse != null) {
      final w = widget.warehouse!;
      _nameController.text = w.name;
      _locationController.text = w.location ?? '';
      _isActive = w.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.isEditing) {
        await WarehouseRepository.update(
          id: widget.warehouse!.id,
          name: _nameController.text,
          location: _locationController.text.isEmpty
              ? null
              : _locationController.text,
          isActive: _isActive,
        );
      } else {
        await WarehouseRepository.create(
          name: _nameController.text,
          location: _locationController.text.isEmpty
              ? null
              : _locationController.text,
          isActive: _isActive,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Dépôt modifié avec succès'
                  : 'Dépôt créé avec succès',
            ),
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
                Icon(Icons.error_outline,
                    color: Theme.of(context).colorScheme.error, size: 18),
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
        title: Text(widget.isEditing ? 'Modifier le dépôt' : 'Nouveau dépôt'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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
                                color: (isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.lightPrimary)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.warehouse,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Informations du dépôt',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Nom du dépôt *',
                            hintText: 'Ex: Entrepôt Principal',
                            prefixIcon: Icon(Icons.business, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le nom est obligatoire';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Location
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Emplacement',
                            hintText: 'Ex: Alger, Zone Industrielle',
                            prefixIcon: Icon(Icons.location_on, size: 20),
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),

                        // Active toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Dépôt actif'),
                          subtitle: Text(
                            _isActive
                                ? 'Les opérations sont autorisées dans ce dépôt'
                                : 'Ce dépôt est désactivé',
                            style: theme.textTheme.bodySmall,
                          ),
                          value: _isActive,
                          activeTrackColor: isDark
                              ? AppColors.darkSuccess
                              : AppColors.lightSuccess,
                          onChanged: _isSaving
                              ? null
                              : (value) => setState(() => _isActive = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? AppColors.darkWarning
                              : AppColors.lightWarning)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isDark
                                ? AppColors.darkWarning
                                : AppColors.lightWarning)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: isDark
                              ? AppColors.darkWarning
                              : AppColors.lightWarning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.isEditing
                                ? 'La modification sera enregistrée dans l\'historique d\'audit.'
                                : 'Un nouvel entrepôt sera créé et enregistré dans l\'historique.',
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
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSaving
                            ? 'Enregistrement...'
                            : 'Enregistrer'),
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
