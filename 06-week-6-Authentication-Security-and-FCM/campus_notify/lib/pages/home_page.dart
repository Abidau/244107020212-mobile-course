import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(tokenStoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login berhasil'),
            const SizedBox(height: 8),
            // Jangan tampilkan token penuh (aturan keamanan codelab).
            FutureBuilder<String?>(
              future: store.readAccess(),
              builder: (context, snap) {
                final t = snap.data ?? '-';
                final shown = t.length > 12 ? '${t.substring(0, 12)}...' : t;
                return Text('Access token: $shown');
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.announcement('3')),
              child: const Text('Buka pengumuman #3'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.debug),
              child: const Text('Debug FCM'),
            ),
          ],
        ),
      ),
    );
  }
}