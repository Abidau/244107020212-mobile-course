import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/debug_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (prev, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      // Token masih dibaca dari secure storage -> jangan redirect dulu.
      if (auth.isLoading && !auth.hasValue) return null;

      final loggedIn = auth.hasValue && auth.value == true;
      final goingLogin = state.matchedLocation == AppRoutes.login;
      final pending = PushService.instance.pendingRoute;

      if (!loggedIn && !goingLogin) return AppRoutes.login;
      // Setelah login, lanjutkan ke tujuan notifikasi yang tertunda.
      if (loggedIn && goingLogin) return pending ?? AppRoutes.home;
      if (loggedIn && pending != null && state.uri.toString() == pending) {
        PushService.instance.pendingRoute = null;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.debug,
        builder: (context, state) => const DebugPage(),
      ),
      GoRoute(
        path: AppRoutes.announcementPattern,
        builder: (context, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
});