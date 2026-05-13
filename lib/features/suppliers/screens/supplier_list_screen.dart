import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/supplier_model.dart';
import '../data/supplier_repository.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Supplier> _suppliers = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await SupplierRepository.getAll(
        search: _searchText.isNotEmpty ? _searchText : null,
      );
      if (mounted) {
        setState(() {
          _suppliers = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur de chargement: $e');
      }
    }
  }

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _onAdd() {
    context.push('/suppliers/new').then((_) => _loadData());
  }

  void _onEdit(Supplier s) {
    context.push('/suppliers/new', extra: s).then((_) => _loadData());
  }

  void _onDetail(Supplier s) {
    context.push('/suppliers/${s.id}').then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          if (isDesktop)
            const SingleActivator(LogicalKeyboardKey.keyN, control: true): _onAdd,
        },
        child: Focus(
          autofocus: true,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fournisseurs', style: theme.textTheme.headlineMedium),
                                const SizedBox(height: 4),
                                Text('Gestion des fournisseurs', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          if (isDesktop)
                            OutlinedButton.icon(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nouveau fournisseur'),
                            )
                          else
                            IconButton.filled(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add),
                              tooltip: 'Nouveau fournisseur',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSearchBar(theme, isDark),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                _buildShimmerList(isDark, isDesktop)
              else if (_suppliers.isEmpty)
                _buildEmptyState(theme)
              else if (isDesktop)
                _buildDesktopTable(theme, isDark)
              else
                _buildMobileCards(theme, isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          setState(() => _searchText = _searchController.text);
          _loadData();
        },
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Rechercher un fournisseur...',
          hintStyle: theme.textTheme.bodySmall,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchText = '');
                    _loadData();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Text(
                  '${_suppliers.length} fournisseur${_suppliers.length > 1 ? 's' : ''}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 44,
                  headingRowHeight: 36,
                  columns: const [
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Téléphone')),
                    DataColumn(label: Text('Ville')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Dette'), numeric: true),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _suppliers.map((s) {
                    return DataRow(
                      onSelectChanged: (_) => _onDetail(s),
                      cells: [
                        DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(s.phone ?? '-', style: theme.textTheme.bodySmall)),
                        DataCell(Text(s.city ?? '-', style: theme.textTheme.bodySmall)),
                        DataCell(_buildTypeChip(s.supplyTypeLabel, isDark)),
                        DataCell(Text(
                          CurrencyFormatter.format(s.totalDebt),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: s.totalDebt > 0
                                ? (isDark ? AppColors.darkError : AppColors.lightError)
                                : null,
                          ),
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                              tooltip: 'Détails',
                              onPressed: () => _onDetail(s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Modifier',
                              onPressed: () => _onEdit(s),
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCards(ThemeData theme, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final s = _suppliers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _onDetail(s),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.local_shipping, size: 20,
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(s.city ?? '-', style: theme.textTheme.labelSmall),
                                const SizedBox(width: 8),
                                Text(s.supplyTypeLabel, style: theme.textTheme.labelSmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (s.totalDebt > 0)
                        Text(
                          CurrencyFormatter.format(s.totalDebt),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: isDark ? AppColors.darkError : AppColors.lightError,
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _suppliers.length,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkInfo : AppColors.lightInfo,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.local_shipping_outlined, size: 48, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 12),
              Text('Aucun fournisseur', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Ajoutez votre premier fournisseur', style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau fournisseur'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(bool isDark, bool isDesktop) {
    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
        highlightColor: isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
          child: Column(
            children: List.generate(5, (_) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(8),
              ),
            )),
          ),
        ),
      ),
    );
  }
}
