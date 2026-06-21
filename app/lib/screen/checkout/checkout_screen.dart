import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openpayments_app/screen/payment/payment_confirmation_screen.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openpayments_app/models/checkout.dart';
import 'package:openpayments_app/models/product.dart';
import 'package:openpayments_app/providers/checkout_provider.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';
import 'package:openpayments_app/widgets/app_text_field.dart';

import '../../widgets/app_scaffold.dart';

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
    final tt = Theme.of(context).textTheme;
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
      appBar: AppBar(
        title: Text('Order summary', style: tt.titleMedium),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProductHero(product: product, price: price, cs: cs),
                    const SizedBox(height: 24),
                    Divider(height: 1, color: cs.outlineVariant),
                    const SizedBox(height: 24),
                    if (split != null) ...[
                      _SplitCard(
                        split: split,
                        product: product,
                        basePrice: price,
                        cs: cs,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _WalletSection(
                      cs: cs,
                      hasWallet: hasWallet,
                      userWallet: userWallet,
                      controller: _walletController,
                    ),
                    if (checkoutState is AsyncError) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(error: checkoutState.error ?? 'Unknown error', cs: cs),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _CtaBar(
              product: product,
              price: price,
              isLoading: checkoutState.isLoading,
              onPay: () => _pay(product, hasWallet ? userWallet : null),
              cs: cs,
            ),
          ],
        ),
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
      final sessionId = state.value!.sessionId;

      // Save payment to history
      final authState = ref.read(authProvider);
      final buyerId = authState.valueOrNull?.user.id ?? 0;
      if (buyerId > 0) {
        final service = ref.read(checkoutServiceProvider);
        await service.savePayment(sessionId, product.id, buyerId);
      }

      final uri = Uri.parse(state.value!.redirectUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentConfirmationScreen(sessionId: sessionId),
        ),
      );
    }
  }
}

class _ProductHero extends StatelessWidget {
  final Product product;
  final num price;
  final ColorScheme cs;

  const _ProductHero({required this.product, required this.price, required this.cs});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 96,
            height: 96,
            color: cs.surfaceContainerHighest,
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: cs.outline),
                  )
                : Icon(Icons.image_outlined, color: cs.outline),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.artisanName,
                style: tt.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.name,
                style: tt.headlineSmall?.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                '${product.assetCode} ${price.toStringAsFixed(product.assetScale)}',
                style: tt.titleLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SplitCard extends StatelessWidget {
  final ProductSplit split;
  final Product product;
  final num basePrice;
  final ColorScheme cs;

  const _SplitCard({
    required this.split,
    required this.product,
    required this.basePrice,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final artisanAmt = basePrice * split.artisanPercent / 100;
    final galleryAmt = basePrice * split.galleryPercent / 100;
    final platformAmt = split.platformPercent > 0 ? basePrice * split.platformPercent / 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'PAYMENT TRANSPARENCY',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (split.artisanPercent > 0)
                    Expanded(flex: split.artisanPercent, child: Container(color: cs.primary)),
                  if (split.galleryPercent > 0)
                    Expanded(flex: split.galleryPercent, child: Container(color: cs.secondary)),
                  if (split.platformPercent > 0)
                    Expanded(flex: split.platformPercent, child: Container(color: cs.tertiary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _splitRow(context, cs.primary, 'Artisan receives', artisanAmt, split.artisanPercent, product),
          if (split.galleryPercent > 0) ...[
            const SizedBox(height: 8),
            _splitRow(context, cs.onSurfaceVariant, 'Gallery receives', galleryAmt, split.galleryPercent, product),
          ],
          if (split.platformPercent > 0) ...[
            const SizedBox(height: 8),
            _splitRow(context, cs.tertiary, 'Platform fee', platformAmt, split.platformPercent, product),
          ],
          Divider(height: 24, color: cs.outlineVariant),
          Row(
            children: [
              Text('Base price', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const Spacer(),
              Text(
                '${product.assetCode} ${basePrice.toStringAsFixed(product.assetScale)}',
                style: tt.bodySmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _splitRow(
    BuildContext context,
    Color dotColor,
    String label,
    num amount,
    int percent,
    Product product,
  ) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface))),
        Text(
          '${product.assetCode} ${amount.toStringAsFixed(product.assetScale)} ($percent%)',
          style: tt.bodySmall?.copyWith(
            color: dotColor == cs.primary ? cs.primary : cs.onSurfaceVariant,
            fontWeight: dotColor == cs.primary ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _WalletSection extends StatelessWidget {
  final ColorScheme cs;
  final bool hasWallet;
  final String userWallet;
  final TextEditingController controller;

  const _WalletSection({
    required this.cs,
    required this.hasWallet,
    required this.userWallet,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pay from',
          style: tt.titleSmall?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (hasWallet)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    userWallet,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.check_circle_outline, size: 16, color: cs.primary),
              ],
            ),
          )
        else
          AppTextField(
            label: 'Interledger wallet URL',
            hint: r'$wallet.example.com/... or https://...',
            controller: controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final Object error;
  final ColorScheme cs;

  const _ErrorBanner({required this.error, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaBar extends StatefulWidget {
  final Product product;
  final num price;
  final bool isLoading;
  final VoidCallback onPay;
  final ColorScheme cs;

  const _CtaBar({
    required this.product,
    required this.price,
    required this.isLoading,
    required this.onPay,
    required this.cs,
  });

  @override
  State<_CtaBar> createState() => _CtaBarState();
}

class _CtaBarState extends State<_CtaBar> with SingleTickerProviderStateMixin {
  late final AnimationController _fillCtrl;
  late final Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();
    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    );
    _fillAnim = CurvedAnimation(
      parent: _fillCtrl,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 0.88));
  }

  @override
  void didUpdateWidget(_CtaBar old) {
    super.didUpdateWidget(old);
    if (widget.isLoading && !old.isLoading) {
      _fillCtrl.forward();
    } else if (!widget.isLoading && old.isLoading) {
      _fillCtrl.stop();
      _fillCtrl.reset();
    }
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: cs.inverseSurface),
                    ),
                    AnimatedBuilder(
                      animation: _fillAnim,
                      builder: (context, _) => FractionallySizedBox(
                        widthFactor: widget.isLoading ? _fillAnim.value : 0,
                        alignment: Alignment.centerLeft,
                        child: ColoredBox(
                          color: cs.onInverseSurface.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.isLoading ? null : widget.onPay,
                        splashColor: cs.onInverseSurface.withValues(alpha: 0.1),
                        highlightColor: cs.onInverseSurface.withValues(alpha: 0.06),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: child,
                            ),
                            child: widget.isLoading
                                ? Row(
                                    key: const ValueKey('loading'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Processing payment',
                                        style: tt.titleSmall?.copyWith(
                                          color: cs.onInverseSurface,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    key: const ValueKey('idle'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.payments_outlined, size: 20, color: cs.onInverseSurface),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Pay with Open Payments',
                                        style: tt.titleSmall?.copyWith(
                                          color: cs.onInverseSurface,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${widget.product.assetCode} ${widget.price.toStringAsFixed(widget.product.assetScale)}',
                                        style: tt.titleSmall?.copyWith(
                                          color: cs.inversePrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeIn,
              crossFadeState: widget.isLoading
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '~10–30 seconds · Keep the app open',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
