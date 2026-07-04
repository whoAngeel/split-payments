import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/providers/api_client_provider.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icon_box.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _codeSent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();

    if (code.isEmpty || password.isEmpty) {
      setState(() => _error = 'Fill in all fields');
      return;
    }
    if (code.length != 6) {
      setState(() => _error = 'The code has 6 digits');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).resetPassword(email, code, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Sign in with your new password')),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  String _friendlyError(Object? error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('invalid or expired')) {
      return 'Invalid or expired code';
    }
    if (msg.contains('too many attempts')) {
      return 'Too many attempts. Request a new code';
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

    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconBox(
                  icon: Icons.lock_reset_outlined,
                  size: 72,
                  radius: 20,
                ),
                const SizedBox(height: 24),
                Text(
                  'Reset password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeSent
                      ? 'Enter the code sent to your email'
                      : 'We will send a recovery code to your email',
                  textAlign: TextAlign.center,
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
                  enabled: !_loading && !_codeSent,
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Recovery code',
                    hint: '6-digit code',
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.pin_outlined),
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'New password',
                    hint: 'At least 8 characters',
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
                    enabled: !_loading,
                  ),
                ],
                if (_error != null) ...[
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
                            _error!,
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
                  label: _codeSent ? 'Reset password' : 'Send code',
                  fullWidth: true,
                  onPressed: _loading ? null : (_codeSent ? _resetPassword : _requestCode),
                ),
                const SizedBox(height: 16),
                if (_codeSent)
                  AppButton(
                    label: 'Resend code',
                    variant: AppButtonVariant.text,
                    onPressed: _loading ? null : _requestCode,
                  ),
                AppButton(
                  label: 'Back to sign in',
                  variant: AppButtonVariant.text,
                  onPressed: _loading ? null : () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
