import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();

    final isRoot = location.startsWith('/admin/dashboard');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (isRoot) {
          SystemNavigator.pop();
        } else {
          context.go('/admin/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indexFor(location),
          onDestinationSelected: (i) => context.go(_routes[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outlined),
              selectedIcon: Icon(Icons.people),
              label: 'Artesanos',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Productos',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}

const _routes = [
  '/admin/dashboard',
  '/admin/artisans',
  '/admin/products',
  '/admin/settings',
];

int _indexFor(String location) {
  if (location.startsWith('/admin/artisans')) return 1;
  if (location.startsWith('/admin/products')) return 2;
  if (location.startsWith('/admin/settings')) return 3;
  return 0;
}
