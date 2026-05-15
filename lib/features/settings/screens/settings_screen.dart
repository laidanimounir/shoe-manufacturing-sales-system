import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/supabase_service.dart';
import '../data/company_settings_model.dart';
import '../data/settings_repository.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  String _ticketFormat = '80mm';
  bool _saving = false;
  bool _logoUploading = false;
  String? _logoUrl;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  void _fillForm(CompanySettings s) {
    _nameCtrl.text = s.name;
    _addrCtrl.text = s.address ?? '';
    _phoneCtrl.text = s.phone ?? '';
    _emailCtrl.text = s.email ?? '';
    _footerCtrl.text = s.ticketFooter;
    _ticketFormat = s.ticketFormat;
    _logoUrl = s.logoUrl;
  }

  Future<void> _saveCompany() async {
    final settings = ref.read(companySettingsProvider).value;
    if (settings == null) return;

    setState(() => _saving = true);
    try {
      await SettingsRepository.updateCompanySettings(
        settings.copyWith(
          name: _nameCtrl.text.trim(),
          address: _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        ),
      );
      ref.invalidate(companySettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres enregistrés')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveTicket() async {
    final settings = ref.read(companySettingsProvider).value;
    if (settings == null) return;

    setState(() => _saving = true);
    try {
      await SettingsRepository.updateCompanySettings(
        settings.copyWith(
          ticketFooter: _footerCtrl.text.trim(),
          ticketFormat: _ticketFormat,
        ),
      );
      ref.invalidate(companySettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres ticket enregistrés')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    setState(() => _logoUploading = true);
    try {
      final url = await SettingsRepository.uploadLogo(File(picked.path));
      if (url != null) {
        final settings = ref.read(companySettingsProvider).value;
        if (settings != null) {
          await SettingsRepository.updateCompanySettings(
            settings.copyWith(logoUrl: url),
          );
        }
        setState(() => _logoUrl = url);
        ref.invalidate(companySettingsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload logo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _logoUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(companySettingsProvider);
    final local = ref.watch(localSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (settings) {
          if (_nameCtrl.text.isEmpty) _fillForm(settings);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader('Entreprise', Icons.business, theme),
              const SizedBox(height: 12),
              _logoSection(theme),
              const SizedBox(height: 16),
              _buildField('Nom de lentreprise', _nameCtrl),
              const SizedBox(height: 12),
              _buildField('Adresse', _addrCtrl, maxLines: 2),
              const SizedBox(height: 12),
              _buildField('Téléphone', _phoneCtrl),
              const SizedBox(height: 12),
              _buildField('Email', _emailCtrl),
              const SizedBox(height: 16),
              _saveButton('Enregistrer entreprise', _saveCompany),
              const SizedBox(height: 32),

              _sectionHeader('Impression', Icons.print, theme),
              const SizedBox(height: 12),
              Text('Format ticket', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '58mm', label: Text('58mm')),
                  ButtonSegment(value: '80mm', label: Text('80mm')),
                ],
                selected: {_ticketFormat},
                onSelectionChanged: (v) => setState(() => _ticketFormat = v.first),
              ),
              const SizedBox(height: 12),
              _buildField('Pied de page ticket', _footerCtrl, maxLines: 2),
              const SizedBox(height: 16),
              _saveButton('Enregistrer ticket', _saveTicket),
              const SizedBox(height: 32),

              _sectionHeader('Langue', Icons.language, theme),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'fr', label: Text('Français')),
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                ],
                selected: {local['locale'] ?? 'fr'},
                onSelectionChanged: (v) {
                  ref.read(localSettingsProvider.notifier).setLocale(v.first);
                },
              ),
              const SizedBox(height: 32),

              _sectionHeader('Thème', Icons.palette, theme),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'dark', label: Text('Sombre')),
                  ButtonSegment(value: 'light', label: Text('Clair')),
                  ButtonSegment(value: 'system', label: Text('Système')),
                ],
                selected: {local['themeMode'] ?? 'system'},
                onSelectionChanged: (v) {
                  ref.read(localSettingsProvider.notifier).setThemeMode(v.first);
                },
              ),
              const SizedBox(height: 32),

              _sectionHeader('Mon compte', Icons.person, theme),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Mounir'),
                subtitle: Text(SupabaseService.currentUser?.email ?? ''),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Déconnexion'),
                        content: const Text('Voulez-vous vous déconnecter ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Déconnexion',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await SupabaseService.signOut();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Déconnexion',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        )),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _saveButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : onPressed,
        icon: _saving
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.save, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _logoSection(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage:
              _logoUrl != null ? NetworkImage(_logoUrl!) : null,
          child: _logoUrl == null
              ? Icon(Icons.storefront, size: 32, color: theme.colorScheme.primary)
              : null,
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _logoUploading ? null : _pickAndUploadLogo,
          icon: _logoUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.camera_alt, size: 18),
          label: Text(_logoUploading ? 'Upload...' : 'Changer le logo'),
        ),
      ],
    );
  }
}
