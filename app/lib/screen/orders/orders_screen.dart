import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/payments_provider.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/empty_payments.dart';
import '../../widgets/payment_card.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final paymentsAsync = ref.watch(paymentsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(paymentsProvider.notifier).refresh(),
      child: CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(
            'Historial',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0.5,
          shadowColor: cs.shadow.withValues(alpha: 0.08),
          elevation: 0,
        ),
        paymentsAsync.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: _SkeletonList(),
          ),
          error: (err, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: AppErrorState(
              message: 'Could not load your history. Check your connection.',
              onRetry: () => ref.invalidate(paymentsProvider),
            ),
          ),
          data: (payments) {
            if (payments.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyPayments(),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList.separated(
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    PaymentCard(payment: payments[index]),
              ),
            );
            },
          ),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: List.generate(
          5,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _SkeletonCard(),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final block = cs.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Rect(w: 72, h: 9, color: block),
                    const SizedBox(height: 5),
                    _Rect(w: 160, h: 13, color: block),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Rect(w: 64, h: 20, r: 6, color: block),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Rect(w: 80, h: 14, color: block),
              const Spacer(),
              _Rect(w: 60, h: 10, color: block),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rect extends StatelessWidget {
  final double w;
  final double h;
  final double r;
  final Color color;

  const _Rect({required this.w, required this.h, required this.color, this.r = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}
