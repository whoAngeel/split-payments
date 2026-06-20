import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/providers/auth_provider.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_icon_box.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text.trim());
    final session = ref.read(authProvider);
    if (session is AsyncData && session.value != null) {
      context.go('/explorar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);

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
                  authState.isLoading
                      ? 'Ingresando...'
                      : 'Ingresa para continuar',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                AppTextField(
                  label: 'Correo electronico',
                  hint: 'usuario@gmail.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Contraseña',
                  hint: 'Escribe tu contraseña',
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                  ), // TODO: mejorar el login para la ux
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Ingresar',
                  fullWidth: true,
                  onPressed: authState.isLoading ? null : _login,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Crear cuenta',
                  variant: AppButtonVariant.text,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
