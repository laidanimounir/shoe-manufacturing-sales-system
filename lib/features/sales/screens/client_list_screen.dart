import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/client_repository.dart';
import '../data/client_model.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Client> _clients = [];
  String _searchText = '';
  String _typeFilter = 'all';

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
      final data = await ClientRepository.getAll(
        search: _searchText.isNotEmpty ? _searchText : null,
        clientType: _typeFilter != 'all' ? _typeFilter : null,
      );
      if (mounted) {
        setState(() {
          _clients = data;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18),
          const SizedBox(width: 8), Expanded(child: Text(message)),
        ]),
        behavior: SnackBarBehavior.floating,
      ));
    });
  }

  void _onAdd() => context.push('/clients/new').then((_) => _loadData());
  void _onEdit(Client c) => context.push('/clients/new', extra: c).then((_) => _loadData());
  void _onDetail(Client c) => context.push('/clients/${c.id}').then((_) => _loadData());

  void _confirmDelete(Client c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer le client "${c.fullName}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              try { await ClientRepository.delete(c.id, c.fullName); if (ctx.mounted) Navigator.of(ctx).pop(); await _loadData(); }
              catch (e) { _showError('Erreur: $e'); }
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

    return Scaffold(
      body: CallbackShortcuts(
        bindings: { if (isDesktop) const SingleActivator(LogicalKeyboardKey.keyN, control: true): _onAdd },
        child: Focus(
          autofocus: true,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Clients', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text('Gestion des clients', style: theme.textTheme.bodySmall),
                      ])),
                      if (isDesktop)
                        OutlinedButton.icon(onPressed: _onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Nouveau client'))
                      else
                        IconButton.filled(onPressed: _onAdd, icon: const Icon(Icons.add), tooltip: 'Nouveau client'),
                    ]),
                    const SizedBox(height: 16),
                    _buildSearchBar(theme),
                    const SizedBox(height: 12),
                    _buildTypeFilter(theme),
                  ]),
                ),
              ),
              if (_isLoading) _buildShimmerList(isDark, isDesktop)
              else if (_clients.isEmpty) _buildEmptyState(theme)
              else if (isDesktop) _buildDesktopTable(theme, isDark)
              else _buildMobileCards(theme, isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) => Container(
    decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)),
    child: TextField(
      controller: _searchController,
      onChanged: (_) { setState(() => _searchText = _searchController.text); _loadData(); },
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Rechercher un client...', hintStyle: theme.textTheme.bodySmall,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchText.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchText = ''); _loadData(); }) : null,
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );

  Widget _buildTypeFilter(ThemeData theme) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
    children: [
      {'key': 'all', 'label': 'Tous'},
      {'key': 'wholesale', 'label': 'Grossiste'},
      {'key': 'retail', 'label': 'Détaillant'},
    ].map((e) {
      final selected = _typeFilter == e['key'];
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(label: Text(e['label']!), selected: selected, onSelected: (v) { setState(() { _typeFilter = e['key']!; _isLoading = true; }); _loadData(); },
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15), checkmarkColor: theme.colorScheme.primary),
      );
    }).toList(),
  ));

  Widget _buildDesktopTable(ThemeData theme, bool isDark) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(
    decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: Text('${_clients.length} client${_clients.length > 1 ? 's' : ''}', style: theme.textTheme.labelLarge)),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 20, dataRowMinHeight: 44, dataRowMaxHeight: 44, headingRowHeight: 36,
        columns: const [DataColumn(label: Text('Nom')), DataColumn(label: Text('Téléphone')), DataColumn(label: Text('Ville')), DataColumn(label: Text('Type')), DataColumn(label: Text('Dette'), numeric: true), DataColumn(label: Text('Actions'))],
        rows: _clients.map((c) => DataRow(onSelectChanged: (_) => _onDetail(c), cells: [
          DataCell(Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(c.phone ?? '-', style: theme.textTheme.bodySmall)),
          DataCell(Text(c.city ?? '-', style: theme.textTheme.bodySmall)),
          DataCell(_typeChip(c.clientTypeLabel, isDark)),
          DataCell(Text(CurrencyFormatter.format(c.totalDebt), style: GoogleFonts.jetBrainsMono(fontSize: 12, color: c.totalDebt > 0 ? (isDark ? AppColors.darkError : AppColors.lightError) : null))),
          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), tooltip: 'Détails', onPressed: () => _onDetail(c)),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Modifier', onPressed: () => _onEdit(c)),
            IconButton(icon: Icon(Icons.delete_outline, size: 18, color: isDark ? AppColors.darkError : AppColors.lightError), tooltip: 'Supprimer', onPressed: () => _confirmDelete(c)),
          ])),
        ])).toList(),
      )),
    ]),
  )));

  Widget _buildMobileCards(ThemeData theme, bool isDark) => SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList(delegate: SliverChildBuilderDelegate(
    (context, index) {
      final c = _clients[index];
      return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.outline)),
        child: InkWell(borderRadius: BorderRadius.circular(8), onTap: () => _onDetail(c), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person, size: 20, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.fullName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(children: [Text(c.phone ?? '-', style: theme.textTheme.labelSmall), const SizedBox(width: 8), Text(c.clientTypeLabel, style: theme.textTheme.labelSmall)]),
          ])),
          if (c.totalDebt > 0) Text(CurrencyFormatter.format(c.totalDebt), style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? AppColors.darkError : AppColors.lightError)),
          const SizedBox(width: 4),
          PopupMenuButton<String>(icon: const Icon(Icons.more_vert, size: 20),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('Détails')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Modifier')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
            ],
            onSelected: (v) { if (v == 'detail') { _onDetail(c); } else if (v == 'edit') { _onEdit(c); } else if (v == 'delete') { _confirmDelete(c); } },
          ),
        ]))),
      );
    },
    childCount: _clients.length,
  )));

  Widget _typeChip(String label, bool isDark) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: (isDark ? AppColors.darkInfo : AppColors.lightInfo).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkInfo : AppColors.lightInfo)));

  Widget _buildEmptyState(ThemeData theme) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 48), child: Center(child: Column(children: [
    Icon(Icons.people_outline, size: 48, color: theme.textTheme.bodySmall?.color), const SizedBox(height: 12),
    Text('Aucun client', style: theme.textTheme.titleMedium), const SizedBox(height: 4),
    Text('Ajoutez votre premier client', style: theme.textTheme.bodySmall), const SizedBox(height: 16),
    OutlinedButton.icon(onPressed: _onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Nouveau client')),
  ]))));

  Widget _buildShimmerList(bool isDark, bool isDesktop) {
    final baseColor = isDark ? const Color(0xFF21262D) : const Color(0xFFE1E4E8);
    final highlightColor = isDark ? const Color(0xFF30363D) : const Color(0xFFF6F8FA);
    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
          child: Column(
            children: List.generate(5, (i) => Container(
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
