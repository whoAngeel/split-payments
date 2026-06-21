import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../providers/checkout_provider.dart';
import '../providers/api_client_provider.dart';
import '../service/ws_service.dart';

class PaymentConfirmationScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String status;

  const PaymentConfirmationScreen({
    super.key,
    required this.sessionId,
    this.status = 'pending',
  });

  @override
  ConsumerState<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends ConsumerState<PaymentConfirmationScreen> {
  final _ws = WsService();
  late String _status;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _status = widget.status;

    if (_status == 'pending') {
      _timeout = Timer(const Duration(minutes: 2), () {
        if (mounted) {
          _completePayment(status: 'failed');
          setState(() => _status = 'failed');
          _ws.disconnect();
        }
      });

      _ws.connect(widget.sessionId, (data) {
        final s = data['status'] as String? ?? '';
        if (s == 'completed' || s == 'failed') {
          _timeout?.cancel();
          _completePayment(status: s);
          setState(() => _status = s);
          _ws.disconnect();
        }
      });
    }
  }

  Future<void> _completePayment({String status = 'completed'}) async {
    try {
      final service = ref.read(checkoutServiceProvider);
      await service.completePayment(widget.sessionId, status: status);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _ws.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: switch (_status) {
          'completed' => _buildCompleted(cs),
          'failed' => _buildFailed(cs),
          _ => _buildPending(cs),
        },
      ),
    );
  }

  Widget _buildPending(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing your payment...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your wallet is being debited and the split payments are being sent to the artisan and gallery.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _infoRow(cs, Icons.timer_outlined, 'Estimated time', '10–30 seconds'),
          const SizedBox(height: 8),
          _infoRow(cs, Icons.receipt_long_outlined, 'Session', widget.sessionId.substring(0, 8)),
        ],
      ),
    );
  }

  Widget _buildCompleted(ColorScheme cs) {
    final product = ref.read(selectedProductProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, size: 48, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Payment Successful!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
          ),
          const SizedBox(height: 24),
          if (product != null) _productSummary(cs, product),
          const SizedBox(height: 16),
          _transactionSummary(cs),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/explorar'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Continue Exploring'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailed(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 48, color: cs.error),
          ),
          const SizedBox(height: 20),
          Text(
            'Payment Failed',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.error,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'The payment could not be completed. Your wallet has not been charged.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.pop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productSummary(ColorScheme cs, Product product) {
    final price = product.basePrice / pow(10, product.assetScale);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(product.imageUrl, fit: BoxFit.cover),
                  )
                : Icon(Icons.image_outlined, color: cs.outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 2),
                Text(product.artisanName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        )),
                const SizedBox(height: 4),
                Text(
                  '${product.assetCode} ${price.toStringAsFixed(product.assetScale)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionSummary(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transaction Summary',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 12),
          _summaryRow(cs, 'Session ID', widget.sessionId.substring(0, 8)),
          const SizedBox(height: 6),
          _summaryRow(cs, 'Status', 'Completed'),
          const SizedBox(height: 6),
          _summaryRow(cs, 'Network', 'Interledger'),
          const SizedBox(height: 6),
          _summaryRow(cs, 'Time', '~15 seconds'),
        ],
      ),
    );
  }

  Widget _summaryRow(ColorScheme cs, String label, String value) {
    return Row(
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                )),
        const Spacer(),
        Text(value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                )),
      ],
    );
  }

  Widget _infoRow(ColorScheme cs, IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                )),
        const SizedBox(width: 8),
        Text(value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
      ],
    );
  }
}
