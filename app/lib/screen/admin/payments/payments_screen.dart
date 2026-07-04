import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/models/payment.dart';
import 'package:openpayments_app/providers/payments_provider.dart';
import 'package:openpayments_app/widgets/app_empty_state.dart';
import 'package:openpayments_app/widgets/app_error_state.dart';
import 'package:openpayments_app/widgets/payment_card.dart';

/// Historial de pagos de la galería para el operador: resumen de ingresos
/// arriba, filtros por estado, y la lista de pagos con su split.
class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

enum _StatusFilter { all, completed, pending, failed }

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  _StatusFilter _filter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryPaymentsProvider.notifier).refresh();
    });
  }

  List<Payment> _filtered(List<Payment> payments) {
    switch (_filter) {
      case _StatusFilter.all:
        return payments;
      case _StatusFilter.completed:
        return payments.where((p) => p.status == 'completed').toList();
      case _StatusFilter.pending:
        return payments.where((p) => p.status == 'pending').toList();
      case _StatusFilter.failed:
        return payments
            .where((p) => p.status != 'completed' && p.status != 'pending')
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paymentsAsync = ref.watch(galleryPaymentsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Pagos'), scrolledUnderElevation: 0.5),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AppErrorState(
          message: 'No se pudieron cargar los pagos.',
          onRetry: () => ref.invalidate(galleryPaymentsProvider),
        ),
        data: (data) {
          if (data.payments.isEmpty) {
            return const AppEmptyState(
              icon: Icons.payments_outlined,
              title: 'Aún no hay ventas',
              description:
                  'Los pagos aparecerán aquí cuando un comprador pague un producto de tu galería.',
            );
          }

          final filtered = _filtered(data.payments);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(galleryPaymentsProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: _SummaryHeader(summary: data.summary),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        _filterChip('Todos', _StatusFilter.all),
                        const SizedBox(width: 8),
                        _filterChip('Completados', _StatusFilter.completed),
                        const SizedBox(width: 8),
                        _filterChip('Pendientes', _StatusFilter.pending),
                        const SizedBox(width: 8),
                        _filterChip('Fallidos', _StatusFilter.failed),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Sin pagos con este estado.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => PaymentCard(payment: filtered[i]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, _StatusFilter value) {
    return FilterChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
      showCheckmark: false,
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final GalleryPaymentsSummary summary;
  const _SummaryHeader({required this.summary});

  String _fmt(int minorUnits) {
    final amount = minorUnits / pow(10, summary.assetScale);
    return '${summary.assetCode} ${amount.toStringAsFixed(summary.assetScale)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total vendido',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            _fmt(summary.totalSold),
            style: tt.headlineSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Tu comisión: ${_fmt(summary.galleryEarned)}',
                style: tt.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (summary.pendingCount > 0)
                Text(
                  '${summary.pendingCount} pendiente${summary.pendingCount == 1 ? '' : 's'}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
