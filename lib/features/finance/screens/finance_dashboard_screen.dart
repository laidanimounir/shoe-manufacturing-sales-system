import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/excel_exporter.dart';
import '../data/finance_summary_model.dart';
import '../data/finance_repository.dart';
import '../providers/finance_provider.dart';

class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});
  @override
  ConsumerState<FinanceDashboardScreen> createState() =>
      _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState
    extends ConsumerState<FinanceDashboardScreen> {
  bool _isLoading = true;
  FinanceSummary? _summary;
  List<Map<String, dynamic>> _series = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        FinanceRepository.getMonthlySummary(_selectedYear, _selectedMonth),
        FinanceRepository.getMonthlySeriesData(_selectedYear),
      ]);
      if (mounted) {
        setState(() {
          _summary = results[0] as FinanceSummary;
          _series = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur: $e');
      }
    }
  }

  void _showError(String m) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), behavior: SnackBarBehavior.floating));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, size: 20),
            tooltip: 'Exporter Excel',
            onPressed: () => ExcelExporter.exportFinanceSummary(_selectedYear),
          ),
        ],
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Tableau de bord financier',
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(_summary != null ? _summary!.monthLabel : '',
                          style: theme.textTheme.bodySmall),
                    ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text(_monthLabel(i + 1),
                                  style: const TextStyle(fontSize: 12)))),
                      onChanged: (v) {
                        setState(() => _selectedMonth = v!);
                        _loadAll();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      items: List.generate(
                          3,
                          (i) => DropdownMenuItem(
                              value: DateTime.now().year - 2 + i,
                              child: Text(
                                  '${DateTime.now().year - 2 + i}',
                                  style: const TextStyle(fontSize: 12)))),
                      onChanged: (v) {
                        setState(() => _selectedYear = v!);
                        _loadAll();
                      },
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
        if (_isLoading)
          _buildShimmer(isDark, isDesktop)
        else if (_summary == null)
          SliverToBoxAdapter(
              child: Center(
                  child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text('Erreur de chargement'),
              TextButton(onPressed: _loadAll, child: const Text('Réessayer')),
            ]),
          )))
        else ...[
          _buildKPICards(theme, isDark, isDesktop),
          _buildCostBreakdown(theme, isDark, isDesktop),
          _buildChart(theme, isDark),
          _buildQuickLinks(theme, isDark),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
    );
  }

  Widget _buildKPICards(ThemeData theme, bool isDark, bool isDesktop) {
    final s = _summary!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpiCard('Revenus', CurrencyFormatter.format(s.totalRevenue),
                isDark ? AppColors.darkInfo : AppColors.lightInfo, theme),
            _kpiCard('Bénéfice net', CurrencyFormatter.format(s.netProfit),
                s.netProfit >= 0
                    ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                    : (isDark ? AppColors.darkError : AppColors.lightError),
                theme),
            _kpiCard('Dette clients',
                CurrencyFormatter.format(s.clientDebt),
                isDark ? AppColors.darkWarning : AppColors.lightWarning, theme),
            _kpiCard('Dette fournisseurs',
                CurrencyFormatter.format(s.supplierDebt),
                isDark ? AppColors.darkWarning : AppColors.lightWarning, theme),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(
          String label, String value, Color color, ThemeData theme) =>
      SizedBox(
        width: 200,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      );

  Widget _buildCostBreakdown(
      ThemeData theme, bool isDark, bool isDesktop) {
    final s = _summary!;
    final items = [
      {'l': 'Production', 'v': s.productionCost},
      {'l': 'Achats', 'v': s.purchaseCost},
      {'l': 'Salaires', 'v': s.salariesPaid},
      {'l': 'Dépenses', 'v': s.totalExpenses},
    ];
    final maxCost =
        items.fold(0.0, (mx, i) => (i['v'] as double) > mx ? i['v'] as double : mx);

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Décomposition des coûts',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 16),
                ...items.map((item) {
                  final v = item['v'] as double;
                  final l = item['l'] as String;
                  final pct =
                      s.totalCosts > 0 ? (v / s.totalCosts * 100) : 0.0;
                  final w = maxCost > 0 ? (v / maxCost) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l, style: theme.textTheme.bodyMedium),
                                Text(
                                    '${CurrencyFormatter.format(v)}  (${pct.toStringAsFixed(1)}%)',
                                    style: theme.textTheme.labelSmall),
                              ]),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: w,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.outline,
                            ),
                          ),
                        ]),
                  );
                }),
              ]),
        ),
      ),
    );
  }

  Widget _buildChart(ThemeData theme, bool isDark) {
    final spotsRev = <FlSpot>[];
    final spotsExp = <FlSpot>[];
    for (int i = 0; i < _series.length; i++) {
      final s = _series[i];
      spotsRev.add(FlSpot(
          (s['month'] as int).toDouble(), (s['revenue'] as double)));
      spotsExp.add(FlSpot(
          (s['month'] as int).toDouble(), (s['expenses'] as double)));
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenus vs Dépenses',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) => Text(
                                _monthShort(v.toInt()),
                                style: const TextStyle(fontSize: 10)),
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) => Text(
                                CurrencyFormatter.formatCompact(v),
                                style: const TextStyle(fontSize: 10)),
                            reservedSize: 60,
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spotsRev,
                          color: isDark ? AppColors.darkInfo : AppColors.lightInfo,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: (isDark ? AppColors.darkInfo : AppColors.lightInfo)
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        LineChartBarData(
                          spots: spotsExp,
                          color: isDark ? AppColors.darkError : AppColors.lightError,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: (isDark ? AppColors.darkError : AppColors.lightError)
                                .withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _legendDot(isDark ? AppColors.darkInfo : AppColors.lightInfo),
                  const SizedBox(width: 4),
                  const Text('Revenus', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 20),
                  _legendDot(isDark ? AppColors.darkError : AppColors.lightError),
                  const SizedBox(width: 4),
                  const Text('Dépenses', style: TextStyle(fontSize: 12)),
                ]),
              ]),
        ),
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _buildQuickLinks(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Wrap(spacing: 12, children: [
          OutlinedButton.icon(
            onPressed: () => context.push('/expenses'),
            icon: const Icon(Icons.money_off, size: 18),
            label: const Text('Voir dépenses'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.push('/audit-logs'),
            icon: const Icon(Icons.history, size: 18),
            label: const Text("Audit logs"),
          ),
        ]),
      ),
    );
  }

  String _monthLabel(int m) {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[m];
  }

  String _monthShort(int m) {
    const months = ['', 'Jan','Fév','Mar','Avr','Mai','Juin','Juil','Aoû','Sep','Oct','Nov','Déc'];
    return months[m.clamp(1, 12)];
  }

  Widget _buildShimmer(bool isDark, bool isDesktop) {
    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
        highlightColor:
            isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(children: [
            Row(children: List.generate(3, (_) => Expanded(
              child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  height: 100,
                  decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(8)))))),
            const SizedBox(height: 16),
            Container(
                height: 200,
                decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 16),
            Container(
                height: 250,
                decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(8))),
          ]),
        ),
      ),
    );
  }
}
