import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/raw_material_model.dart';
import '../data/raw_material_repository.dart';
import '../providers/raw_material_provider.dart';

class RawMaterialListScreen extends ConsumerStatefulWidget {
  const RawMaterialListScreen({super.key});

  @override
  ConsumerState<RawMaterialListScreen> createState() => _RawMaterialListScreenState();
}

class _RawMaterialListScreenState extends ConsumerState<RawMaterialListScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<RawMaterial> _materials = [];
  String _searchText = '';
  List<RawMaterial> _lowStockItems = [];

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
      final results = await Future.wait([
        RawMaterialRepository.getAll(search: _searchText.isNotEmpty ? _searchText : null),
        RawMaterialRepository.getLowStock(),
      ]);
      if (mounted) {
        setState(() {
          _materials = results[0] as List<RawMaterial>;
          _lowStockItems = results[1] as List<RawMaterial>;
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

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() => _searchText = query);
    ref.read(rawMaterialSearchProvider.notifier).state = query;
    _loadData();
  }

  void _onAdd() {
    context.push('/raw-materials/new').then((_) => _loadData());
  }

  void _onEdit(RawMaterial m) {
    context.push('/raw-materials/new', extra: m).then((_) => _loadData());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Rupture': return Colors.red;
      case 'Stock bas': return Colors.orange;
      default: return Colors.green;
    }
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
              if (_lowStockItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, size: 16,
                            color: isDark ? AppColors.darkError : AppColors.lightError),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
            '${_lowStockItems.length} matière${_lowStockItems.length > 1 ? 's' : ''} en stock bas',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkError : AppColors.lightError,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                                Text('Matières premières', style: theme.textTheme.headlineMedium),
                                const SizedBox(height: 4),
                                Text('Gestion des stocks de matières', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          if (isDesktop)
                            OutlinedButton.icon(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nouvelle matière'),
                            )
                          else
                            IconButton.filled(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add),
                              tooltip: 'Nouvelle matière',
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
              else if (_materials.isEmpty)
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
          hintText: 'Rechercher une matière...',
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
                  '${_materials.length} matière${_materials.length > 1 ? 's' : ''}',
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
                    DataColumn(label: Text('Unité')),
                    DataColumn(label: Text('Dépôt')),
                    DataColumn(label: Text('Quantité'), numeric: true),
                    DataColumn(label: Text('Min'), numeric: true),
                    DataColumn(label: Text('Coût unitaire'), numeric: true),
                    DataColumn(label: Text('Statut')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _materials.map((m) {
                    final status = m.statusLabel;
                    return DataRow(
                      cells: [
                        DataCell(Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(m.unit, style: theme.textTheme.bodySmall)),
                        DataCell(Text(m.warehouseName ?? '-', style: theme.textTheme.bodySmall)),
                        DataCell(Text('${m.quantity}', style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                        DataCell(Text('${m.minQuantity}', style: GoogleFonts.jetBrainsMono(fontSize: 12))),
                        DataCell(Text(
                          CurrencyFormatter.format(m.unitCost),
                          style: GoogleFonts.jetBrainsMono(fontSize: 12),
                        )),
                        DataCell(_buildStatusChip(status, isDark)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Modifier',
                              onPressed: () => _onEdit(m),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              tooltip: 'Ajuster le stock',
                              onPressed: () => _showStockDialog(m),
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
            final m = _materials[index];
            final status = m.statusLabel;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkWarning : AppColors.lightWarning).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory, size: 20,
                            color: isDark ? AppColors.darkWarning : AppColors.lightWarning),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text('${m.quantity} ${m.unit}', style: theme.textTheme.labelSmall),
                                if (m.warehouseName != null) ...[
                                  const SizedBox(width: 8),
                                  Text(m.warehouseName!, style: theme.textTheme.labelSmall),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(status, isDark),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Row(
                            children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Modifier')],
                          )),
                          const PopupMenuItem(value: 'stock', child: Row(
                            children: [Icon(Icons.refresh, size: 18), SizedBox(width: 8), Text('Ajuster stock')],
                          )),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') _onEdit(m);
                          else if (value == 'stock') _showStockDialog(m);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _materials.length,
        ),
      ),
    );
  }

  void _showStockDialog(RawMaterial material) {
    final controller = TextEditingController(text: material.quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajuster le stock - ${material.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Nouvelle quantité (${material.unit})',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              final qty = double.tryParse(controller.text.replaceAll(',', '.'));
              if (qty == null) return;
              try {
                await RawMaterialRepository.updateStock(material.id, qty, material.name);
                if (ctx.mounted) Navigator.of(ctx).pop();
                await _loadData();
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isDark) {
    Color color;
    switch (status) {
      case 'Rupture': color = isDark ? AppColors.darkError : AppColors.lightError;
      case 'Stock bas': color = isDark ? AppColors.darkWarning : AppColors.lightWarning;
      default: color = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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
              Icon(Icons.inventory_outlined, size: 48, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 12),
              Text(_searchText.isNotEmpty ? 'Aucune matière trouvée' : 'Aucune matière',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                _searchText.isNotEmpty ? 'Essayez un autre terme' : 'Ajoutez votre première matière',
                style: theme.textTheme.bodySmall,
              ),
              if (_searchText.isEmpty) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle matière'),
                ),
              ],
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
