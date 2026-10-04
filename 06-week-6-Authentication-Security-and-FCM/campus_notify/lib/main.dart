import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'messaging/push_service.dart';
import 'providers/auth_provider.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp + registrasi background handler (aman bila gagal).
  await PushService.instance.bootstrapFirebase();
  runApp(const ProviderScope(child: CampusNotifyApp()));
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  @override
  void initState() {
    super.initState();
    // Setelah frame pertama: router sudah siap menerima navigasi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushService.instance.init(onToken: _sendToken, onRoute: _navigate);
    });
  }

  /// Kirim token ke backend (POST /devices). Backend contoh tidak ada,
  /// jadi kegagalan hanya dicatat.
  Future<void> _sendToken(String token) async {
    try {
      await ref.read(apiClientProvider).post('/devices', data: {
        'fcm_token': token,
        'platform': defaultTargetPlatform.name,
      });
    } catch (e) {
      debugPrint('POST /devices gagal (backend contoh): ${e.runtimeType}');
    }
  }

  /// Navigasi dari notifikasi. Bila belum login, simpan sebagai tujuan
  /// tertunda lalu diteruskan setelah login berhasil.
  Future<void> _navigate(String route) async {
    bool loggedIn;
    try {
      loggedIn = await ref.read(authStateProvider.future);
    } catch (_) {
      loggedIn = false;
    }
    if (!mounted) return;
    if (loggedIn) {
      ref.read(routerProvider).go(route);
    } else {
      PushService.instance.pendingRoute = route;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
