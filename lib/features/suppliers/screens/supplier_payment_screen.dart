import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/purchase_order_model.dart';
import '../data/purchase_order_repository.dart';

class SupplierPaymentScreen extends StatefulWidget {
  final PurchaseOrder order;
  const SupplierPaymentScreen({super.key, required this.order});

  @override
  State<SupplierPaymentScreen> createState() => _SupplierPaymentScreenState();
}

class _SupplierPaymentScreenState extends State<SupplierPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMethod = 'cash';
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;

  static const _methods = [
    {'value': 'cash', 'label': 'Espèces'},
    {'value': 'bank_transfer', 'label': 'Virement bancaire'},
    {'value': 'cheque', 'label': 'Chèque'},
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.order.debtAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await PurchaseOrderRepository.recordPayment(
        orderId: widget.order.id,
        supplierId: widget.order.supplierId,
        amount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0,
        paymentMethod: _selectedMethod,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement enregistré avec succès'),
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
        title: const Text('Enregistrer un paiement'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
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
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _infoRow(theme, 'Fournisseur', widget.order.supplierName ?? '-'),
                              const SizedBox(height: 4),
                              _infoRow(theme, 'Montant restant',
                                  CurrencyFormatter.format(widget.order.debtAmount)),
                              const SizedBox(height: 4),
                              _infoRow(theme, 'Total commande',
                                  CurrencyFormatter.format(widget.order.totalAmount)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Montant *',
                            prefixIcon: const Icon(Icons.attach_money, size: 20),
                            prefixText: 'DZD ',
                            suffixText: CurrencyFormatter.format(widget.order.debtAmount),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Le montant est obligatoire';
                            final amount = double.tryParse(v.replaceAll(',', '.'));
                            if (amount == null || amount <= 0) return 'Montant invalide';
                            if (amount > widget.order.debtAmount) {
                              return 'Ne peut pas dépasser la dette (${CurrencyFormatter.format(widget.order.debtAmount)})';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMethod,
                          decoration: const InputDecoration(
                            labelText: 'Mode de paiement *',
                            prefixIcon: Icon(Icons.account_balance, size: 20),
                          ),
                          items: _methods.map((m) => DropdownMenuItem(
                            value: m['value'] as String,
                            child: Text(m['label'] as String),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedMethod = v!),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date de paiement',
                              prefixIcon: const Icon(Icons.calendar_today, size: 20),
                              suffixIcon: Icon(Icons.arrow_drop_down,
                                  color: theme.colorScheme.primary),
                            ),
                            child: Text(
                              '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            hintText: 'Référence, remarques...',
                            prefixIcon: Icon(Icons.notes, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                          _isSaving ? 'Traitement...' : 'Confirmer le paiement'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
