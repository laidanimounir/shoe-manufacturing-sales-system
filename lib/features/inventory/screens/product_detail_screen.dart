import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/product_model.dart';
import '../data/product_repository.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  List<Map<String, dynamic>> _stockByWarehouse = [];
  List<Map<String, dynamic>> _recentSales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseService.client;
      final results = await Future.wait<Object>([
        ProductRepository.getById(widget.productId) as Future<Object>,
        client.from('inventory')
            .select('quantity, warehouse_id, warehouses(name)')
            .eq('product_id', widget.productId) as Future<Object>,
        client.from('invoice_items')
            .select('quantity, unit_price, invoice_id, invoices(invoice_number, invoice_date, client_id, clients(name))')
            .eq('product_id', widget.productId)
            .order('invoice_id', ascending: false)
            .limit(10) as Future<Object>,
      ]);

      if (mounted) {
        setState(() {
          _product = results[0] as Product?;
          _stockByWarehouse = List<Map<String, dynamic>>.from(results[1] as List);
          _recentSales = List<Map<String, dynamic>>.from(results[2] as List);
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

  void _onEdit() {
    if (_product == null) return;
    context.push('/products/new', extra: _product).then((_) => _loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Détails du produit'),
        actions: [
          if (_product != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Modifier',
              onPressed: _onEdit,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Rafraîchir',
            onPressed: _loadAll,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: _isLoading
            ? _buildShimmer(isDark, isDesktop)
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: Column(
                              children: [
                                _buildInfoCard(theme, isDark),
                                const SizedBox(height: 16),
                                _buildStockTable(theme, isDark),
                              ],
                            )),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: Column(
                              children: [
                                _buildSalesTable(theme, isDark),
                              ],
                            )),
                          ],
                        )
                      : Column(
                          children: [
                            _buildInfoCard(theme, isDark),
                            const SizedBox(height: 12),
                            _buildStockTable(theme, isDark),
                            const SizedBox(height: 12),
                            _buildSalesTable(theme, isDark),
                          ],
                        ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark) {
    if (_product == null) return const SizedBox.shrink();
    final p = _product!;

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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, size: 22,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: theme.textTheme.titleLarge),
                    if (p.sku != null)
                      Text('SKU: ${p.sku!}', style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                  ],
                ),
              ),
              _buildStatusChip(p.isActive, isDark),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _buildInfoTile(theme, 'Catégorie', p.category ?? '-')),
              Expanded(child: _buildInfoTile(theme, 'Taille', p.size ?? '-')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInfoTile(theme, 'Couleur', p.color ?? '-')),
              Expanded(child: _buildInfoTile(theme, 'Matière', p.material ?? '-')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInfoTile(theme, 'Prix de vente', CurrencyFormatter.format(p.sellingPrice))),
              if (p.barcode != null)
                Expanded(child: _buildInfoTile(theme, 'Code-barres', p.barcode!, mono: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(ThemeData theme, String label, String value, {bool mono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: mono
              ? GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w500)
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildStockTable(ThemeData theme, bool isDark) {
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
          Text('Stock par dépôt', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_stockByWarehouse.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Aucun stock', style: theme.textTheme.bodySmall)),
            )
          else
            ..._stockByWarehouse.map((item) {
              final wh = item['warehouses'];
              final whName = wh is Map ? (wh['name'] ?? '-') : '-';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.warehouse, size: 16,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(whName, style: theme.textTheme.bodyMedium)),
                    Text(
                      '${item['quantity'] ?? 0}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: (item['quantity'] as num? ?? 0) > 0
                            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSalesTable(ThemeData theme, bool isDark) {
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
          Text('Dernières ventes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_recentSales.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Aucune vente', style: theme.textTheme.bodySmall)),
            )
          else
            ..._recentSales.map((sale) {
              final inv = sale['invoices'];
              final client = inv is Map ? inv['clients'] : null;
              final clientName = client is Map ? (client['name'] ?? '-') : '-';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${sale['quantity'] ?? 0}x',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clientName, style: theme.textTheme.bodyMedium),
                          Text(
                            CurrencyFormatter.format((sale['unit_price'] as num?)?.toDouble()),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
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

  Widget _buildShimmer(bool isDark, bool isDesktop) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
      highlightColor: isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            children: [
              Container(height: 160, decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(8),
              )),
              const SizedBox(height: 16),
              Container(height: 120, decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(8),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
