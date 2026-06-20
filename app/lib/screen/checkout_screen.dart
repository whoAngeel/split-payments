import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openpayments_app/screen/payment_confirmation_screen.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/models/checkout.dart';
import 'package:openpayments_app/models/product.dart';
import 'package:openpayments_app/providers/checkout_provider.dart';
import 'package:openpayments_app/widgets/app_button.dart';
import 'package:openpayments_app/widgets/app_text_field.dart';
import 'package:openpayments_app/widgets/split_payment_bar.dart';

import '../widgets/app_scaffold.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _walletController = TextEditingController();

  @override
  void dispose() {
    _walletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final product = ref.watch(selectedProductProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final user = ref.watch(authProvider).valueOrNull?.user;
    final userWallet = user?.walletAddressUrl ?? '';
    final hasWallet = userWallet.isNotEmpty;

    if (product == null) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('No product selected')),
      );
    }

    final price = product.basePrice / pow(10, product.assetScale);
    final split = product.split;

    return AppScaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _productSummary(cs, product, price),
            const SizedBox(height: 24),

            if (split != null) ...[
              _priceBreakdown(cs, product, split),
              const SizedBox(height: 24),
              Text(
                'Split Distribution',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              SplitPaymentBar(split: split),
              const SizedBox(height: 24),
            ],

            Text(
              'Tu wallet',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            if (hasWallet)
              _walletChip(cs, userWallet)
            else
              AppTextField(
                label: 'Interledger wallet URL',
                hint: r'$wallet.example.com/...  o  https://...',
                controller: _walletController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
            const SizedBox(height: 24),

            AppButton(
              label: checkoutState.isLoading ? 'Procesando...' : 'Pagar con Open Payments',
              fullWidth: true,
              onPressed: checkoutState.isLoading
                  ? null
                  : () => _pay(product, hasWallet ? userWallet : null),
            ),

            if (checkoutState is AsyncError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  '${checkoutState.error}',
                  style: TextStyle(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _walletChip(ColorScheme cs, String wallet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              wallet,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productSummary(ColorScheme cs, Product product, num price) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: product.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(12),
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.image_outlined),
                  ),
                )
              : const Icon(Icons.image_outlined),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                product.artisanName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
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
    );
  }

  Widget _priceBreakdown(ColorScheme cs, Product product, ProductSplit split) {
    final basePrice = product.basePrice / pow(10, product.assetScale);
    final artisanAmount = basePrice * split.artisanPercent / 100;
    final galleryAmount = basePrice * split.galleryPercent / 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row(cs, 'Precio base', basePrice, product),
          const Divider(height: 24),
          _row(cs, 'Artesano recibe', artisanAmount, product, color: cs.primary),
          _row(cs, 'Galería recibe', galleryAmount, product, color: cs.secondary),
          if (split.platformPercent > 0)
            _row(
              cs,
              'Comisión plataforma',
              basePrice * split.platformPercent / 100,
              product,
              color: cs.tertiary,
            ),
        ],
      ),
    );
  }

  Widget _row(ColorScheme cs, String label, num amount, Product product, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color ?? cs.onSurface),
          ),
          const Spacer(),
          Text(
            '${product.assetCode} ${amount.toStringAsFixed(product.assetScale)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(Product product, String? prefilledWallet) async {
    final wallet = prefilledWallet ?? _walletController.text.trim();
    if (wallet.isEmpty) return;

    await ref.read(checkoutProvider.notifier).checkout(
      CheckoutRequest(productId: product.id, buyerWallet: wallet),
    );

    if (!mounted) return;

    final state = ref.read(checkoutProvider);
    if (state is AsyncData && state.value != null) {
      final uri = Uri.parse(state.value!.redirectUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentConfirmationScreen(sessionId: state.value!.sessionId),
        ),
      );
    }
  }
}
