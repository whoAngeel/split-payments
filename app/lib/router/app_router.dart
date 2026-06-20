import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openpayments_app/providers/auth_provider.dart';
import 'package:openpayments_app/screen/account_screen.dart';
import 'package:openpayments_app/screen/admin_artisans_screen.dart';
import 'package:openpayments_app/screen/admin_dashboard_screen.dart';
import 'package:openpayments_app/screen/admin_products_screen.dart';
import 'package:openpayments_app/screen/admin_settings_screen.dart';
import 'package:openpayments_app/screen/checkout_screen.dart';
import 'package:openpayments_app/screen/home_screen.dart';
import 'package:openpayments_app/screen/login_screen.dart';
import 'package:openpayments_app/screen/register_screen.dart';
import 'package:openpayments_app/screen/orders_screen.dart';
import 'package:openpayments_app/screen/explore_screen.dart';
import 'package:openpayments_app/screen/product_detail_screen.dart';
import 'package:openpayments_app/screen/payment_confirmation_screen.dart';
import 'package:openpayments_app/widgets/admin_shell.dart';
import 'package:openpayments_app/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/explorar',
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Catch raw deep link before go_router fails
      if (location.startsWith('openpayments://')) {
        final uri = Uri.parse(location);
        final sessionId = uri.queryParameters['session_id'] ?? '';
        final status = uri.queryParameters['status'] ?? '';
        return '/payment/complete?session_id=$sessionId&status=$status';
      }

      if (authState.isLoading) return null;

      final session = authState.valueOrNull;
      final isLoggedIn = session != null;
      final isAdmin = session?.isAdmin ?? false;
      final isLoginRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) {
        return isAdmin ? '/admin/dashboard' : '/explorar';
      }

      // Redirect from buyer shell to admin shell and vice versa
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

      // Overlay routes (push, not shell)
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
