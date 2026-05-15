import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../data/expense_model.dart';
import '../data/expense_repository.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;
  const ExpenseFormScreen({super.key, this.expense});
  bool get isEditing => expense != null;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Autre';
  String? _selectedWarehouseId;
  DateTime _expenseDate = DateTime.now();
  List<Map<String, dynamic>> _warehouses = [];
  bool _isSaving = false;

  static const _categories = [
    'Électricité','Eau','Transport','Maintenance','Loyer','Fournitures','Salaires','Autre'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWarehouses());
    if (widget.expense != null) {
      final e = widget.expense!;
      _category = e.category;
      _amountController.text = e.amount.toString();
      _descriptionController.text = e.description ?? '';
      _selectedWarehouseId = e.warehouseId;
      _expenseDate = e.expenseDate;
    }
  }

  Future<void> _loadWarehouses() async {
    final d = await SupabaseService.client.from('warehouses').select('id, name').eq('is_active', true).order('name');
    if (mounted) setState(() => _warehouses = List<Map<String, dynamic>>.from(d as List));
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(context: context, initialDate: _expenseDate, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (p != null) setState(() => _expenseDate = p);
  }

  @override
  void dispose() { _amountController.dispose(); _descriptionController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (widget.isEditing) {
        await ExpenseRepository.update(id: widget.expense!.id, warehouseId: _selectedWarehouseId, category: _category, amount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0, description: _descriptionController.text, expenseDate: _expenseDate);
      } else {
        await ExpenseRepository.create(warehouseId: _selectedWarehouseId, category: _category, amount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0, description: _descriptionController.text, expenseDate: _expenseDate);
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isEditing ? 'Dépense modifiée' : 'Dépense créée'), behavior: SnackBarBehavior.floating)); context.pop(); }
    } catch (e) {
      if (mounted) { setState(() => _isSaving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), behavior: SnackBarBehavior.floating)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Modifier dépense' : 'Nouvelle dépense'),
        actions: [TextButton.icon(onPressed: _isSaving ? null : _save, icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined, size: 18), label: const Text('Enregistrer')), const SizedBox(width: 8)]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Informations', style: theme.textTheme.titleMedium), const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'Catégorie *'), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _category = v!), validator: (v) => v == null ? 'Requis' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant *', prefixText: 'DZD '), validator: (v) { if (v == null || v.isEmpty) return 'Requis'; if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Invalide'; return null; }),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _selectedWarehouseId, decoration: const InputDecoration(labelText: 'Dépôt'), items: _warehouses.map((w) => DropdownMenuItem(value: w['id'] as String, child: Text(w['name'] as String))).toList(), onChanged: (v) => setState(() => _selectedWarehouseId = v)),
          const SizedBox(height: 16),
          InkWell(onTap: _pickDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Date'), child: Text('${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}', style: theme.textTheme.bodyMedium))),
          const SizedBox(height: 16),
          TextFormField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
        ])),
        const SizedBox(height: 24),
        SizedBox(height: 48, child: FilledButton.icon(onPressed: _isSaving ? null : _save, icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'))),
      ]))))));
  }
}
