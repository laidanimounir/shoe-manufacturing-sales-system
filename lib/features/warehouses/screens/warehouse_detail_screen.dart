import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../data/warehouse_model.dart';
import '../data/warehouse_repository.dart';
import 'warehouse_form_screen.dart';

class WarehouseDetailScreen extends ConsumerStatefulWidget {
  final String warehouseId;

  const WarehouseDetailScreen({super.key, required this.warehouseId});

  @override
  ConsumerState<WarehouseDetailScreen> createState() =>
      _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState
    extends ConsumerState<WarehouseDetailScreen> {
  Warehouse? _warehouse;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        WarehouseRepository.getById(widget.warehouseId),
        WarehouseRepository.getStats(widget.warehouseId),
        WarehouseRepository.getEmployees(widget.warehouseId),
        WarehouseRepository.getInventorySummary(widget.warehouseId),
      ]);

      if (mounted) {
        setState(() {
          _warehouse = results[0] as Warehouse?;
          _stats = results[1] as Map<String, dynamic>?;
          _employees = List<Map<String, dynamic>>.from(results[2] as List);
          _inventory = List<Map<String, dynamic>>.from(results[3] as List);
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

  void _onEdit() {
    if (_warehouse == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WarehouseFormScreen(warehouse: _warehouse),
      ),
    ).then((_) => _loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(_warehouse?.name ?? 'Détails du dépôt'),
        actions: [
          if (_warehouse != null)
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
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildInfoCard(theme, isDark),
                                  const SizedBox(height: 16),
                                  _buildInventoryTable(theme, isDark),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildStatsCard(theme, isDark),
                                  const SizedBox(height: 16),
                                  _buildEmployeesList(theme, isDark),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildInfoCard(theme, isDark),
                            const SizedBox(height: 12),
                            _buildStatsCard(theme, isDark),
                            const SizedBox(height: 12),
                            _buildEmployeesList(theme, isDark),
                            const SizedBox(height: 12),
                            _buildInventoryTable(theme, isDark),
                          ],
                        ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark) {
    if (_warehouse == null) return const SizedBox.shrink();

    final w = _warehouse!;
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
                  color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warehouse,
                  size: 22,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.name, style: theme.textTheme.titleLarge),
                    if (w.location != null)
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Text(w.location!, style: theme.textTheme.bodySmall),
                        ],
                      ),
                  ],
                ),
              ),
              _buildStatusChip(w.isActive, isDark),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildInfoTile(theme, 'Créé le', w.formattedDate),
              const SizedBox(width: 24),
              _buildInfoTile(
                theme,
                'Statut',
                w.isActive ? 'Actif' : 'Inactif',
              ),
              const SizedBox(width: 24),
              _buildInfoTile(
                theme,
                'ID',
                w.id.substring(0, 8),
                mono: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(ThemeData theme, String label, String value,
      {bool mono = false}) {
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

  Widget _buildStatsCard(ThemeData theme, bool isDark) {
    final totalProducts = _stats?['totalProducts'] ?? 0;
    final activeEmployees = _stats?['activeEmployees'] ?? 0;
    final productVarieties = _stats?['productVarieties'] ?? 0;

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
          Text('Statistiques', style: theme.textTheme.titleMedium),
          const SizedBox(height: 14),
          _buildStatRow(
            theme,
            'Produits en stock',
            '$totalProducts',
            Icons.inventory_2,
            isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
          ),
          const Divider(height: 18),
          _buildStatRow(
            theme,
            'Variétés de produits',
            '$productVarieties',
            Icons.category_outlined,
            isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
          const Divider(height: 18),
          _buildStatRow(
            theme,
            'Employés actifs',
            '$activeEmployees',
            Icons.people,
            isDark ? AppColors.darkWarning : AppColors.lightWarning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
      ThemeData theme, String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeesList(ThemeData theme, bool isDark) {
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
              Icon(Icons.people_outline,
                  size: 18,
                  color: isDark ? AppColors.darkWarning : AppColors.lightWarning),
              const SizedBox(width: 8),
              Text('Employés assignés', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '${_employees.length}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_employees.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Aucun employé assigné',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            )
          else
            ..._employees.map((emp) {
              final profileData = emp['profiles'];
              final fullName = profileData is Map
                  ? (profileData['full_name'] ?? '-')
                  : '-';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: (isDark
                              ? AppColors.darkWarning
                              : AppColors.lightWarning)
                          .withValues(alpha: 0.15),
                      child: Text(
                        fullName.isNotEmpty
                            ? fullName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkWarning
                              : AppColors.lightWarning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (emp['job_title'] != null)
                            Text(
                              emp['job_title'] as String,
                              style: theme.textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (emp['is_active'] == true
                                ? (isDark
                                    ? AppColors.darkSuccess
                                    : AppColors.lightSuccess)
                                : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        emp['is_active'] == true ? 'Actif' : 'Inactif',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: emp['is_active'] == true
                              ? (isDark
                                  ? AppColors.darkSuccess
                                  : AppColors.lightSuccess)
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
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

  Widget _buildInventoryTable(ThemeData theme, bool isDark) {
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
          Text('État du stock', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_inventory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Aucun produit en stock',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 36,
                headingRowHeight: 32,
                columns: const [
                  DataColumn(label: Text('Produit')),
                  DataColumn(label: Text('Catégorie')),
                  DataColumn(label: Text('Quantité'), numeric: true),
                ],
                rows: _inventory.take(15).map((item) {
                  final productData = item['products'];
                  final productName =
                      productData is Map ? (productData['name'] ?? '-') : '-';
                  final category = productData is Map
                      ? (productData['category'] ?? '-')
                      : '-';
                  return DataRow(cells: [
                    DataCell(
                      Text(
                        productName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(Text(category, style: theme.textTheme.bodySmall)),
                    DataCell(
                      Text(
                        '${item['quantity'] ?? 0}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: (item['quantity'] as num? ?? 0) > 0
                              ? (isDark
                                  ? AppColors.darkSuccess
                                  : AppColors.lightSuccess)
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
        ],
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
              ? (isDark
                  ? AppColors.darkSuccess
                  : AppColors.lightSuccess)
              : (isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark, bool isDesktop) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
      highlightColor:
          isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
