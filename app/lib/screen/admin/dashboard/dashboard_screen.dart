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
    final statsAsync = ref.watch(statsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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

        final statsData = statsAsync.valueOrNull ?? {};

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(dashboardProvider.notifier).refresh(),
              ref.read(galleryPaymentsProvider.notifier).refresh(),
              ref.read(statsProvider.notifier).refresh(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(
                dashboard.gallery.name,
                style: tt.headlineSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),

              // Top metrics: artisans + products
              Row(
                children: [
                  Expanded(
                    child: _TappableMetric(
                      icon: Icons.people_alt_outlined,
                      label: 'Artesanos',
                      value: '${dashboard.activeArtisans}',
                      total: dashboard.totalArtisans,
                      onTap: () => context.go('/admin/artisans'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TappableMetric(
                      icon: Icons.inventory_2_outlined,
                      label: 'Productos',
                      value: '${dashboard.activeProducts}',
                      total: dashboard.totalProducts,
                      onTap: () => context.go('/admin/products'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Revenue card
              if (paymentsAsync.valueOrNull != null)
                _RevenueCard(
                  summary: paymentsAsync.value!.summary,
                  onTap: () => context.push('/admin/payments'),
                ),

              // Stats row — wider, single line per stat, no overflow
              if (statsData.isNotEmpty) ...[
                const SizedBox(height: 20),
                _StatsSection(stats: statsData),
              ],

              // Recent payments
              if (paymentsAsync.valueOrNull != null &&
                  paymentsAsync.value!.payments.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    Text('Pagos recientes',
                        style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/admin/payments'),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...paymentsAsync.value!.payments.take(3).map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PaymentCard(payment: p),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Tappable Metric ──────────────────────────────────────────────────────────

class _TappableMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int total;
  final VoidCallback onTap;

  const _TappableMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text(label,
                    style: tt.labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ]),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value,
                      style: tt.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700, color: cs.primary)),
                  const SizedBox(width: 4),
                  Text('/ $total',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Revenue Card ─────────────────────────────────────────────────────────────

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.payments_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text('Ingresos',
                    style: tt.labelLarge
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const Spacer(),
                if (summary.pendingCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${summary.pendingCount} pendiente${summary.pendingCount == 1 ? '' : 's'}',
                      style: tt.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ]),
              const SizedBox(height: 12),
              Text(_fmt(summary.totalSold),
                  style: tt.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
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

// ─── Stats Section ────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final earnings = (stats['gallery_earnings'] as num?)?.toInt() ?? 0;
    final completed = (stats['completed_payments'] as num?)?.toInt() ?? 0;
    final pending = (stats['pending_payments'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _Stat(label: 'Ganancias', value: '\$${(earnings / 100).toStringAsFixed(0)}'),
          _dot(cs),
          _Stat(label: 'Completados', value: '$completed'),
          _dot(cs),
          _Stat(label: 'Pendientes', value: '$pending'),
        ],
      ),
    );
  }

  Widget _dot(ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('·', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 18)),
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style:
                tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}
