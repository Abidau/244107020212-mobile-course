import 'package:go_router/go_router.dart';

import 'features/chat_screen.dart';
import 'features/multimodal_screen.dart';
import 'features/notes/presentation/pages/notes_page.dart';

/// Rute dan konfigurasi GoRouter aplikasi
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String notes = '/notes';
  static const String chat = '/chat';
  static const String multimodal = '/multimodal';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const NotesPage(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: AppRoutes.multimodal,
      builder: (context, state) => const MultimodalScreen(),
    ),
  ],
);
