import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/payment.dart';
import 'package:openpayments_app/providers/admin_provider.dart';
import 'package:openpayments_app/providers/payments_provider.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';
import 'package:openpayments_app/widgets/payment_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).refresh();
      ref.read(galleryPaymentsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final paymentsAsync = ref.watch(galleryPaymentsProvider);
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
          onRefresh: () async {
            await Future.wait([
              ref.read(dashboardProvider.notifier).refresh(),
              ref.read(galleryPaymentsProvider.notifier).refresh(),
            ]);
          },
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
                    child: _MetricCard(
                      icon: Icons.people,
                      label: 'Artesanos',
                      value:
                          '${dashboard.activeArtisans} / ${dashboard.totalArtisans}',
                      subtitle: 'activos / total',
                      color: cs.primary,
                      onTap: () => context.go('/admin/artisans'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.inventory_2,
                      label: 'Productos',
                      value:
                          '${dashboard.activeProducts} / ${dashboard.totalProducts}',
                      subtitle: 'activos / total',
                      color: cs.primary,
                      onTap: () => context.go('/admin/products'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (paymentsAsync.valueOrNull != null) ...[
                _RevenueCard(
                  summary: paymentsAsync.value!.summary,
                  onTap: () => context.push('/admin/payments'),
                ),
                if (paymentsAsync.value!.payments.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Pagos recientes',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/admin/payments'),
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...paymentsAsync.value!.payments
                      .take(3)
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PaymentCard(payment: p),
                        ),
                      ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Card de ingresos: total vendido como número principal, la comisión de la
/// galería como secundario. Tap → historial completo de pagos.
class _RevenueCard extends StatelessWidget {
  final GalleryPaymentsSummary summary;
  final VoidCallback onTap;

  const _RevenueCard({required this.summary, required this.onTap});

  String _fmt(int minorUnits) {
    final amount = minorUnits / pow(10, summary.assetScale);
    return '${summary.assetCode} ${amount.toStringAsFixed(summary.assetScale)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payments_outlined, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Ingresos',
                    style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (summary.pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${summary.pendingCount} pendiente${summary.pendingCount == 1 ? '' : 's'}',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _fmt(summary.totalSold),
                style: tt.headlineMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tu comisión: ${_fmt(summary.galleryEarned)} · ${summary.completedCount} venta${summary.completedCount == 1 ? '' : 's'}',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
