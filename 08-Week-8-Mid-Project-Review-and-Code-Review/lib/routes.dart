import 'package:go_router/go_router.dart';

import 'features/notes/presentation/pages/notes_page.dart';

/// Rute dan konfigurasi GoRouter aplikasi
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String notes = '/notes';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const NotesPage(),
    ),
  ],
);
