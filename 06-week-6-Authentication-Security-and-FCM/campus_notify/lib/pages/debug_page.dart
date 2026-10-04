import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../messaging/push_service.dart';
import '../routes.dart';

/// Halaman bukti untuk laporan: status FCM, token TERPOTONG, topik, log.
class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final push = PushService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug FCM'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(
            [push.status, push.fcmToken, push.subscribed, push.logs]),
        builder: (context, _) {
          final token = push.fcmToken.value;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Status: ${push.status.value}'),
              const SizedBox(height: 8),
              Text('FCM token: ${token == null ? '-' : previewToken(token)}'),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Topik $kCampusTopic'),
                value: push.subscribed.value,
                onChanged:
                    push.firebaseReady ? (v) => push.setSubscribed(v) : null,
              ),
              const Divider(),
              const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (push.logs.value.isEmpty) const Text('(kosong)'),
              for (final line in push.logs.value)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(line, style: const TextStyle(fontSize: 12)),
                ),
            ],
          );
        },
      ),
    );
  }
}