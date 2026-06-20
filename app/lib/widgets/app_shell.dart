import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(_titleFor(location)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outlined),
            onPressed: () => context.go('/account'),
            tooltip: 'Cuenta',
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(location),
        onDestinationSelected: (l) => context.go(_routes[l]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}

const _routes = ['/explorar', '/orders', '/account'];

int _indexFor(String location) {
  if (location.startsWith('/orders')) return 1;
  if (location.startsWith('/account')) return 2;
  return 0;
}

String _titleFor(String location) {
  if (location.startsWith('/explorar')) return 'Explorar';
  if (location.startsWith('/orders')) return 'Historial';
  if (location.startsWith('/account')) return 'Cuenta';
  return 'Gallery';
}
