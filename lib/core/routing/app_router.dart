import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/owner_dashboard.dart';
import '../../features/warehouses/screens/warehouse_list_screen.dart';
import '../../features/warehouses/screens/warehouse_form_screen.dart';
import '../../features/warehouses/screens/warehouse_detail_screen.dart';
import '../../features/warehouses/data/warehouse_model.dart';
import '../../features/inventory/screens/product_list_screen.dart';
import '../../features/inventory/screens/product_form_screen.dart';
import '../../features/inventory/screens/product_detail_screen.dart';
import '../../features/inventory/screens/raw_material_list_screen.dart';
import '../../features/inventory/screens/raw_material_form_screen.dart';
import '../../features/inventory/data/product_model.dart';
import '../../features/inventory/data/raw_material_model.dart';
import '../../features/production/screens/production_order_list_screen.dart';
import '../../features/production/screens/production_order_form_screen.dart';
import '../../features/production/screens/production_order_detail_screen.dart';
import '../../features/production/screens/production_log_screen.dart';
import '../../features/production/screens/production_stock_entry_screen.dart';
import '../../features/production/screens/recipe_list_screen.dart';
import '../../features/production/screens/recipe_form_screen.dart';
import '../../features/production/data/recipe_model.dart';
import '../../features/suppliers/screens/supplier_list_screen.dart';
import '../../features/suppliers/screens/supplier_form_screen.dart';
import '../../features/suppliers/screens/supplier_detail_screen.dart';
import '../../features/suppliers/screens/purchase_order_list_screen.dart';
import '../../features/suppliers/screens/purchase_order_form_screen.dart';
import '../../features/suppliers/screens/purchase_order_detail_screen.dart';
import '../../features/suppliers/screens/supplier_payment_screen.dart';
import '../../features/suppliers/data/supplier_model.dart';
import '../../features/suppliers/data/purchase_order_model.dart';
import '../../features/sales/screens/client_list_screen.dart';
import '../../features/sales/screens/client_form_screen.dart';
import '../../features/sales/screens/client_detail_screen.dart';
import '../../features/sales/screens/pos_screen.dart';
import '../../features/sales/screens/invoice_list_screen.dart';
import '../../features/sales/screens/invoice_detail_screen.dart';
import '../../features/sales/screens/payment_screen.dart';
import '../../features/sales/data/client_model.dart';
import '../../features/sales/data/invoice_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
    ref.keepAlive();
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const OwnerDashboard(),
          ),
          GoRoute(
            path: '/warehouses',
            name: 'warehouses',
            builder: (context, state) => const WarehouseListScreen(),
          ),
          GoRoute(
            path: '/warehouses/new',
            name: 'warehouse-new',
            builder: (context, state) =>
                WarehouseFormScreen(warehouse: state.extra as Warehouse?),
          ),
          GoRoute(
            path: '/warehouses/:id',
            name: 'warehouse-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return WarehouseDetailScreen(warehouseId: id);
            },
          ),
          GoRoute(
            path: '/products',
            name: 'products',
            builder: (context, state) => const ProductListScreen(),
          ),
          GoRoute(
            path: '/products/new',
            name: 'product-new',
            builder: (context, state) =>
                ProductFormScreen(product: state.extra as Product?),
          ),
          GoRoute(
            path: '/products/:id',
            name: 'product-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductDetailScreen(productId: id);
            },
          ),
          GoRoute(
            path: '/raw-materials',
            name: 'raw-materials',
            builder: (context, state) => const RawMaterialListScreen(),
          ),
          GoRoute(
            path: '/raw-materials/new',
            name: 'raw-material-new',
            builder: (context, state) =>
                RawMaterialFormScreen(material: state.extra as RawMaterial?),
          ),
          GoRoute(
            path: '/production',
            name: 'production',
            builder: (context, state) => const ProductionOrderListScreen(),
          ),
          GoRoute(
            path: '/production/new',
            name: 'production-new',
            builder: (context, state) => const ProductionOrderFormScreen(),
          ),
          GoRoute(
            path: '/production/:id',
            name: 'production-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductionOrderDetailScreen(orderId: id);
            },
          ),
          GoRoute(
            path: '/production/:id/log',
            name: 'production-log',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductionLogScreen(orderId: id);
            },
          ),
          GoRoute(
            path: '/production/:id/entry',
            name: 'production-entry',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductionStockEntryScreen(orderId: id);
            },
          ),
          GoRoute(
            path: '/recipes',
            name: 'recipes',
            builder: (context, state) => const RecipeListScreen(),
          ),
          GoRoute(
            path: '/recipes/new',
            name: 'recipe-new',
            builder: (context, state) =>
                RecipeFormScreen(recipe: state.extra as Recipe?),
          ),
          GoRoute(
            path: '/suppliers',
            name: 'suppliers',
            builder: (context, state) => const SupplierListScreen(),
          ),
          GoRoute(
            path: '/suppliers/new',
            name: 'supplier-new',
            builder: (context, state) =>
                SupplierFormScreen(supplier: state.extra as Supplier?),
          ),
          GoRoute(
            path: '/suppliers/:id',
            name: 'supplier-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SupplierDetailScreen(supplierId: id);
            },
          ),
          GoRoute(
            path: '/purchases',
            name: 'purchases',
            builder: (context, state) => const PurchaseOrderListScreen(),
          ),
          GoRoute(
            path: '/purchases/new',
            name: 'purchase-new',
            builder: (context, state) => const PurchaseOrderFormScreen(),
          ),
          GoRoute(
            path: '/purchases/:id',
            name: 'purchase-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PurchaseOrderDetailScreen(orderId: id);
            },
          ),
          GoRoute(
            path: '/purchases/:id/payment',
            name: 'purchase-payment',
            builder: (context, state) {
              final order = state.extra as PurchaseOrder;
              return SupplierPaymentScreen(order: order);
            },
          ),
          GoRoute(
            path: '/clients',
            name: 'clients',
            builder: (context, state) => const ClientListScreen(),
          ),
          GoRoute(
            path: '/clients/new',
            name: 'client-new',
            builder: (context, state) =>
                ClientFormScreen(client: state.extra as Client?),
          ),
          GoRoute(
            path: '/clients/:id',
            name: 'client-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ClientDetailScreen(clientId: id);
            },
          ),
          GoRoute(
            path: '/sales',
            name: 'sales',
            builder: (context, state) => const InvoiceListScreen(),
          ),
          GoRoute(
            path: '/sales/new',
            name: 'sale-new',
            builder: (context, state) => const PosScreen(),
          ),
          GoRoute(
            path: '/sales/:id',
            name: 'sale-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InvoiceDetailScreen(invoiceId: id);
            },
          ),
          GoRoute(
            path: '/sales/:id/payment',
            name: 'sale-payment',
            builder: (context, state) {
              final inv = state.extra as Invoice;
              return PaymentScreen(invoice: inv);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = SupabaseService.isAuthenticated;
      final isOnSplash = state.matchedLocation == '/';
      final isOnLogin = state.matchedLocation == '/login';

      if (isOnSplash) return null;
      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && isOnLogin) return '/dashboard';
      return null;
    },
  );
});

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return _DesktopShell(child: child);
    }
    return _MobileShell(child: child);
  }
}

class _DesktopShell extends StatefulWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  bool _isCollapsed = false;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/warehouses')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/raw-materials')) return 3;
    if (location.startsWith('/production')) return 4;
    if (location.startsWith('/recipes')) return 5;
    if (location.startsWith('/suppliers')) return 6;
    if (location.startsWith('/purchases')) return 7;
    if (location.startsWith('/sales')) return 8;
    if (location.startsWith('/clients')) return 9;
    return 0;
  }

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Tableau de bord'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.warehouse_outlined),
      selectedIcon: Icon(Icons.warehouse),
      label: Text('Dépôts'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: Text('Produits'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.category_outlined),
      selectedIcon: Icon(Icons.category),
      label: Text('Matières'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.precision_manufacturing_outlined),
      selectedIcon: Icon(Icons.precision_manufacturing),
      label: Text('Production'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: Text('Recettes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.local_shipping_outlined),
      selectedIcon: Icon(Icons.local_shipping),
      label: Text('Fournisseurs'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.shopping_cart_outlined),
      selectedIcon: Icon(Icons.shopping_cart),
      label: Text('Achats'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale),
      label: Text('Ventes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: Text('Clients'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.badge_outlined),
      selectedIcon: Icon(Icons.badge),
      label: Text('Employés'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_balance_outlined),
      selectedIcon: Icon(Icons.account_balance),
      label: Text('Finance'),
    ),
  ];

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/warehouses');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/raw-materials');
        break;
      case 4:
        context.go('/production');
        break;
      case 5:
        context.go('/recipes');
        break;
      case 6:
        context.go('/suppliers');
        break;
      case 7:
        context.go('/purchases');
        break;
      case 8:
        context.go('/sales');
        break;
      case 9:
        context.go('/clients');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline;

    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: borderColor),
              ),
            ),
            child: NavigationRail(
              extended: !_isCollapsed,
              minExtendedWidth: 240,
              minWidth: 64,
              selectedIndex: _selectedIndex(context),
              onDestinationSelected: _onDestinationSelected,
              leading: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: _isCollapsed ? 8 : 16,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.storefront,
                            size: 18,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        if (!_isCollapsed) ...[
                          const SizedBox(width: 10),
                          Text(
                            'ShoeTrak',
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: Icon(
                        _isCollapsed
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _isCollapsed = !_isCollapsed);
                      },
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: const Icon(Icons.logout, size: 20),
                      tooltip: 'Déconnexion',
                      onPressed: () async {
                        await SupabaseService.signOut();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ),
                ),
              ),
              destinations: _destinations,
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/raw-materials')) return 2;
    if (location.startsWith('/production')) return 3;
    if (location.startsWith('/recipes')) return 4;
    return 0;
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Recettes'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/recipes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Fournisseurs'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/suppliers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Bons de commande'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/purchases');
              },
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale_outlined),
              title: const Text('Ventes'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/sales');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Clients'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/clients');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/products');
              break;
            case 2:
              context.go('/raw-materials');
              break;
            case 3:
              context.go('/production');
              break;
            case 4:
              _showMoreSheet(context);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Matières',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing_outlined),
            activeIcon: Icon(Icons.precision_manufacturing),
            label: 'Production',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Plus',
          ),
        ],
      ),
    );
  }
}
