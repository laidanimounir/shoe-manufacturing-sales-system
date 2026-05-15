import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../data/audit_log_model.dart';
import '../data/audit_log_repository.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});
  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  bool _isLoading = true;
  List<AuditLog> _logs = [];
  String _actionFilter = 'all';
  final _searchController = TextEditingController();
  static const _actions = {
    'all':'Tous','create':'Création','update':'Modification','delete':'Suppression','payment':'Paiement','approve':'Approbation'
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    try {
      final data = await AuditLogRepository.getAll(action: _actionFilter != 'all' ? _actionFilter : null, search: _searchController.text.isNotEmpty ? _searchController.text : null);
      if (mounted) setState(() { _logs = data; _isLoading = false; });
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); _showError('Erreur: $e'); }
    }
  }

  void _showError(String m) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
    });
  }

  Color _actionColor(String action) {
    switch (action) { case 'create': return Colors.green; case 'update': return Colors.blue; case 'delete': return Colors.red; case 'approve': return Colors.teal; case 'payment': return Colors.orange; case 'transfer': return Colors.purple; default: return Colors.grey; }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final isDark = theme.brightness == Brightness.dark; final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(title: const Text("Journal d'audit")),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(isDesktop ? 24 : 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Rechercher...', prefixIcon: const Icon(Icons.search, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(vertical: 10)), onSubmitted: (_) => _loadData()),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _actions.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(e.value),
                          selected: _actionFilter == e.key,
                          onSelected: (v) {
                            setState(() {
                              _actionFilter = e.key;
                              _isLoading = true;
                            });
                            _loadData();
                          },
                          selectedColor: theme.colorScheme.primary
                              .withValues(alpha: 0.15),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ]))),
        if (_isLoading) _buildShimmer(isDark, isDesktop)
        else if (_logs.isEmpty) _buildEmpty(theme)
        else if (isDesktop) _buildDesktop(theme, isDark) else _buildMobile(theme, isDark),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
    );
  }

  Widget _buildDesktop(ThemeData theme, bool isDark) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [DataColumn(label: Text('Utilisateur')), DataColumn(label: Text('Action')), DataColumn(label: Text('Table')), DataColumn(label: Text('Description')), DataColumn(label: Text('Date'))], rows: _logs.map((l) => DataRow(cells: [
    DataCell(Text(l.userName, style: const TextStyle(fontWeight: FontWeight.w600))),
    DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _actionColor(l.action).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(l.actionLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _actionColor(l.action))))),
    DataCell(Text(l.tableName, style: theme.textTheme.bodySmall)),
    DataCell(Text(l.description, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
    DataCell(Text(l.formattedDate, style: GoogleFonts.jetBrainsMono(fontSize: 11))),
  ])).toList())))));

  Widget _buildMobile(ThemeData theme, bool isDark) => SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
    final l = _logs[i];
    return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)), child: ListTile(dense: true, title: Text(l.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2), subtitle: Text('${l.userName} | ${l.tableName} | ${l.formattedDate}', style: theme.textTheme.labelSmall), leading: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _actionColor(l.action).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(l.actionLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _actionColor(l.action))))));
  }, childCount: _logs.length)));

  Widget _buildEmpty(ThemeData theme) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 48), child: Center(child: Column(children: [Icon(Icons.history, size: 48, color: theme.textTheme.bodySmall?.color), const SizedBox(height: 12), Text('Aucune activité enregistrée', style: theme.textTheme.titleMedium)]))));

  Widget _buildShimmer(bool isDark, bool isDesktop) => SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8), highlightColor: isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA), child: Padding(padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16), child: Column(children: List.generate(5, (_) => Container(margin: const EdgeInsets.only(bottom: 8), height: 56, decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : AppColors.lightSurface, borderRadius: BorderRadius.circular(8))))))));
}
