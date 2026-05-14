import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/employee_repository.dart';
import '../data/advance_repository.dart';
import '../data/advance_model.dart';
import '../data/salary_repository.dart';
import '../data/salary_sheet_model.dart';
import '../data/employee_model.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final String employeeId;
  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  Employee? _employee;
  List<Advance> _advances = [];
  List<SalarySheet> _salaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        EmployeeRepository.getById(widget.employeeId),
        AdvanceRepository.getByEmployee(widget.employeeId),
        SalaryRepository.getByEmployee(widget.employeeId),
      ]);
      if (mounted) setState(() {
        _employee = results[0] as Employee?;
        _advances = results[1] as List<Advance>;
        _salaries = results[2] as List<SalarySheet>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); _showError('Erreur: $e'); }
    }
  }

  void _showError(String m) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18), const SizedBox(width: 8), Expanded(child: Text(m))]), behavior: SnackBarBehavior.floating));
    });
  }

  void _showAdvanceDialog() {
    final ctrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Avance - ${_employee?.fullName ?? ''}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant DZD')),
        const SizedBox(height: 8),
        TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Motif')),
      ]),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Annuler')),
        FilledButton(onPressed: () async {
          final a = double.tryParse(ctrl.text.replaceAll(',', '.'));
          if (a == null || a <= 0) return;
          try {
            await AdvanceRepository.create(employeeId: widget.employeeId, amount: a, reason: reasonCtrl.text);
            if (ctx.mounted) context.pop();
            _loadData();
          } catch (ex) { _showError('Erreur: $ex'); }
        }, child: const Text('Enregistrer')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_employee?.fullName ?? 'Employé'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/employees/new', extra: _employee).then((_) => _loadData())),
        ],
      ),
      body: _isLoading ? _buildShimmer(isDark) : _buildContent(theme, isDark),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    final e = _employee;
    if (e == null) return const Center(child: Text('Employé introuvable'));

    final stats = [
      _statCard(theme, isDark, 'Mois en cours', '${DateTime.now().month}/${DateTime.now().year}', isDark ? AppColors.darkInfo : AppColors.lightInfo),
      _statCard(theme, isDark, 'Avances', _advances.where((a) => !a.isDeducted).length.toString(), isDark ? AppColors.darkWarning : AppColors.lightWarning),
      _statCard(theme, isDark, 'Dernier salaire', _salaries.isNotEmpty ? CurrencyFormatter.format(_salaries.first.netSalary) : '-', isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildEmployeeCard(theme, isDark, e),
        const SizedBox(height: 16),
        Row(children: stats),
        const SizedBox(height: 24),
        _sectionHeader('Avances', _advances.length),
        const SizedBox(height: 8),
        _buildAdvancesList(theme, isDark),
        const SizedBox(height: 24),
        _sectionHeader('Historique des salaires', _salaries.length),
        const SizedBox(height: 8),
        _buildSalariesList(theme, isDark),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAdvanceDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvelle avance'),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildEmployeeCard(ThemeData theme, bool isDark, Employee e) {
    final saleLabel = e.salaryType == 'monthly'
        ? '${CurrencyFormatter.format(e.baseSalary)}/mois'
        : '${CurrencyFormatter.format(e.dailyRate)}/jour';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.person, size: 22, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.fullName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (e.position != null) Text(e.position!, style: theme.textTheme.bodySmall),
          ])),
        ]),
        const Divider(height: 24),
        _infoRow(theme, 'Type de salaire', e.salaryLabel),
        const SizedBox(height: 6),
        _infoRow(theme, 'Salaire', saleLabel),
        if (e.hireDate != null) ...[
          const SizedBox(height: 6),
          _infoRow(theme, 'Date d\'embauche', '${e.hireDate!.day.toString().padLeft(2, '0')}/${e.hireDate!.month.toString().padLeft(2, '0')}/${e.hireDate!.year}'),
        ],
        if (e.phone != null) ...[
          const SizedBox(height: 6),
          _infoRow(theme, 'Téléphone', e.phone!),
        ],
      ]),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: theme.textTheme.bodySmall),
      Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _statCard(ThemeData theme, bool isDark, String label, String value, Color color) {
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.textTheme.bodySmall?.color), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _sectionHeader(String title, int count) {
    return Row(children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: Text('$count', style: Theme.of(context).textTheme.labelSmall)),
    ]);
  }

  Widget _buildAdvancesList(ThemeData theme, bool isDark) {
    if (_advances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)),
        child: Center(child: Text('Aucune avance', style: theme.textTheme.bodySmall)),
      );
    }
    return Column(children: _advances.map((a) => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(CurrencyFormatter.format(a.amount), style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w700)),
          if (a.reason != null && a.reason!.isNotEmpty) Text(a.reason!, style: theme.textTheme.labelSmall),
          Text(a.formattedDate, style: theme.textTheme.labelSmall),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: (a.isDeducted ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess) : (isDark ? AppColors.darkWarning : AppColors.lightWarning)).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(a.isDeducted ? 'Déduite' : 'En attente', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: a.isDeducted ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess) : (isDark ? AppColors.darkWarning : AppColors.lightWarning)))),
      ]),
    )).toList());
  }

  Widget _buildSalariesList(ThemeData theme, bool isDark) {
    if (_salaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)),
        child: Center(child: Text('Aucun salaire', style: theme.textTheme.bodySmall)),
      );
    }
    return Column(children: _salaries.map((s) => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.monthLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('Net: ${CurrencyFormatter.format(s.netSalary)}', style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _statusColor(s.status, isDark).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(s.statusLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(s.status, isDark)))),
      ]),
    )).toList());
  }

  Color _statusColor(String status, bool isDark) {
    switch (status) {
      case 'paid': return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      case 'validated': return isDark ? AppColors.darkInfo : AppColors.lightInfo;
      default: return isDark ? AppColors.darkMuted : AppColors.lightMuted;
    }
  }

  Widget _buildShimmer(bool isDark) {
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
        highlightColor: isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: List.generate(5, (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : AppColors.lightSurface, borderRadius: BorderRadius.circular(8)),
          ))),
        ),
      )),
    ]);
  }
}
