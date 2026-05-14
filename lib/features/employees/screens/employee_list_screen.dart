import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/employee_model.dart';
import '../data/employee_repository.dart';
import '../data/advance_repository.dart';
import '../providers/employee_provider.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});
  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  bool _isLoading = true;
  List<Employee> _employees = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final data = await EmployeeRepository.getAll(
        isActive: _filter == 'all' ? null : _filter == 'active',
      );
      if (mounted) setState(() { _employees = data; _isLoading = false; });
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

  void _onAdd() => context.push('/employees/new').then((_) => _loadData());
  void _onEdit(Employee e) => context.push('/employees/new', extra: e).then((_) => _loadData());
  void _onDetail(Employee e) => context.push('/employees/${e.id}').then((_) => _loadData());

  void _showAdvanceDialog(Employee e) {
    final ctrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Avance - ${e.fullName}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant DZD')),
        const SizedBox(height: 8),
        TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Motif')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
        FilledButton(onPressed: () async {
          final a = double.tryParse(ctrl.text.replaceAll(',', '.'));
          if (a == null || a <= 0) return;
          try { await AdvanceRepository.create(employeeId: e.id, amount: a, reason: reasonCtrl.text); if (ctx.mounted) Navigator.of(ctx).pop(); _loadData(); }
          catch (ex) { _showError('Erreur: $ex'); }
        }, child: const Text('Enregistrer')),
      ],
    ));
  }

  void _confirmDelete(Employee e) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirmer'),
      content: Text('Supprimer ${e.fullName} ?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () async { try { await EmployeeRepository.delete(e.id, e.fullName); if (ctx.mounted) Navigator.of(ctx).pop(); await _loadData(); } catch (ex) { _showError('Erreur: $ex'); } },
          child: const Text('Supprimer')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final isDark = theme.brightness == Brightness.dark; final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(body: CallbackShortcuts(bindings: {if (isDesktop) const SingleActivator(LogicalKeyboardKey.keyN, control: true): _onAdd}, child: Focus(autofocus: true, child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(isDesktop ? 24 : 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Employés', style: theme.textTheme.headlineMedium), const SizedBox(height: 4),
            Text('Gestion des employés', style: theme.textTheme.bodySmall),
          ])),
          if (isDesktop) OutlinedButton.icon(onPressed: _onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Nouvel employé'))
          else IconButton.filled(onPressed: _onAdd, icon: const Icon(Icons.add), tooltip: 'Nouvel employé'),
        ]),
        const SizedBox(height: 16),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          ...['all','active','inactive'].map((k) {
            final labels = {'all':'Tous','active':'Actif','inactive':'Inactif'};
            return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(labels[k]!), selected: _filter == k, onSelected: (v) { setState(() { _filter = k; _isLoading = true; }); _loadData(); }, selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15)));
          }),
        ])),
      ]))),
      if (_isLoading) _buildShimmer(isDark, isDesktop)
      else if (_employees.isEmpty) _buildEmpty(theme)
      else if (isDesktop) _buildDesktop(theme, isDark) else _buildMobile(theme, isDark),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]))));
  }

  Widget _buildDesktop(ThemeData theme, bool isDark) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Text('${_employees.length} employé${_employees.length > 1 ? 's' : ''}', style: theme.textTheme.labelLarge)),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 16, dataRowMinHeight: 44, dataRowMaxHeight: 44, headingRowHeight: 36,
      columns: const [DataColumn(label: Text('Nom')), DataColumn(label: Text('Poste')), DataColumn(label: Text('Téléphone')), DataColumn(label: Text('Type')), DataColumn(label: Text('Salaire'), numeric: true), DataColumn(label: Text('Statut')), DataColumn(label: Text('Actions'))],
      rows: _employees.map((e) => DataRow(onSelectChanged: (_) => _onDetail(e), cells: [
        DataCell(Text(e.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(e.position ?? '-', style: theme.textTheme.bodySmall)),
        DataCell(Text(e.phone ?? '-', style: theme.textTheme.bodySmall)),
        DataCell(Text(e.salaryLabel, style: theme.textTheme.bodySmall)),
        DataCell(Text(CurrencyFormatter.format(e.baseSalary), style: GoogleFonts.jetBrainsMono(fontSize: 12))),
        DataCell(e.isActive ? _chip('Actif', isDark ? AppColors.darkSuccess : AppColors.lightSuccess, isDark) : _chip('Inactif', isDark ? AppColors.darkMuted : AppColors.lightMuted, isDark)),
        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () => _onDetail(e)),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _onEdit(e)),
          IconButton(icon: Icon(Icons.account_balance_wallet_outlined, size: 18, color: isDark ? AppColors.darkWarning : AppColors.lightWarning), tooltip: 'Avance', onPressed: () => _showAdvanceDialog(e)),
          IconButton(icon: Icon(Icons.delete_outline, size: 18, color: isDark ? AppColors.darkError : AppColors.lightError), onPressed: () => _confirmDelete(e)),
        ])),
      ])).toList(),
    )),
  ]))));

  // ignore: unused_element
  Widget _buildMobile(ThemeData theme, bool isDark) => SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
    final e = _employees[i];
    return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: InkWell(borderRadius: BorderRadius.circular(8), onTap: () => _onDetail(e), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person, size: 20, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e.fullName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        Text(e.position ?? e.salaryLabel, style: theme.textTheme.labelSmall),
      ])),
      PopupMenuButton<String>(icon: const Icon(Icons.more_vert, size: 20), itemBuilder: (_) => [
        const PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('Détails')])),
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Modifier')])),
        const PopupMenuItem(value: 'advance', child: Row(children: [Icon(Icons.account_balance_wallet_outlined, size: 18), SizedBox(width: 8), Text('Avance')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
      ], onSelected: (v) { if (v == 'detail') _onDetail(e); else if (v == 'edit') _onEdit(e); else if (v == 'advance') _showAdvanceDialog(e); else if (v == 'delete') _confirmDelete(e); }),
    ]))));
  }, childCount: _employees.length)));

  Widget _chip(String label, Color color, bool isDark) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)));

  Widget _buildEmpty(ThemeData theme) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 48), child: Center(child: Column(children: [Icon(Icons.people_outline, size: 48, color: theme.textTheme.bodySmall?.color), const SizedBox(height: 12), Text('Aucun employé', style: theme.textTheme.titleMedium), const SizedBox(height: 16), OutlinedButton.icon(onPressed: _onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Nouvel employé'))]))));

  Widget _buildShimmer(bool isDark, bool isDesktop) => SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8), highlightColor: isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA), child: Padding(padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16), child: Column(children: List.generate(5, (i) => Container(margin: const EdgeInsets.only(bottom: 8), height: 56, decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : AppColors.lightSurface, borderRadius: BorderRadius.circular(8))))))));
}
