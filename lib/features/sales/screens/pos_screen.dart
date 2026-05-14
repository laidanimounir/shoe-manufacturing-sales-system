import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/product_search_service.dart';
import '../data/invoice_repository.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _CartItem {
  String productId;
  String productName;
  String? sku;
  String sourceType;
  double unitCost;
  int quantity;
  double unitPrice;
  int stockAvailable;

  _CartItem({
    required this.productId,
    required this.productName,
    this.sku,
    this.sourceType = 'manufactured',
    this.unitCost = 0,
    this.quantity = 1,
    this.unitPrice = 0,
    this.stockAvailable = 0,
  });

  double get subtotal => quantity * unitPrice;
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  final _paidController = TextEditingController();
  List<SaleProduct> _products = [];
  final List<_CartItem> _cart = [];
  String _sourceFilter = 'all';
  String? _selectedWarehouseId;
  String? _selectedClientId;
  String _saleType = 'cash';
  String _paymentMethod = 'cash';
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _clients = [];
  bool _isSearching = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final client = SupabaseService.client;
    final results = await Future.wait([
      client.from('warehouses').select('id, name').eq('is_active', true).order('name'),
      client.from('clients').select('id, name').order('name'),
    ]);
    if (mounted) {
      setState(() {
        _warehouses = List<Map<String, dynamic>>.from(results[0] as List);
        _clients = List<Map<String, dynamic>>.from(results[1] as List);
        if (_warehouses.isNotEmpty) _selectedWarehouseId = _warehouses.first['id'] as String;
      });
    }
  }

  Future<void> _search() async {
    if (_selectedWarehouseId == null) return;
    setState(() => _isSearching = true);
    try {
      final results = await ProductSearchService.searchForSale(
        warehouseId: _selectedWarehouseId!,
        query: _searchController.text,
      );
      if (mounted) {
        setState(() {
          _products = _sourceFilter == 'all'
              ? results
              : results.where((p) => p.sourceType == _sourceFilter).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addToCart(SaleProduct p) {
    final existingIdx = _cart.indexWhere((c) => c.productId == p.id);
    if (existingIdx >= 0) {
      if (_cart[existingIdx].quantity < p.availableQty) {
        setState(() => _cart[existingIdx].quantity++);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock insuffisant'), behavior: SnackBarBehavior.floating));
        }
      }
    } else {
      setState(() {
        _cart.add(_CartItem(
          productId: p.id,
          productName: p.name,
          sku: p.sku,
          sourceType: p.sourceType,
          unitCost: p.unitCost,
          quantity: 1,
          unitPrice: p.sellingPrice,
          stockAvailable: p.availableQty,
        ));
      });
    }
  }

  void _removeFromCart(int index) => setState(() => _cart.removeAt(index));

  double get _cartTotal => _cart.fold(0.0, (s, c) => s + c.subtotal);

  double get _paidAmount {
    return double.tryParse(_paidController.text.replaceAll(',', '.')) ?? 0;
  }

  double get _remainingDebt => _cartTotal - _paidAmount;

  Future<void> _confirmSale() async {
    if (_cart.isEmpty) { _showError('Le panier est vide'); return; }
    if (_selectedWarehouseId == null) { _showError('Sélectionnez un dépôt'); return; }
    if (_remainingDebt > 0 && _selectedClientId == null) {
      _showError('Sélectionnez un client pour une vente à crédit');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la vente'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_cart.length} article${_cart.length > 1 ? 's' : ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Total: ${CurrencyFormatter.format(_cartTotal)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('Payé: ${CurrencyFormatter.format(_paidAmount)}'),
          if (_remainingDebt > 0) Text('Reste: ${CurrencyFormatter.format(_remainingDebt)}', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          Text('Client: ${_clientName()}', style: const TextStyle(fontSize: 13)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isSaving = true);

    try {
      final items = _cart.map((c) => {
        'product_id': c.productId,
        'source_type': c.sourceType,
        'quantity': c.quantity,
        'unit_price': c.unitPrice,
        'unit_cost': c.unitCost,
      }).toList();

      await InvoiceRepository.create(
        warehouseId: _selectedWarehouseId,
        clientId: _selectedClientId,
        saleType: _saleType,
        totalAmount: _cartTotal,
        initialPayment: _paidAmount,
        paymentMethod: _paidAmount > 0 ? _paymentMethod : null,
        items: items,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vente enregistrée ✓'), behavior: SnackBarBehavior.floating));
        _showPrintDialog();
      }
    } catch (e) {
      if (mounted) { setState(() => _isSaving = false); _showError('Erreur: $e'); }
    }
  }

  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Impression'),
        content: const Text('Vente enregistrée avec succès.\n\nL\'impression sera disponible dans une prochaine mise à jour.'),
        actions: [
          FilledButton(onPressed: () { Navigator.of(ctx).pop(); _clearCart(); }, child: const Text('OK')),
        ],
      ),
    );
  }

  void _clearCart() {
    setState(() { _cart.clear(); _paidController.clear(); _saleType = 'cash'; _selectedClientId = null; });
  }

  String _clientName() {
    if (_selectedClientId == null) return 'Au comptoir';
    final c = _clients.firstWhere((c) => c['id'] == _selectedClientId, orElse: () => {'name': 'Inconnu'});
    return c['name'] as String? ?? 'Inconnu';
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18), const SizedBox(width: 8), Expanded(child: Text(msg))]), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Point de vente'), automaticallyImplyLeading: false, actions: [
        DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: _selectedWarehouseId,
          style: theme.textTheme.bodySmall,
          items: _warehouses.map((w) => DropdownMenuItem(value: w['id'] as String, child: Text(w['name'] as String, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) { setState(() { _selectedWarehouseId = v; _products.clear(); }); },
        )),
        const SizedBox(width: 16),
      ]),
      body: isDesktop ? _buildDesktopLayout(theme, isDark) : _buildMobileLayout(theme, isDark),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, bool isDark) {
    return Row(children: [
      Expanded(flex: 5, child: _buildProductPanel(theme, isDark)),
      Container(width: 1, color: theme.colorScheme.outline),
      Expanded(flex: 4, child: _buildCartPanel(theme, isDark)),
    ]);
  }

  Widget _buildProductPanel(ThemeData theme, bool isDark) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(children: [
          Expanded(child: TextField(
            controller: _searchController, autofocus: true,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, SKU ou scanner code-barres...', prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.qr_code_scanner, size: 20), tooltip: 'Scanner', onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanner bientôt disponible'), behavior: SnackBarBehavior.floating)); }),
                if (_searchController.text.isNotEmpty) IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); }),
              ]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: theme.textTheme.bodyMedium,
            onSubmitted: (_) => _search(),
          )),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: _search, icon: const Icon(Icons.search, size: 18), label: const Text('Chercher')),
        ]),
        const SizedBox(height: 8),
        _buildSourceFilter(theme),
      ])),
      Expanded(child: _isSearching ? const Center(child: CircularProgressIndicator()) : _products.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_outlined, size: 48, color: theme.textTheme.bodySmall?.color), const SizedBox(height: 8), Text('Recherchez un produit', style: theme.textTheme.bodySmall)])) : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.9, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: _products.length,
        itemBuilder: (ctx, i) => _buildProductCard(_products[i], theme, isDark),
      )),
    ]);
  }

  Widget _buildSourceFilter(ThemeData theme) => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
    children: const [{'k': 'all', 'l': 'Tous'}, {'k': 'manufactured', 'l': 'Fabriqué'}, {'k': 'purchased', 'l': 'Acheté'}].map((e) {
      final sel = _sourceFilter == e['k'];
      return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(e['l']!), selected: sel, onSelected: (v) { setState(() => _sourceFilter = e['k']!); _search(); }, selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15), checkmarkColor: theme.colorScheme.primary));
    }).toList(),
  ));

  Widget _buildProductCard(SaleProduct p, ThemeData theme, bool isDark) {
    final stockColor = p.availableQty > 10 ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess) : p.availableQty > 0 ? (isDark ? AppColors.darkWarning : AppColors.lightWarning) : (isDark ? AppColors.darkError : AppColors.lightError);
    return Container(
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: p.availableQty == 0 ? stockColor : theme.colorScheme.outline)),
      child: InkWell(borderRadius: BorderRadius.circular(8), onTap: p.availableQty > 0 ? () => _addToCart(p) : null, child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: stockColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text('${p.availableQty}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stockColor))),
        ]),
        const SizedBox(height: 4),
        Text('SKU: ${p.sku ?? '-'}', style: theme.textTheme.labelSmall),
        Text(p.sourceType == 'manufactured' ? '🏭 Fabriqué' : '🛒 Acheté', style: const TextStyle(fontSize: 11)),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(CurrencyFormatter.format(p.sellingPrice), style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700)),
          Icon(Icons.add_circle_outline, size: 22, color: p.availableQty > 0 ? theme.colorScheme.primary : theme.colorScheme.outline),
        ]),
      ]))),
    );
  }

  Widget _buildCartPanel(ThemeData theme, bool isDark) {
    final total = _cartTotal;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Text('Panier', style: theme.textTheme.titleMedium),
        const Spacer(),
        if (_cart.isNotEmpty) TextButton.icon(onPressed: _clearCart, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Vider'), style: TextButton.styleFrom(foregroundColor: isDark ? AppColors.darkError : AppColors.lightError)),
      ])),
      Expanded(child: _cart.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_cart_outlined, size: 48, color: theme.textTheme.bodySmall?.color), const SizedBox(height: 8), Text('Panier vide', style: theme.textTheme.bodySmall)])) : ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _cart.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _buildCartItem(i, theme, isDark),
      )),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outline))), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total HT', style: theme.textTheme.titleSmall), Text(CurrencyFormatter.format(total), style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _paidController, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Montant payé', prefixText: 'DZD ', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14),
          )),
          const SizedBox(width: 8),
          if (_paidAmount > 0) DropdownButton<String>(
            value: _paymentMethod,
            items: const [DropdownMenuItem(value: 'cash', child: Text('💵')), DropdownMenuItem(value: 'bank', child: Text('🏦')), DropdownMenuItem(value: 'cheque', child: Text('📋'))],
            onChanged: (v) => setState(() => _paymentMethod = v!),
            underline: const SizedBox.shrink(),
          ),
        ]),
        if (_remainingDebt > 0) Padding(padding: const EdgeInsets.only(top: 4), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Reste dû: ${CurrencyFormatter.format(_remainingDebt)}', style: TextStyle(color: isDark ? AppColors.darkError : AppColors.lightError, fontWeight: FontWeight.w600))])),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedClientId,
          decoration: const InputDecoration(labelText: 'Client', prefixIcon: Icon(Icons.person, size: 20), border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Vente au comptoir')),
            ..._clients.map((c) => DropdownMenuItem<String>(value: c['id'] as String, child: Text(c['name'] as String))),
          ],
          onChanged: (v) => setState(() { _selectedClientId = v; if (v == null) { _saleType = 'cash'; _paidController.text = total.toString(); } else { _saleType = 'credit'; } }),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(onPressed: _isSaving ? null : _confirmSale, icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle, size: 20), label: Text(_isSaving ? 'Traitement...' : 'Confirmer la vente'))),
      ])),
    ]);
  }

  Widget _buildCartItem(int index, ThemeData theme, bool isDark) {
    final item = _cart[index];
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8FA), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        IconButton(icon: Icon(Icons.delete_outline, size: 18, color: isDark ? AppColors.darkError : AppColors.lightError), onPressed: () => _removeFromCart(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        IconButton(icon: const Icon(Icons.remove_circle_outline, size: 22), onPressed: () { if (item.quantity > 1) setState(() => item.quantity--); }, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        IconButton(icon: const Icon(Icons.add_circle_outline, size: 22), onPressed: () { if (item.quantity < item.stockAvailable) setState(() => item.quantity++); else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock insuffisant'), behavior: SnackBarBehavior.floating)); }, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        const Spacer(),
        Expanded(child: TextFormField(
          initialValue: '${item.unitPrice}',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
          style: const TextStyle(fontSize: 12),
          onChanged: (v) => setState(() => item.unitPrice = double.tryParse(v.replaceAll(',', '.')) ?? 0),
        )),
        const SizedBox(width: 8),
        Text(CurrencyFormatter.formatCompact(item.subtotal), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ]));
  }

  Widget _buildMobileLayout(ThemeData theme, bool isDark) {
    return Stack(children: [
      _buildProductPanel(theme, isDark),
      if (_cart.isNotEmpty) Positioned(bottom: 16, right: 16, child: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: _buildCartPanel(theme, isDark))),
        icon: Badge(label: Text('${_cart.length}'), child: const Icon(Icons.shopping_cart)),
        label: Text(CurrencyFormatter.format(_cartTotal)),
      )),
    ]);
  }
}
