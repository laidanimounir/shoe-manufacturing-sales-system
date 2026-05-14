import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../data/client_model.dart';
import '../data/client_repository.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;
  const ClientFormScreen({super.key, this.client});
  bool get isEditing => client != null;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String _selectedType = 'wholesale';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      final c = widget.client!;
      _nameController.text = c.fullName;
      _phoneController.text = c.phone ?? '';
      _emailController.text = c.email ?? '';
      _addressController.text = c.address ?? '';
      _cityController.text = c.city ?? '';
      _selectedType = c.clientType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); _phoneController.dispose();
    _emailController.dispose(); _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (widget.isEditing) {
        await ClientRepository.update(id: widget.client!.id, fullName: _nameController.text, phone: _phoneController.text, email: _emailController.text, address: _addressController.text, city: _cityController.text, clientType: _selectedType);
      } else {
        await ClientRepository.create(fullName: _nameController.text, phone: _phoneController.text, email: _emailController.text, address: _addressController.text, city: _cityController.text, clientType: _selectedType);
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isEditing ? 'Client modifié avec succès' : 'Client créé avec succès'), behavior: SnackBarBehavior.floating)); context.pop(); }
    } catch (e) {
      if (mounted) { setState(() => _isSaving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18), const SizedBox(width: 8), Expanded(child: Text('Erreur: $e'))]), behavior: SnackBarBehavior.floating)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier le client' : 'Nouveau client'),
        actions: [
          TextButton.icon(onPressed: _isSaving ? null : _save, icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined, size: 18), label: const Text('Enregistrer')), const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(padding: EdgeInsets.all(isDesktop ? 32 : 16), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person, size: 18, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
            const SizedBox(width: 12), Text('Informations', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 20),
          TextFormField(controller: _nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Nom complet *', hintText: 'Ex: Ahmed SARL', prefixIcon: Icon(Icons.badge, size: 20)), validator: (v) => v == null || v.trim().isEmpty ? 'Le nom est obligatoire' : null, textInputAction: TextInputAction.next),
          const SizedBox(height: 16),
          if (isDesktop) Row(children: [
            Expanded(child: TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone', hintText: 'Ex: 0555 12 34 56', prefixIcon: Icon(Icons.phone, size: 20)), textInputAction: TextInputAction.next)),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', hintText: 'Ex: contact@abc.dz', prefixIcon: Icon(Icons.email, size: 20)), textInputAction: TextInputAction.next)),
          ]) else ...[
            TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone', hintText: 'Ex: 0555 12 34 56', prefixIcon: Icon(Icons.phone, size: 20)), textInputAction: TextInputAction.next),
            const SizedBox(height: 16),
            TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', hintText: 'Ex: contact@abc.dz', prefixIcon: Icon(Icons.email, size: 20)), textInputAction: TextInputAction.next),
          ],
          const SizedBox(height: 16),
          if (isDesktop) Row(children: [
            Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'Ville', hintText: 'Ex: Alger', prefixIcon: Icon(Icons.location_city, size: 20)), textInputAction: TextInputAction.next)),
            const SizedBox(width: 16),
            Expanded(child: DropdownButtonFormField<String>(initialValue: _selectedType, decoration: const InputDecoration(labelText: 'Type *', prefixIcon: Icon(Icons.category, size: 20)), items: const [DropdownMenuItem(value: 'wholesale', child: Text('Grossiste')), DropdownMenuItem(value: 'retail', child: Text('Détaillant'))], onChanged: (v) => setState(() => _selectedType = v!))),
          ]) else ...[
            TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'Ville', hintText: 'Ex: Alger', prefixIcon: Icon(Icons.location_city, size: 20)), textInputAction: TextInputAction.next),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(initialValue: _selectedType, decoration: const InputDecoration(labelText: 'Type *', prefixIcon: Icon(Icons.category, size: 20)), items: const [DropdownMenuItem(value: 'wholesale', child: Text('Grossiste')), DropdownMenuItem(value: 'retail', child: Text('Détaillant'))], onChanged: (v) => setState(() => _selectedType = v!)),
          ],
          const SizedBox(height: 16),
          TextFormField(controller: _addressController, maxLines: 2, decoration: const InputDecoration(labelText: 'Adresse', hintText: 'Ex: Rue 123...', prefixIcon: Icon(Icons.location_on, size: 20)), textInputAction: TextInputAction.newline),
        ])),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.3))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 18, color: isDark ? AppColors.darkWarning : AppColors.lightWarning), const SizedBox(width: 10),
          Expanded(child: Text(widget.isEditing ? 'Les modifications seront enregistrées dans l\'historique d\'audit.' : 'Un nouveau client sera créé et enregistré dans l\'historique.', style: theme.textTheme.bodySmall)),
        ])),
        if (!isDesktop) ...[const SizedBox(height: 24), SizedBox(height: 48, child: FilledButton.icon(onPressed: _isSaving ? null : _save, icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer')))],
      ])))),
    ));
  }
}
