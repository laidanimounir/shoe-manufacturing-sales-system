import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  bool _isLoading = true;
  String _userName = '';

  // KPI Data
  int _todayProduction = 0;
  int _pendingInvoices = 0;
  int _lowStockAlerts = 0;
  double _totalClientDebt = 0;
  double _totalSupplierDebt = 0;
  double _todayRevenue = 0;
  int _activeOrders = 0;
  int _totalProducts = 0;
  int _totalEmployees = 0;
  int _totalWarehouses = 0;

  // Recent activity
  List<Map<String, dynamic>> _recentInvoices = [];
  List<Map<String, dynamic>> _recentProductionOrders = [];
  List<Map<String, dynamic>> _lowStockItems = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final client = SupabaseService.client;

      // Get user profile
      final profile = await SupabaseService.getCurrentProfile();
      _userName = profile?['full_name'] ?? 'Utilisateur';

      // Run all queries in parallel
      final results = await Future.wait([
        // 0: Today's production
        client
            .from('production_logs')
            .select('quantity')
            .eq('log_date', DateTime.now().toIso8601String().substring(0, 10)),
        // 1: Pending/unpaid invoices count
        client
            .from('invoices')
            .select('id')
            .eq('payment_status', 'unpaid'),
        // 2: Low stock raw materials
        client.rpc('', params: {}).catchError((_) => <Map<String, dynamic>>[]),
        // 3: Total client debt
        client.from('clients').select('total_debt'),
        // 4: Total supplier debt
        client.from('suppliers').select('total_debt'),
        // 5: Today's revenue
        client
            .from('invoices')
            .select('total_amount')
            .eq('invoice_date', DateTime.now().toIso8601String().substring(0, 10)),
        // 6: Active production orders
        client
            .from('production_orders')
            .select('id')
            .inFilter('status', ['pending', 'in_progress']),
        // 7: Total products
        client.from('products').select('id').eq('is_active', true),
        // 8: Total employees
        client.from('employees').select('id').eq('is_active', true),
        // 9: Total warehouses
        client.from('warehouses').select('id').eq('is_active', true),
        // 10: Recent invoices
        client
            .from('invoices')
            .select('id, invoice_number, total_amount, payment_status, invoice_date, client_id, clients(name)')
            .order('created_at', ascending: false)
            .limit(5),
        // 11: Recent production orders
        client
            .from('production_orders')
            .select('id, ordered_qty, produced_qty, status, target_date, product_id, products(name)')
            .order('created_at', ascending: false)
            .limit(5),
        // 12: Low stock materials
        client.from('raw_materials').select('id, name, quantity, min_quantity, unit'),
      ]);

      // Process results
      final todayLogs = results[0] as List;
      _todayProduction = todayLogs.fold<int>(
          0, (sum, log) => sum + ((log['quantity'] as num?)?.toInt() ?? 0));

      final unpaidInvoices = results[1] as List;
      _pendingInvoices = unpaidInvoices.length;

      final clientDebts = results[3] as List;
      _totalClientDebt = clientDebts.fold<double>(
          0, (sum, c) => sum + ((c['total_debt'] as num?)?.toDouble() ?? 0));

      final supplierDebts = results[4] as List;
      _totalSupplierDebt = supplierDebts.fold<double>(
          0, (sum, s) => sum + ((s['total_debt'] as num?)?.toDouble() ?? 0));

      final todayInvoices = results[5] as List;
      _todayRevenue = todayInvoices.fold<double>(
          0, (sum, i) => sum + ((i['total_amount'] as num?)?.toDouble() ?? 0));

      final activeOrders = results[6] as List;
      _activeOrders = activeOrders.length;

      _totalProducts = (results[7] as List).length;
      _totalEmployees = (results[8] as List).length;
      _totalWarehouses = (results[9] as List).length;

      _recentInvoices = List<Map<String, dynamic>>.from(results[10] as List);
      _recentProductionOrders = List<Map<String, dynamic>>.from(results[11] as List);

      // Filter low stock
      final allMaterials = List<Map<String, dynamic>>.from(results[12] as List);
      _lowStockItems = allMaterials
          .where((m) =>
              (m['quantity'] as num? ?? 0) <=
              (m['min_quantity'] as num? ?? 0))
          .toList();
      _lowStockAlerts = _lowStockItems.length;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline,
                    color: Theme.of(context).colorScheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Erreur de chargement: ${e.toString()}')),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          slivers: [
            // Header
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
                                'Bonjour, $_userName',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Voici un aperçu de votre activité',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _loadDashboardData,
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Rafraîchir',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── KPI Cards ───
                    _isLoading
                        ? _buildShimmerGrid(isDesktop)
                        : _buildKpiGrid(isDesktop, isDark),
                  ],
                ),
              ),
            ),

            // ─── Main Content ───
            if (!_isLoading)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
                sliver: SliverToBoxAdapter(
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildRecentInvoicesTable(theme),
                                  const SizedBox(height: 16),
                                  _buildRecentProductionTable(theme),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildQuickStats(theme, isDark),
                                  const SizedBox(height: 16),
                                  _buildLowStockAlerts(theme, isDark),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildQuickStats(theme, isDark),
                            const SizedBox(height: 16),
                            _buildRecentInvoicesTable(theme),
                            const SizedBox(height: 16),
                            _buildLowStockAlerts(theme, isDark),
                            const SizedBox(height: 16),
                            _buildRecentProductionTable(theme),
                          ],
                        ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ─── KPI Grid ───
  Widget _buildKpiGrid(bool isDesktop, bool isDark) {
    final kpis = [
      _KpiData(
        title: "Production aujourd'hui",
        value: '$_todayProduction paires',
        icon: Icons.precision_manufacturing,
        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      ),
      _KpiData(
        title: 'Factures impayées',
        value: '$_pendingInvoices',
        icon: Icons.receipt_long,
        color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
      ),
      _KpiData(
        title: 'Alertes stock bas',
        value: '$_lowStockAlerts',
        icon: Icons.warning_amber,
        color: isDark ? AppColors.darkError : AppColors.lightError,
      ),
      _KpiData(
        title: "Chiffre d'affaires du jour",
        value: CurrencyFormatter.format(_todayRevenue),
        icon: Icons.trending_up,
        color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
      ),
      _KpiData(
        title: 'Dette clients',
        value: CurrencyFormatter.formatCompact(_totalClientDebt),
        icon: Icons.people,
        color: isDark ? AppColors.darkWarning : AppColors.lightWarning,
      ),
      _KpiData(
        title: 'Dette fournisseurs',
        value: CurrencyFormatter.formatCompact(_totalSupplierDebt),
        icon: Icons.local_shipping,
        color: isDark ? AppColors.darkError : AppColors.lightError,
      ),
      _KpiData(
        title: 'Commandes actives',
        value: '$_activeOrders',
        icon: Icons.assignment,
        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      ),
      _KpiData(
        title: 'Produits actifs',
        value: '$_totalProducts',
        icon: Icons.inventory_2,
        color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isDesktop ? 2.2 : 1.6,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) => _buildKpiCard(kpis[index]),
    );
  }

  Widget _buildKpiCard(_KpiData data) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 16, color: data.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  style: theme.textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            data.value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.headlineMedium?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Quick Stats ───
  Widget _buildQuickStats(ThemeData theme, bool isDark) {
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
          Text('Vue d\'ensemble', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildStatRow(theme, 'Dépôts actifs', '$_totalWarehouses',
              Icons.warehouse, isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
          const Divider(height: 20),
          _buildStatRow(theme, 'Produits', '$_totalProducts',
              Icons.inventory_2, isDark ? AppColors.darkSuccess : AppColors.lightSuccess),
          const Divider(height: 20),
          _buildStatRow(theme, 'Employés', '$_totalEmployees',
              Icons.people, isDark ? AppColors.darkWarning : AppColors.lightWarning),
          const Divider(height: 20),
          _buildStatRow(theme, 'Commandes actives', '$_activeOrders',
              Icons.assignment, isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
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
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  // ─── Recent Invoices Table ───
  Widget _buildRecentInvoicesTable(ThemeData theme) {
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
              Expanded(
                child: Text('Dernières factures',
                    style: theme.textTheme.titleLarge),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recentInvoices.isEmpty)
            _buildEmptyState(theme, Icons.receipt_long, 'Aucune facture')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 40,
                headingRowHeight: 36,
                columns: const [
                  DataColumn(label: Text('N° Facture')),
                  DataColumn(label: Text('Client')),
                  DataColumn(label: Text('Montant'), numeric: true),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Date')),
                ],
                rows: _recentInvoices.map((invoice) {
                  final clientData = invoice['clients'];
                  final clientName = clientData is Map
                      ? (clientData['name'] ?? '-')
                      : '-';
                  return DataRow(cells: [
                    DataCell(Text(
                      invoice['invoice_number'] ?? '-',
                      style: GoogleFonts.jetBrainsMono(fontSize: 12),
                    )),
                    DataCell(Text(clientName)),
                    DataCell(Text(
                      CurrencyFormatter.format(
                          (invoice['total_amount'] as num?)?.toDouble()),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                    DataCell(_buildStatusChip(
                        invoice['payment_status'] ?? 'unpaid')),
                    DataCell(Text(invoice['invoice_date'] ?? '-')),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Recent Production Table ───
  Widget _buildRecentProductionTable(ThemeData theme) {
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
              Expanded(
                child: Text('Commandes de production',
                    style: theme.textTheme.titleLarge),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recentProductionOrders.isEmpty)
            _buildEmptyState(
                theme, Icons.precision_manufacturing, 'Aucune commande')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 40,
                headingRowHeight: 36,
                columns: const [
                  DataColumn(label: Text('Produit')),
                  DataColumn(label: Text('Commandé'), numeric: true),
                  DataColumn(label: Text('Produit'), numeric: true),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Date cible')),
                ],
                rows: _recentProductionOrders.map((order) {
                  final productData = order['products'];
                  final productName = productData is Map
                      ? (productData['name'] ?? '-')
                      : '-';
                  return DataRow(cells: [
                    DataCell(Text(productName)),
                    DataCell(Text(
                      '${order['ordered_qty'] ?? 0}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 12),
                    )),
                    DataCell(Text(
                      '${order['produced_qty'] ?? 0}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 12),
                    )),
                    DataCell(
                        _buildProductionStatusChip(order['status'] ?? 'pending')),
                    DataCell(Text(order['target_date'] ?? '-')),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Low Stock Alerts ───
  Widget _buildLowStockAlerts(ThemeData theme, bool isDark) {
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
              Icon(Icons.warning_amber, size: 16,
                  color: isDark ? AppColors.darkWarning : AppColors.lightWarning),
              const SizedBox(width: 8),
              Text('Alertes stock bas', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          if (_lowStockItems.isEmpty)
            _buildEmptyState(theme, Icons.check_circle_outline,
                'Aucune alerte de stock')
          else
            ..._lowStockItems.take(5).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkError
                            : AppColors.lightError,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? '',
                              style: theme.textTheme.bodyMedium),
                          Text(
                            '${item['quantity'] ?? 0} / ${item['min_quantity'] ?? 0} ${item['unit'] ?? ''}',
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

  // ─── Status Chips ───
  Widget _buildStatusChip(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'paid':
        bgColor = (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
            .withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
        label = 'Payé';
        break;
      case 'partial':
        bgColor = (isDark ? AppColors.darkWarning : AppColors.lightWarning)
            .withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkWarning : AppColors.lightWarning;
        label = 'Partiel';
        break;
      default:
        bgColor = (isDark ? AppColors.darkError : AppColors.lightError)
            .withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkError : AppColors.lightError;
        label = 'Impayé';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildProductionStatusChip(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'completed':
        bgColor = (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
            .withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
        label = 'Terminé';
        break;
      case 'in_progress':
        bgColor = (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
            .withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
        label = 'En cours';
        break;
      case 'cancelled':
        bgColor = (isDark ? AppColors.darkError : AppColors.lightError)
            .withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkError : AppColors.lightError;
        label = 'Annulé';
        break;
      default:
        bgColor = (isDark ? AppColors.darkWarning : AppColors.lightWarning)
            .withValues(alpha: 0.15);
        textColor = isDark ? AppColors.darkWarning : AppColors.lightWarning;
        label = 'En attente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ─── Empty State ───
  Widget _buildEmptyState(ThemeData theme, IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  // ─── Shimmer Loading ───
  Widget _buildShimmerGrid(bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8),
      highlightColor:
          isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isDesktop ? 2.2 : 1.6,
        ),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
