import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../data/warehouse_model.dart';
import '../data/warehouse_repository.dart';
import '../providers/warehouse_provider.dart';
import 'warehouse_form_screen.dart';
import 'warehouse_detail_screen.dart';

class WarehouseListScreen extends ConsumerStatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  ConsumerState<WarehouseListScreen> createState() =>
      _WarehouseListScreenState();
}

class _WarehouseListScreenState extends ConsumerState<WarehouseListScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Warehouse> _warehouses = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    try {
      final warehouses = await WarehouseRepository.getAll(search: _searchText.isNotEmpty ? _searchText : null);
      if (mounted) {
        setState(() {
          _warehouses = warehouses;
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

  Future<void> _toggleActive(Warehouse warehouse) async {
    try {
      await WarehouseRepository.toggleActive(
        warehouse.id,
        !warehouse.isActive,
        warehouse.name,
      );
      await _loadWarehouses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dépôt ${warehouse.isActive ? "désactivé" : "activé"} avec succès',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() => _searchText = query);
    ref.read(searchQueryProvider.notifier).state = query;
    _loadWarehouses();
  }

  void _onAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WarehouseFormScreen()),
    ).then((_) => _loadWarehouses());
  }

  void _onEdit(Warehouse warehouse) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WarehouseFormScreen(warehouse: warehouse),
      ),
    ).then((_) => _loadWarehouses());
  }

  void _onViewDetail(Warehouse warehouse) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WarehouseDetailScreen(warehouseId: warehouse.id),
      ),
    );
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
            const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                _onAdd,
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
                                Text(
                                  'Dépôts',
                                  style: theme.textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gestion des entrepôts et usines',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (isDesktop)
                            OutlinedButton.icon(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nouveau dépôt'),
                            )
                          else
                            IconButton.filled(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add),
                              tooltip: 'Nouveau dépôt',
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
              else if (_warehouses.isEmpty)
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
        onChanged: (_) => _onSearchChanged(),
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Rechercher un dépôt...',
          hintStyle: theme.textTheme.bodySmall,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  '${_warehouses.length} dépôt${_warehouses.length > 1 ? 's' : ''}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 44,
                  headingRowHeight: 36,
                  columns: const [
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Emplacement')),
                    DataColumn(label: Text('Statut')),
                    DataColumn(label: Text('Créé le')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _warehouses.map((w) {
                    return DataRow(
                      onSelectChanged: (_) => _onViewDetail(w),
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.lightPrimary)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.warehouse,
                                  size: 16,
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                w.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            w.location ?? '-',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        DataCell(_buildStatusChip(w.isActive, isDark)),
                        DataCell(
                          Text(
                            w.formattedDate,
                            style: GoogleFonts.jetBrainsMono(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Modifier',
                                onPressed: () => _onEdit(w),
                              ),
                              IconButton(
                                icon: Icon(
                                  w.isActive
                                      ? Icons.block_outlined
                                      : Icons.check_circle_outline,
                                  size: 18,
                                ),
                                tooltip: w.isActive ? 'Désactiver' : 'Activer',
                                onPressed: () => _toggleActive(w),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16),
                                tooltip: 'Détails',
                                onPressed: () => _onViewDetail(w),
                              ),
                            ],
                          ),
                        ),
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
            final w = _warehouses[index];
            return Dismissible(
              key: ValueKey(w.id),
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                color: isDark ? AppColors.darkError : AppColors.lightError,
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                child: const Icon(Icons.check_circle_outline,
                    color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  return false;
                }
                await _toggleActive(w);
                return false;
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: InkWell(
                  onTap: () => _onViewDetail(w),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.warehouse,
                            size: 20,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (w.location != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 12,
                                        color: theme.textTheme.bodySmall?.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      w.location!,
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        _buildStatusChip(w.isActive, isDark),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    w.isActive
                                        ? Icons.block_outlined
                                        : Icons.check_circle_outline,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(w.isActive ? 'Désactiver' : 'Activer'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _onEdit(w);
                            } else if (value == 'toggle') {
                              _toggleActive(w);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: _warehouses.length,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                .withValues(alpha: 0.15)
            : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Actif' : 'Inactif',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive
              ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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
              Icon(Icons.warehouse_outlined,
                  size: 48, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 12),
              Text(
                _searchText.isNotEmpty
                    ? 'Aucun dépôt trouvé'
                    : 'Aucun dépôt',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _searchText.isNotEmpty
                    ? 'Essayez un autre terme de recherche'
                    : 'Ajoutez votre premier entrepôt pour commencer',
                style: theme.textTheme.bodySmall,
              ),
              if (_searchText.isEmpty) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau dépôt'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(bool isDark, bool isDesktop) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
      highlightColor:
          isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
      child: SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            childCount: 5,
          ),
        ),
      ),
    );
  }
}
