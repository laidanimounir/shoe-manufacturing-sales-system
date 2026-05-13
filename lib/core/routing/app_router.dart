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

final routerProvider = Provider<GoRouter>((ref) {
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
            builder: (context, state) => const WarehouseFormScreen(),
          ),
          GoRoute(
            path: '/warehouses/:id',
            name: 'warehouse-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return WarehouseDetailScreen(warehouseId: id);
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
      icon: Icon(Icons.precision_manufacturing_outlined),
      selectedIcon: Icon(Icons.precision_manufacturing),
      label: Text('Production'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.local_shipping_outlined),
      selectedIcon: Icon(Icons.local_shipping),
      label: Text('Fournisseurs'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale),
      label: Text('Ventes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
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
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: 'Ventes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Stock',
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
