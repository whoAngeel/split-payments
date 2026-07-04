import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'router/app_router.dart';

class OpenPaymentsApp extends ConsumerStatefulWidget {
  const OpenPaymentsApp({super.key});

  @override
  ConsumerState<OpenPaymentsApp> createState() => _OpenPaymentsAppState();
}

class _OpenPaymentsAppState extends ConsumerState<OpenPaymentsApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host == 'payment' && uri.path == '/complete') {
      final sessionId = uri.queryParameters['session_id'] ?? '';
      final status = uri.queryParameters['status'] ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(appRouterProvider).go(
            '/payment/complete?session_id=$sessionId&status=$status',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'OpenPayments',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      routerConfig: router,
    );
  }
}
