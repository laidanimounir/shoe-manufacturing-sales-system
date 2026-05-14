import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../data/employee_model.dart';
import '../data/employee_repository.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;
  const EmployeeFormScreen({super.key, this.employee});
  bool get isEditing => employee != null;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  static const int _workingDays = 26;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  String? _selectedWarehouseId;
  String _salaryType = 'monthly';
  final _baseController = TextEditingController();
  final _dailyController = TextEditingController();
  DateTime? _hireDate;
  List<Map<String, dynamic>> _warehouses = [];
  bool _isSaving = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWarehouses());
    if (widget.employee != null) {
      final e = widget.employee!;
      _nameController.text = e.fullName;
      _positionController.text = e.position ?? '';
      _selectedWarehouseId = e.warehouseId;
      _salaryType = e.salaryType;
      _baseController.text = e.baseSalary.toStringAsFixed(0);
      _dailyController.text = e.dailyRate.toStringAsFixed(2);
      _hireDate = e.hireDate;
    }
    _baseController.addListener(_onBaseSalaryChanged);
    _dailyController.addListener(_onDailyRateChanged);
  }

  void _onBaseSalaryChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final base = double.tryParse(_baseController.text.replaceAll(',', '.')) ?? 0;
    _dailyController.text = (base / _workingDays).toStringAsFixed(2);
    _isUpdating = false;
  }

  void _onDailyRateChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final daily = double.tryParse(_dailyController.text.replaceAll(',', '.')) ?? 0;
    _baseController.text = (daily * _workingDays).toStringAsFixed(0);
    _isUpdating = false;
  }

  Future<void> _loadWarehouses() async {
    final d = await SupabaseService.client.from('warehouses').select('id, name').eq('is_active', true).order('name');
    if (mounted) setState(() => _warehouses = List<Map<String, dynamic>>.from(d as List));
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(context: context, initialDate: _hireDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
    if (p != null) setState(() => _hireDate = p);
  }

  @override
  void dispose() {
    _nameController.dispose(); _positionController.dispose(); _baseController.dispose(); _dailyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (widget.isEditing) {
        await EmployeeRepository.update(
          id: widget.employee!.id, position: _positionController.text,
          salaryType: _salaryType, baseSalary: double.tryParse(_baseController.text.replaceAll(',', '.')) ?? 0,
          dailyRate: double.tryParse(_dailyController.text.replaceAll(',', '.')) ?? 0,
          hireDate: _hireDate,
        );
      } else {
        await EmployeeRepository.create(
          fullName: _nameController.text, position: _positionController.text,
          warehouseId: _selectedWarehouseId, salaryType: _salaryType,
          baseSalary: double.tryParse(_baseController.text.replaceAll(',', '.')) ?? 0,
          dailyRate: double.tryParse(_dailyController.text.replaceAll(',', '.')) ?? 0,
          hireDate: _hireDate,
        );
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isEditing ? 'Employé modifié' : 'Employé créé'), behavior: SnackBarBehavior.floating)); context.pop(); }
    } catch (e) {
      if (mounted) { setState(() => _isSaving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18), const SizedBox(width: 8), Expanded(child: Text('Erreur: $e'))]), behavior: SnackBarBehavior.floating)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Modifier employé' : 'Nouvel employé'),
        actions: [TextButton.icon(onPressed: _isSaving ? null : _save, icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined, size: 18), label: const Text('Enregistrer')), const SizedBox(width: 8)]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person, size: 18, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)), const SizedBox(width: 12), Text('Informations', style: theme.textTheme.titleMedium)]),
          const SizedBox(height: 20),
          if (!widget.isEditing) TextFormField(controller: _nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Nom complet *', prefixIcon: Icon(Icons.badge, size: 20)), validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null, textInputAction: TextInputAction.next),
          if (!widget.isEditing) const SizedBox(height: 16),
          TextFormField(controller: _positionController, decoration: const InputDecoration(labelText: 'Poste', hintText: 'Ex: Tailleur, Ouvrier...', prefixIcon: Icon(Icons.work, size: 20)), textInputAction: TextInputAction.next),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _selectedWarehouseId, decoration: const InputDecoration(labelText: 'Dépôt', prefixIcon: Icon(Icons.warehouse, size: 20)), items: _warehouses.map((w) => DropdownMenuItem(value: w['id'] as String, child: Text(w['name'] as String))).toList(), onChanged: (v) => setState(() => _selectedWarehouseId = v)),
          const SizedBox(height: 16),
          InkWell(onTap: _pickDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Date d\'embauche', prefixIcon: Icon(Icons.calendar_today, size: 20)), child: Text(_hireDate != null ? '${_hireDate!.day}/${_hireDate!.month}/${_hireDate!.year}' : 'Sélectionner', style: theme.textTheme.bodyMedium))),
        ])),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.attach_money, size: 18, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess)), const SizedBox(width: 12), Text('Salaire', style: theme.textTheme.titleMedium)]),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'monthly', label: Text('Mensuel')), ButtonSegment(value: 'daily', label: Text('Journalier'))],
            selected: {_salaryType}, onSelectionChanged: (v) => setState(() => _salaryType = v.first),
          ),
          const SizedBox(height: 16),
          if (_salaryType == 'monthly') ...[
            TextFormField(controller: _baseController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Salaire mensuel (DZD)', prefixIcon: Icon(Icons.attach_money, size: 20))),
            const SizedBox(height: 12),
            TextFormField(controller: _dailyController, readOnly: true, decoration: InputDecoration(labelText: 'Taux journalier (calculé)', prefixIcon: Icon(Icons.attach_money, size: 20), fillColor: theme.disabledColor.withValues(alpha: 0.05), filled: true)),
          ],
          if (_salaryType == 'daily') ...[
            TextFormField(controller: _dailyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Taux journalier (DZD)', prefixIcon: Icon(Icons.attach_money, size: 20))),
            const SizedBox(height: 12),
            TextFormField(controller: _baseController, readOnly: true, decoration: InputDecoration(labelText: 'Salaire mensuel estimé', prefixIcon: Icon(Icons.attach_money, size: 20), fillColor: theme.disabledColor.withValues(alpha: 0.05), filled: true)),
          ],
        ])),
        const SizedBox(height: 24),
        SizedBox(height: 48, child: FilledButton.icon(onPressed: _isSaving ? null : _save, icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'))),
      ],
    ),
  ),
),
),
));
}
}
