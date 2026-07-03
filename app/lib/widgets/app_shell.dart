import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();

    final isRoot = location.startsWith('/explorar');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (isRoot) {
          SystemNavigator.pop();
        } else {
          context.go('/explorar');
        }
      },
      child: Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(location),
        onDestinationSelected: (l) => context.go(_routes[l]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Historial',
          ),
        ],
      ),
    ));

  }
}

const _routes = ['/explorar', '/orders'];

int _indexFor(String location) {
  if (location.startsWith('/orders')) return 1;
  return 0;
}
