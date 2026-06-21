import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/models/session.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/screen/account/account_screen.dart';
import 'package:openpayments_app/screen/admin/artisans/artisans_screen.dart';
import 'package:openpayments_app/screen/admin/artisans/artisan_form_screen.dart';
import 'package:openpayments_app/screen/admin/artisans/artisan_products_screen.dart';
import 'package:openpayments_app/screen/admin/dashboard/dashboard_screen.dart';
import 'package:openpayments_app/screen/admin/products/products_screen.dart';
import 'package:openpayments_app/screen/admin/settings/settings_screen.dart';
import 'package:openpayments_app/screen/checkout/checkout_screen.dart';
import 'package:openpayments_app/screen/home_screen.dart';
import 'package:openpayments_app/screen/auth/login_screen.dart';
import 'package:openpayments_app/screen/auth/register_screen.dart';
import 'package:openpayments_app/screen/orders/orders_screen.dart';
import 'package:openpayments_app/screen/explore/explore_screen.dart';
import 'package:openpayments_app/screen/explore/product_detail_screen.dart';
import 'package:openpayments_app/screen/payment/payment_confirmation_screen.dart';
import 'package:openpayments_app/widgets/admin_shell.dart';
import 'package:openpayments_app/widgets/app_shell.dart';

final sessionNotifier = ValueNotifier<Session?>(null);

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.listen(authProvider, (_, next) {
    sessionNotifier.value = next.valueOrNull;
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: sessionNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (location.startsWith('openpayments://')) {
        final uri = Uri.parse(location);
        final sessionId = uri.queryParameters['session_id'] ?? '';
        final status = uri.queryParameters['status'] ?? '';
        return '/payment/complete?session_id=$sessionId&status=$status';
      }

      final session = sessionNotifier.value;
      final isLoading = session == null && ref.read(authProvider).isLoading;

      if (isLoading) return null;

      final isLoggedIn = session != null;
      final isAdmin = session?.isAdmin ?? false;
      final isLoginRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) {
        return isAdmin ? '/admin/dashboard' : '/explorar';
      }

      final isOnAdminRoute = state.matchedLocation.startsWith('/admin');
      if (isAdmin && !isOnAdminRoute && !isLoginRoute) {
        return '/admin/dashboard';
      }
      if (!isAdmin && isOnAdminRoute) {
        return '/explorar';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Buyer shell
      ShellRoute(
        builder: ((context, state, child) => AppShell(child: child)),
        routes: [
          GoRoute(
            path: '/explorar',
            name: 'explorar',
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersScreen(),
          ),
        ],
      ),

      // Admin shell
      ShellRoute(
        builder: ((context, state, child) => AdminShell(child: child)),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/artisans',
            name: 'admin-artisans',
            builder: (context, state) => const AdminArtisansScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            name: 'admin-products',
            builder: (context, state) => const AdminProductsScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'admin-settings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: id);
        },
      ),

      // Admin overlay routes
      GoRoute(
        path: '/admin/artisans/new',
        name: 'admin-artisan-new',
        builder: (context, state) => const AdminArtisanFormScreen(),
      ),
      GoRoute(
        path: '/admin/artisans/:id/edit',
        name: 'admin-artisan-edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AdminArtisanFormScreen(artisanId: id);
        },
      ),
      GoRoute(
        path: '/admin/artisans/:id/products',
        name: 'admin-artisan-products',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final name = state.extra as String? ?? '';
          return AdminArtisanProductsScreen(artisanId: id, artisanName: name);
        },
      ),

      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/payment/complete',
        name: 'paymentComplete',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['session_id'] ?? '';
          final status = state.uri.queryParameters['status'] ?? '';
          return PaymentConfirmationScreen(
            sessionId: sessionId,
            status: status,
          );
        },
      ),
    ],
  );
});
