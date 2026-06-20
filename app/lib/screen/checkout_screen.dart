import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: const Center(child: Text('Checkout')),
    );
  }
}
