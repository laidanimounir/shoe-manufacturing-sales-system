import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/salary_sheet_model.dart';
import '../data/salary_repository.dart';

class SalaryDetailScreen extends StatefulWidget {
  final String sheetId;
  const SalaryDetailScreen({super.key, required this.sheetId});

  @override
  State<SalaryDetailScreen> createState() => _SalaryDetailScreenState();
}

class _SalaryDetailScreenState extends State<SalaryDetailScreen> {
  SalarySheet? _sheet;
  bool _loading = true;
  bool _saving = false;

  late TextEditingController _bonusController;
  late TextEditingController _deductionsController;

  @override
  void initState() {
    super.initState();
    _bonusController = TextEditingController();
    _deductionsController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _bonusController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.client
          .from('salary_sheets')
          .select('*, employees!inner(profiles(full_name))')
          .eq('id', widget.sheetId)
          .single();
      final sheet = SalarySheet.fromMap(data);
      _bonusController.text = sheet.bonus.toStringAsFixed(2);
      _deductionsController.text = sheet.deductions.toStringAsFixed(2);
      if (mounted) setState(() { _sheet = sheet; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'), behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _updateField(String field, double value) async {
    setState(() => _saving = true);
    try {
      final client = SupabaseService.client;
      final updated = await client
          .from('salary_sheets')
          .update({field: value})
          .eq('id', widget.sheetId)
          .select('*, employees!inner(profiles(full_name))')
          .single();
      final sheet = SalarySheet.fromMap(updated);
      _bonusController.text = sheet.bonus.toStringAsFixed(2);
      _deductionsController.text = sheet.deductions.toStringAsFixed(2);
      if (mounted) setState(() { _sheet = sheet; _saving = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'), behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _saveBonus() async {
    final v = double.tryParse(_bonusController.text.replaceAll(',', '.'));
    if (v == null) return;
    await _updateField('bonus', v);
  }

  Future<void> _saveDeductions() async {
    final v = double.tryParse(_deductionsController.text.replaceAll(',', '.'));
    if (v == null) return;
    await _updateField('deductions', v);
  }

  Future<void> _markPaid() async {
    setState(() => _saving = true);
    try {
      await SalaryRepository.markPaid(widget.sheetId);
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'), behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheet = _sheet;

    return Scaffold(
      appBar: AppBar(title: Text(sheet?.monthLabel ?? 'Fiche de paie')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : sheet == null
              ? const Center(child: Text('Fiche introuvable'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildEmployeeInfo(sheet, theme, isDark),
                          const SizedBox(height: 16),
                          _buildBreakdownCard(sheet, theme, isDark),
                          const SizedBox(height: 24),
                          if (sheet.status == 'draft')
                            _buildDraftActions(theme, isDark),
                          if (sheet.status == 'validated')
                            _buildValidateAction(theme, isDark),
                          if (sheet.status == 'paid')
                            _buildPaidChip(sheet, theme, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmployeeInfo(SalarySheet sheet, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.person, size: 20, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sheet.employeeName ?? 'Employé', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(sheet.monthLabel, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: sheet.status == 'paid'
                ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.12)
                : sheet.status == 'validated'
                    ? (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.12)
                    : (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(sheet.statusLabel,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: sheet.status == 'paid'
                  ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                  : sheet.status == 'validated'
                      ? (isDark ? AppColors.darkInfo : AppColors.lightInfo)
                      : (isDark ? AppColors.darkWarning : AppColors.lightWarning),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildBreakdownCard(SalarySheet sheet, ThemeData theme, bool isDark) {
    final workingDays = 26;

    Widget _row(String label, String value, {Color? valueColor, Widget? trailing}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            )),
          ],
        ),
      );
    }

    Widget _divider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    );

    bool isDraft = sheet.status == 'draft';

    return Container(
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
              child: Icon(Icons.receipt_long, size: 18, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
            ),
            const SizedBox(width: 12),
            Text('Détail du salaire', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 20),
          _row('Jours travaillés', '${sheet.workedDays} / $workingDays'),
          const SizedBox(height: 4),
          _row('Salaire de base', CurrencyFormatter.format(sheet.baseSalary)),
          const SizedBox(height: 4),
          _row('Primes', '+ ${CurrencyFormatter.format(sheet.bonus)}',
            valueColor: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
            trailing: isDraft ? _editButton(theme, isDark, _bonusController, _saveBonus) : null,
          ),
          const SizedBox(height: 4),
          _row('Déductions', '- ${CurrencyFormatter.format(sheet.deductions)}',
            valueColor: (isDark ? AppColors.darkError : AppColors.lightError),
            trailing: isDraft ? _editButton(theme, isDark, _deductionsController, _saveDeductions) : null,
          ),
          const SizedBox(height: 4),
          _row('Avances', '- ${CurrencyFormatter.format(sheet.totalAdvances)}',
            valueColor: (isDark ? AppColors.darkError : AppColors.lightError),
          ),
          _divider(),
          _row('Net à payer', CurrencyFormatter.format(sheet.netSalary),
            valueColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
        ],
      ),
    );
  }

  Widget _editButton(ThemeData theme, bool isDark, TextEditingController controller, VoidCallback onSave) {
    return InkWell(
      onTap: () => _showEditDialog(theme, isDark, controller, onSave),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.edit_outlined, size: 16, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
      ),
    );
  }

  void _showEditDialog(ThemeData theme, bool isDark, TextEditingController controller, VoidCallback onSave) {
    final localController = TextEditingController(text: controller.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier'),
        content: TextField(
          controller: localController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Montant', prefixText: 'DZD '),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              controller.text = localController.text;
              context.pop();
              onSave();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ).then((_) => localController.dispose());
  }

  Widget _buildDraftActions(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: _saving ? null : () async {
          setState(() => _saving = true);
          try {
            await SalaryRepository.validate(widget.sheetId);
            await _load();
          } catch (e) {
            if (mounted) {
              setState(() => _saving = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Erreur: $e'), behavior: SnackBarBehavior.floating,
              ));
            }
          }
        },
        icon: _saving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.check_circle_outline),
        label: const Text('Valider la fiche'),
      ),
    );
  }

  Widget _buildValidateAction(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: _saving ? null : _markPaid,
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
        ),
        icon: _saving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.monetization_on_outlined),
        label: const Text('Payer'),
      ),
    );
  }

  Widget _buildPaidChip(SalarySheet sheet, ThemeData theme, bool isDark) {
    final paidDate = sheet.paidAt != null
        ? '${sheet.paidAt!.day}/${sheet.paidAt!.month}/${sheet.paidAt!.year}'
        : '';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 20, color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
            const SizedBox(width: 8),
            Text('Payé ✓',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
              ),
            ),
            if (paidDate.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text('le $paidDate',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
