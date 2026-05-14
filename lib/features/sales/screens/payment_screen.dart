import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/invoice_model.dart';
import '../data/invoice_repository.dart';

class PaymentScreen extends StatefulWidget {
  final Invoice invoice;
  const PaymentScreen({super.key, required this.invoice});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMethod = 'cash';
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.invoice.remainingDebt.toString();
  }

  @override
  void dispose() {
    _amountController.dispose(); _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _paymentDate, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await InvoiceRepository.recordPayment(
        invoiceId: widget.invoice.id,
        clientId: widget.invoice.clientId,
        amount: double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0,
        method: _selectedMethod,
        notes: _notesController.text,
      );
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement enregistré'), behavior: SnackBarBehavior.floating)); context.pop(); }
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
      appBar: AppBar(title: const Text('Enregistrer un paiement')),
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
                        Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.payment, size: 18,
                                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
                          ),
                          const SizedBox(width: 12),
                          Text('Paiement', style: theme.textTheme.titleMedium),
                        ]),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(children: [
                            _infoRow(theme, 'Client', widget.invoice.clientName ?? 'Au comptoir'),
                            const SizedBox(height: 4),
                            _infoRow(theme, 'Facture', widget.invoice.invoiceNumber),
                            const SizedBox(height: 4),
                            _infoRow(theme, 'Montant restant', CurrencyFormatter.format(widget.invoice.remainingDebt)),
                          ]),
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
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Le montant est obligatoire';
                            final a = double.tryParse(v.replaceAll(',', '.'));
                            if (a == null || a <= 0) return 'Montant invalide';
                            if (a > widget.invoice.remainingDebt) {
                              return 'Ne peut pas dépasser ${CurrencyFormatter.format(widget.invoice.remainingDebt)}';
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
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                            DropdownMenuItem(value: 'bank', child: Text('Virement bancaire')),
                            DropdownMenuItem(value: 'cheque', child: Text('Chèque')),
                          ],
                          onChanged: (v) => setState(() => _selectedMethod = v!),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de paiement',
                              prefixIcon: Icon(Icons.calendar_today, size: 20),
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
                      label: Text(_isSaving ? 'Traitement...' : 'Confirmer'),
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

  Widget _infoRow(ThemeData theme, String label, String value) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: theme.textTheme.labelSmall), Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600))]);
}
