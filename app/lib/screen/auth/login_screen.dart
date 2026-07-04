import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/providers/auth_provider.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icon_box.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _validationError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _validationError = 'Fill in all fields');
      return;
    }

    setState(() => _validationError = null);

    await ref.read(authProvider.notifier).login(email, password);

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
    if (msg.contains('401') || msg.contains('invalid') || msg.contains('password')) {
      return 'Incorrect email or password';
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
                AppIconBox(
                  icon: Icons.handshake_outlined,
                  size: 72,
                  radius: 20,
                ),
                const SizedBox(height: 24),
                Text(
                  'Open Artisan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  authState.isLoading ? 'Signing in...' : 'Sign in to continue',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
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
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
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
                  label: 'Sign in',
                  fullWidth: true,
                  onPressed: authState.isLoading ? null : _login,
                ),
                const SizedBox(height: 16),
                if (authState.isLoading)
                  AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.text,
                    onPressed: () => ref.read(authProvider.notifier).cancelLogin(),
                  )
                else ...[
                  AppButton(
                    label: 'Create account',
                    variant: AppButtonVariant.text,
                    onPressed: () => context.go('/register'),
                  ),
                  AppButton(
                    label: 'Forgot password?',
                    variant: AppButtonVariant.text,
                    onPressed: () => context.go('/forgot-password'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
