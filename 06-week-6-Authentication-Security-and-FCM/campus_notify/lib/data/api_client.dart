import 'dart:ui' show VoidCallback;

import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

Dio buildApiClient(
  TokenStore store,
  AuthRepository auth, {
  VoidCallback? onSessionExpired,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final access = await store.readAccess();
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      final is401 = e.response?.statusCode == 401;
      // Flag 'retried' mencegah loop tak berujung bila retry tetap 401.
      final alreadyRetried = e.requestOptions.extra['retried'] == true;

      if (is401 && !alreadyRetried) {
        final refresh = await store.readRefresh();
        if (refresh == null) return handler.next(e);
        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);

          final opts = e.requestOptions
            ..headers['Authorization'] = 'Bearer $renewed'
            ..extra['retried'] = true;
          final retry = await dio.fetch(opts);
          return handler.resolve(retry);
        } catch (_) {
          await store.clear(); // refresh ikut mati -> paksa login ulang
          onSessionExpired?.call();
        }
      }
      handler.next(e);
    },
  ));
  return dio;
}