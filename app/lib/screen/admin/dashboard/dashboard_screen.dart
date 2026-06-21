import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/providers/admin_provider.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';
import 'package:openpayments_app/widgets/app_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final cs = Theme.of(context).colorScheme;

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorState(
        message: 'No se pudo cargar el dashboard',
        onRetry: () => ref.invalidate(dashboardProvider),
      ),
      data: (dashboard) {
        if (dashboard == null) {
          return const AppErrorState(message: 'No hay galería disponible');
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                dashboard.gallery.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: _MetricTile(
                        icon: Icons.people,
                        label: 'Artesanos',
                        value: '${dashboard.activeArtisans} / ${dashboard.totalArtisans}',
                        subtitle: 'activos / total',
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: _MetricTile(
                        icon: Icons.inventory_2,
                        label: 'Productos',
                        value: '${dashboard.activeProducts} / ${dashboard.totalProducts}',
                        subtitle: 'activos / total',
                        color: cs.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppCard(
                child: _MetricTile(
                  icon: Icons.inventory_2,
                  label: 'Productos',
                  value: '${dashboard.activeProducts} / ${dashboard.totalProducts}',
                  subtitle: 'activos / total',
                  color: cs.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
