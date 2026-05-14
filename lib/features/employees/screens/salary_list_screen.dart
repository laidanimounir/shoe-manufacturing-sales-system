import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/salary_repository.dart';
import '../data/salary_sheet_model.dart';

class SalaryListScreen extends ConsumerStatefulWidget {
  const SalaryListScreen({super.key});
  @override
  ConsumerState<SalaryListScreen> createState() => _SalaryListScreenState();
}

class _SalaryListScreenState extends ConsumerState<SalaryListScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<SalarySheet> _sheets = [];
  Map<String, dynamic>? _report;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  late TabController _tabController;

  final _years = List.generate(5, (i) => DateTime.now().year - 2 + i);
  final _monthLabels = [
    '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadData();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_tabController.index == 0) {
        _sheets = await SalaryRepository.getAll(year: _year, month: _month);
      } else {
        _report = await SalaryRepository.getMonthlyReport(_year, _month);
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur: $e');
      }
    }
  }

  void _showError(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(m)),
        ],
      ),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccess(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(m)),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.darkSuccess,
    ));
  }

  Future<void> _generate() async {
    try {
      await SalaryRepository.generateForMonth(_year, _month);
      _showSuccess('Fiches de paie générées');
      _loadData();
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  Future<void> _validate(String sheetId) async {
    try {
      await SalaryRepository.validate(sheetId);
      _showSuccess('Fiche validée');
      _loadData();
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  Future<void> _pay(String sheetId) async {
    try {
      await SalaryRepository.markPaid(sheetId);
      _showSuccess('Paiement effectué');
      _loadData();
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  Color _statusColor(String status, bool isDark) {
    switch (status) {
      case 'draft':
        return isDark ? AppColors.darkWarning : AppColors.lightWarning;
      case 'validated':
        return isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
      case 'paid':
        return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      default:
        return isDark ? AppColors.darkMuted : AppColors.lightMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(theme, isDark),
          Material(
            color: theme.scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Fiches de paie'),
                Tab(text: 'Rapport mensuel'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoading
                    ? _buildShimmer(isDark)
                    : _sheets.isEmpty
                        ? _buildEmpty(theme, 'Aucune fiche de paie')
                        : _buildSheetsList(theme, isDark),
                _isLoading
                    ? _buildShimmer(isDark)
                    : _report == null
                        ? _buildEmpty(theme, 'Aucun rapport')
                        : _buildReport(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Salaires', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Gestion des salaires', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDropdown(
                value: _year,
                items: _years,
                label: 'Année',
                onChanged: (v) {
                  setState(() => _year = v);
                  _loadData();
                },
                isDark: isDark,
                width: 100,
              ),
              const SizedBox(width: 12),
              _buildDropdown(
                value: _month,
                items: List.generate(12, (i) => i + 1),
                label: 'Mois',
                itemLabel: (v) => _monthLabels[v],
                onChanged: (v) {
                  setState(() => _month = v);
                  _loadData();
                },
                isDark: isDark,
                width: 160,
              ),
              const Spacer(),
              if (_tabController.index == 0)
                FilledButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Générer les fiches'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String label,
    required ValueChanged<T> onChanged,
    required bool isDark,
    double width = 120,
    String Function(T)? itemLabel,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: items
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(
                      itemLabel != null ? itemLabel(v) : v.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: (T? v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }

  Widget _buildSheetsList(ThemeData theme, bool isDark) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 44,
              headingRowHeight: 36,
              columns: const [
                DataColumn(label: Text('Employé')),
                DataColumn(label: Text('Jours'), numeric: true),
                DataColumn(label: Text('Base'), numeric: true),
                DataColumn(label: Text('Primes'), numeric: true),
                DataColumn(label: Text('Avances'), numeric: true),
                DataColumn(label: Text('Net'), numeric: true),
                DataColumn(label: Text('Statut')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _sheets.map((s) {
                final totalDays = s.workedDays + s.absentDays;
                return DataRow(cells: [
                  DataCell(Text(s.employeeName ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text('${s.workedDays}/$totalDays',
                      style: theme.textTheme.bodySmall)),
                  DataCell(Text(CurrencyFormatter.format(s.baseSalary),
                      style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                  DataCell(Text(CurrencyFormatter.format(s.bonus),
                      style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                  DataCell(Text(CurrencyFormatter.format(s.totalAdvances),
                      style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                  DataCell(Text(CurrencyFormatter.format(s.netSalary),
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 12, fontWeight: FontWeight.w600))),
                  DataCell(
                      _statusChip(s.statusLabel, _statusColor(s.status, isDark), isDark)),
                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                    if (s.status == 'draft')
                      IconButton(
                        icon: Icon(Icons.check_circle_outline,
                            size: 18,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary),
                        tooltip: 'Valider',
                        onPressed: () => _validate(s.id),
                      ),
                    if (s.status == 'validated')
                      IconButton(
                        icon: Icon(Icons.account_balance_wallet_outlined,
                            size: 18,
                            color: isDark
                                ? AppColors.darkSuccess
                                : AppColors.lightSuccess),
                        tooltip: 'Payer',
                        onPressed: () => _pay(s.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'Détails',
                      onPressed: () =>
                          context.push('/salaries/${s.id}').then((_) => _loadData()),
                    ),
                  ])),
                ]);
              }).toList(),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _sheets.length,
      itemBuilder: (ctx, i) {
        final s = _sheets[i];
        final totalDays = s.workedDays + s.absentDays;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                context.push('/salaries/${s.id}').then((_) => _loadData()),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.employeeName ?? '-',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      _statusChip(
                          s.statusLabel, _statusColor(s.status, isDark), isDark),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Net: ${CurrencyFormatter.format(s.netSalary)}',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jours: $totalDays  |  Base: ${CurrencyFormatter.formatNumber(s.baseSalary)}',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (s.status == 'draft')
                        TextButton.icon(
                          icon: Icon(Icons.check_circle_outline,
                              size: 16,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary),
                          label: Text('Valider',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary)),
                          onPressed: () => _validate(s.id),
                        ),
                      if (s.status == 'validated')
                        TextButton.icon(
                          icon: Icon(Icons.account_balance_wallet_outlined,
                              size: 16,
                              color: isDark
                                  ? AppColors.darkSuccess
                                  : AppColors.lightSuccess),
                          label: Text('Payer',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkSuccess
                                      : AppColors.lightSuccess)),
                          onPressed: () => _pay(s.id),
                        ),
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        tooltip: 'Détails',
                        onPressed: () => context
                            .push('/salaries/${s.id}')
                            .then((_) => _loadData()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReport(ThemeData theme, bool isDark) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final items = [
      {
        'label': 'Masse salariale',
        'value': CurrencyFormatter.format(_report!['totalSalaryMass']),
        'icon': Icons.attach_money,
        'color': isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      },
      {
        'label': 'Total avances',
        'value': CurrencyFormatter.format(_report!['totalAdvances']),
        'icon': Icons.account_balance_wallet_outlined,
        'color': isDark ? AppColors.darkWarning : AppColors.lightWarning,
      },
      {
        'label': 'Total payé',
        'value': CurrencyFormatter.format(_report!['totalPaid']),
        'icon': Icons.payments_outlined,
        'color': isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
      },
      {
        'label': 'Effectif',
        'value': '${_report!['headcount']}',
        'icon': Icons.people_outline,
        'color': isDark ? AppColors.darkInfo : AppColors.lightInfo,
      },
    ];

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Row(
          children: [
            for (final item in items) ...[
              Expanded(child: _reportCard(theme, isDark, item)),
              if (item != items.last) const SizedBox(width: 12),
            ],
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items.map((item) {
          final w = (MediaQuery.of(context).size.width - 44) / 2;
          return SizedBox(width: w, child: _reportCard(theme, isDark, item));
        }).toList(),
      ),
    );
  }

  Widget _reportCard(
      ThemeData theme, bool isDark, Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(item['icon'] as IconData,
                size: 20, color: item['color'] as Color),
          ),
          const SizedBox(height: 12),
          Text(
            item['value'] as String,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(item['label'] as String, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: theme.textTheme.bodySmall?.color),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Shimmer.fromColors(
            baseColor:
                isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
            highlightColor:
                isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(
                  5,
                  (i) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    height: 56,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
