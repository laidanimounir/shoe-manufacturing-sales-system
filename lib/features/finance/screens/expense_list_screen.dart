import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/expense_model.dart';
import '../data/expense_repository.dart';
import '../providers/finance_provider.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});
  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  bool _isLoading = true;
  List<Expense> _expenses = [];
  List<Map<String, dynamic>> _categorySummary = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        ExpenseRepository.getAll(year: now.year, month: now.month),
        ExpenseRepository.getCategorySummary(now.year, now.month),
      ]);
      if (mounted) {
        setState(() {
          _expenses = results[0] as List<Expense>;
          _categorySummary = results[1] as List<Map<String, dynamic>>;
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

  void _confirmDelete(Expense e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer cette dépense ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              try {
                await ExpenseRepository.delete(e.id, e.category);
                if (ctx.mounted) Navigator.of(ctx).pop();
                await _loadData();
              } catch (ex) {
                _showError('Erreur: $ex');
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final totalMonth = _expenses.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        actions: [
          TextButton.icon(
            onPressed: () =>
                context.push('/expenses/new').then((_) => _loadData()),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvelle dépense'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(slivers: [
        if (_categorySummary.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(isDesktop ? 24 : 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total ce mois: ${CurrencyFormatter.format(totalMonth)}',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categorySummary.map((cs) => Chip(
                            label: Text(
                                '${cs['category']}: ${CurrencyFormatter.formatCompact(cs['total'] as double)}'),
                            avatar: Icon(Icons.circle, size: 10,
                                color: isDark ? AppColors.darkWarning : AppColors.lightWarning),
                          )).toList(),
                    ),
                  ]),
            ),
          ),
        if (_isLoading)
          _buildShimmer(isDark, isDesktop)
        else if (_expenses.isEmpty)
          _buildEmpty(theme)
        else if (isDesktop)
          _buildDesktopTable(theme, isDark)
        else
          _buildMobileCards(theme, isDark),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
    );
  }

  Widget _buildDesktopTable(ThemeData theme, bool isDark) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Catégorie')),
                    DataColumn(label: Text('Montant'), numeric: true),
                    DataColumn(label: Text('Dépôt')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _expenses.map((e) => DataRow(cells: [
                        DataCell(Text(e.formattedDate,
                            style: theme.textTheme.bodySmall)),
                        DataCell(Text(e.category,
                            style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(CurrencyFormatter.format(e.amount),
                            style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                        DataCell(Text(e.warehouseName ?? '-',
                            style: theme.textTheme.bodySmall)),
                        DataCell(Text(e.description ?? '-',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => context.push('/expenses/new', extra: e).then((_) => _loadData())),
                          IconButton(
                              icon: Icon(Icons.delete_outline, size: 18,
                                  color: isDark
                                      ? AppColors.darkError
                                      : AppColors.lightError),
                              onPressed: () => _confirmDelete(e)),
                        ])),
                      ])).toList()),
            ),
          ),
        ),
      );

  Widget _buildMobileCards(ThemeData theme, bool isDark) =>
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final e = _expenses[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: theme.colorScheme.outline)),
                    child: ListTile(
                      title: Text(e.category,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle:
                          Text('${e.formattedDate} | ${CurrencyFormatter.format(e.amount)}'),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18),
                                onPressed: () => context
                                    .push('/expenses/new', extra: e)
                                    .then((_) => _loadData())),
                            IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 18,
                                    color: isDark
                                        ? AppColors.darkError
                                        : AppColors.lightError),
                                onPressed: () => _confirmDelete(e)),
                          ]),
                    ),
                  );
                },
                childCount: _expenses.length)),
      );

  Widget _buildEmpty(ThemeData theme) => SliverToBoxAdapter(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
              child: Column(children: [
            Icon(Icons.money_off, size: 48,
                color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 12),
            Text('Aucune dépense enregistrée',
                style: theme.textTheme.titleMedium),
          ]))));

  Widget _buildShimmer(bool isDark, bool isDesktop) => SliverToBoxAdapter(
      child: Shimmer.fromColors(
          baseColor:
              isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
          highlightColor:
              isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
          child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
              child: Column(children: List.generate(
                  5,
                  (_) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      height: 56,
                      decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8))))))));
}
