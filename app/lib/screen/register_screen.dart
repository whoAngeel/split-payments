import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/providers/auth_provider.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_icon_box.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _walletController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _validationError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _validationError = 'Fill in all fields');
      return;
    }
    if (password.length < 8) {
      setState(() => _validationError = 'Password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _validationError = "Passwords don't match");
      return;
    }

    setState(() => _validationError = null);

    final wallet = _walletController.text.trim();
    await ref.read(authProvider.notifier).register(
      email,
      password,
      name,
      walletAddress: wallet.isEmpty ? null : wallet,
    );

    if (!mounted) return;

    final state = ref.read(authProvider);
    if (state is AsyncData && state.value != null) {
      final session = state.value;
      if (session!.isAdmin) {
        context.go('/admin/dashboard');
      } else {
        context.go('/explorar');
      }
    }
  }

  String _friendlyError(Object? error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('409') || msg.contains('conflict') || msg.contains('already')) {
      return 'This email is already registered';
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'Server took too long. Try again';
    }
    if (msg.contains('socket') || msg.contains('connection') || msg.contains('network')) {
      return 'No connection. Check your internet';
    }
    return 'Error: ${error.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);

    final errorMessage =
        _validationError ?? (authState.hasError ? _friendlyError(authState.error) : null);

    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconBox(icon: Icons.handshake_outlined, size: 72, radius: 20),
                const SizedBox(height: 24),
                Text(
                  'Create account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  authState.isLoading ? 'Creating account...' : 'Join Open Artisan',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                AppTextField(
                  label: 'Name',
                  hint: 'Your full name',
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outlined),
                  enabled: !authState.isLoading,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  hint: 'user@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined),
                  enabled: !authState.isLoading,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: 'At least 8 characters',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  enabled: !authState.isLoading,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Wallet (optional)',
                  hint: r'$wallet.example.com/usuario  o  https://...',
                  controller: _walletController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  enabled: !authState.isLoading,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Repeat your password',
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  enabled: !authState.isLoading,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
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
                            errorMessage,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: 'Create account',
                  fullWidth: true,
                  onPressed: authState.isLoading ? null : _register,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Already have an account',
                  variant: AppButtonVariant.text,
                  onPressed: authState.isLoading ? null : () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
