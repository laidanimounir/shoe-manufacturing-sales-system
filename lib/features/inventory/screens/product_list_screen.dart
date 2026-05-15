import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/product_model.dart';
import '../data/product_repository.dart';
import '../providers/product_provider.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Product> _products = [];
  String _searchText = '';
  String? _selectedCategory;
  List<String> _categories = [];

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
        ProductRepository.getAllWithStock(
          search: _searchText.isNotEmpty ? _searchText : null,
          category: _selectedCategory,
        ),
        ProductRepository.getCategories(),
      ]);
      if (mounted) {
        final loaded = results[0];
        final cats = results[1];
        setState(() {
          if (loaded is List<Product>) _products = loaded;
          if (cats is List<String>) _categories = cats;
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

  Future<void> _toggleActive(Product product) async {
    try {
      await ProductRepository.toggleActive(
        product.id,
        !product.isActive,
        product.name,
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produit ${product.isActive ? "désactivé" : "activé"} avec succès',
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() => _searchText = query);
    ref.read(productSearchProvider.notifier).state = query;
    _loadData();
  }

  void _onCategoryFilter(String? category) {
    setState(() => _selectedCategory = category);
    ref.read(productCategoryFilterProvider.notifier).state = category;
    _loadData();
  }

  void _onAdd() {
    context.push('/products/new').then((_) => _loadData());
  }

  void _onEdit(Product product) {
    context.push('/products/new', extra: product).then((_) => _loadData());
  }

  void _onViewDetail(Product product) {
    context.push('/products/${product.id}');
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
          child: RefreshIndicator(
            onRefresh: () async => _loadData(),
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
                                Text('Produits', style: theme.textTheme.headlineMedium),
                                const SizedBox(height: 4),
                                Text(
                                  'Catalogue des produits finis',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (isDesktop)
                            OutlinedButton.icon(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nouveau produit'),
                            )
                          else
                            IconButton.filled(
                              onPressed: _onAdd,
                              icon: const Icon(Icons.add),
                              tooltip: 'Nouveau produit',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSearchBar(theme, isDark),
                      if (_categories.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildCategoryChips(theme, isDark),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                _buildShimmerList(isDark, isDesktop)
              else if (_products.isEmpty)
                _buildEmptyState(theme)
              else if (isDesktop)
                _buildDesktopTable(theme, isDark)
              else
                _buildMobileCards(theme, isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          )),
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
          hintText: 'Rechercher un produit...',
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

  Widget _buildCategoryChips(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tous'),
            selected: _selectedCategory == null,
            onSelected: (_) => _onCategoryFilter(null),
          ),
          const SizedBox(width: 8),
          ..._categories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: _selectedCategory == cat,
              onSelected: (_) => _onCategoryFilter(cat),
            ),
          )),
        ],
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
                  '${_products.length} produit${_products.length > 1 ? 's' : ''}',
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
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Catégorie')),
                    DataColumn(label: Text('Taille')),
                    DataColumn(label: Text('Couleur')),
                    DataColumn(label: Text('Prix'), numeric: true),
                    DataColumn(label: Text('Stock'), numeric: true),
                    DataColumn(label: Text('Statut')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _products.map((p) {
                    return DataRow(
                      onSelectChanged: (_) => _onViewDetail(p),
                      cells: [
                        DataCell(Text(
                          p.sku ?? '-',
                          style: GoogleFonts.jetBrainsMono(fontSize: 12),
                        )),
                        DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(p.category ?? '-', style: theme.textTheme.bodySmall)),
                        DataCell(Text(p.size ?? '-', style: theme.textTheme.bodySmall)),
                        DataCell(_buildColorChip(p.color)),
                        DataCell(Text(
                          CurrencyFormatter.format(p.sellingPrice),
                          style: GoogleFonts.jetBrainsMono(fontSize: 12),
                        )),
                        DataCell(_buildStockBadge(p.totalStock, isDark)),
                        DataCell(_buildStatusChip(p.isActive, isDark)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Modifier',
                              onPressed: () => _onEdit(p),
                            ),
                            IconButton(
                              icon: Icon(
                                p.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                                size: 18,
                              ),
                              tooltip: p.isActive ? 'Désactiver' : 'Activer',
                              onPressed: () => _toggleActive(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, size: 16),
                              tooltip: 'Détails',
                              onPressed: () => _onViewDetail(p),
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
            final p = _products[index];
            return Dismissible(
              key: ValueKey(p.id),
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
                child: const Icon(Icons.check_circle_outline, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) return false;
                await _toggleActive(p);
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
                  onTap: () => _onViewDetail(p),
                  borderRadius: BorderRadius.circular(8),
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
                          child: Icon(Icons.inventory_2, size: 20,
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (p.sku != null) ...[
                                    Text(p.sku!, style: GoogleFonts.jetBrainsMono(fontSize: 11)),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(p.category ?? '', style: theme.textTheme.labelSmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(p.isActive, isDark),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(
                              children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Modifier')],
                            )),
                            PopupMenuItem(value: 'toggle', child: Row(
                              children: [Icon(Icons.block_outlined, size: 18), SizedBox(width: 8), Text(p.isActive ? 'Désactiver' : 'Activer')],
                            )),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') { _onEdit(p); }
                            else if (value == 'toggle') { _toggleActive(p); }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: _products.length,
        ),
      ),
    );
  }

  Widget _buildStockBadge(double stock, bool isDark) {
    Color color;
    String label;
    if (stock <= 0) {
      color = isDark ? AppColors.darkError : AppColors.lightError;
      label = 'Rupture';
    } else if (stock <= 10) {
      color = isDark ? AppColors.darkWarning : AppColors.lightWarning;
      label = '${stock.toStringAsFixed(0)} u';
    } else {
      color = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
      label = '${stock.toStringAsFixed(0)} u';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.15)
            : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted).withValues(alpha: 0.15),
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

  Widget _buildColorChip(String? color) {
    if (color == null || color.isEmpty) return Text('-', style: Theme.of(context).textTheme.bodySmall);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _parseColor(color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(color, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Color _parseColor(String color) {
    switch (color.toLowerCase()) {
      case 'noir': return Colors.black;
      case 'blanc': return Colors.white;
      case 'rouge': return Colors.red;
      case 'bleu': return Colors.blue;
      case 'vert': return Colors.green;
      case 'jaune': return Colors.yellow;
      case 'marron': return Colors.brown;
      case 'gris': return Colors.grey;
      case 'beige': return Color(0xFFF5F5DC);
      case 'rose': return Colors.pink;
      case 'violet': return Colors.purple;
      case 'orange': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: theme.textTheme.bodySmall?.color),
              const SizedBox(height: 12),
              Text(
                _searchText.isNotEmpty ? 'Aucun produit trouvé' : 'Aucun produit',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _searchText.isNotEmpty
                    ? 'Essayez un autre terme de recherche'
                    : 'Ajoutez votre premier produit pour commencer',
                style: theme.textTheme.bodySmall,
              ),
              if (_searchText.isEmpty) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau produit'),
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
