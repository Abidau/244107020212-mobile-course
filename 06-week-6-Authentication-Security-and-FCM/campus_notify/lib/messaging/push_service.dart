import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'route_from_message.dart';

const kCampusTopic = 'pengumuman-kampus';
const _channelId = 'pengumuman';
const _channelName = 'Pengumuman Kampus';

typedef TokenCallback = Future<void> Function(String token);
typedef RouteCallback = void Function(String route);

/// Handler background WAJIB fungsi top-level + @pragma (jalan di isolate lain).
/// Jangan akses BuildContext / Riverpod di sini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[BG] id=${message.messageId} data=${message.data}');
}

String previewToken(String token) =>
    token.length > 12 ? '${token.substring(0, 12)}...' : token;

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // State yang ditampilkan di halaman Debug.
  final ValueNotifier<String> status = ValueNotifier('Belum diinisialisasi');
  final ValueNotifier<String?> fcmToken = ValueNotifier<String?>(null);
  final ValueNotifier<bool> subscribed = ValueNotifier<bool>(false);
  final ValueNotifier<List<String>> logs =
      ValueNotifier<List<String>>(const []);

  bool firebaseReady = false;
  bool _initialized = false;
  StreamSubscription<String>? _tokenSub;

  /// Rute tujuan dari notifikasi yang diklik saat user belum login.
  String? pendingRoute;

  void _log(String message) {
    final t = DateTime.now().toIso8601String().substring(11, 19);
    final next = ['$t  $message', ...logs.value];
    logs.value = next.length > 40 ? next.sublist(0, 40) : next;
    debugPrint('[Push] $message');
  }

  // ---------------------------------------------------------------------
  // Praktikum 2 - Langkah 1: inisialisasi Firebase
  // ---------------------------------------------------------------------
  /// Dipanggil di main() SEBELUM runApp. Aman bila google-services.json
  /// belum dipasang: aplikasi tetap jalan, fitur FCM saja yang nonaktif.
  Future<void> bootstrapFirebase() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      firebaseReady = true;
      status.value = 'Firebase siap';
    } catch (e) {
      firebaseReady = false;
      status.value = 'FCM nonaktif: Firebase belum dikonfigurasi '
          '(cek android/app/google-services.json)';
      _log('Firebase.initializeApp gagal (${e.runtimeType})');
    }
  }

  // ---------------------------------------------------------------------
  // Praktikum 2 - Langkah 2: izin notifikasi
  // ---------------------------------------------------------------------
  Future<bool> requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _initLocalNotifications(RouteCallback onRoute) async {
    // flutter_local_notifications >= 20 memakai named parameter.
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onRoute(payload);
      },
    );

    // Channel dengan importance tinggi agar banner muncul (Android 8+).
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Pengumuman dan informasi kampus',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Aplikasi dibuka dari klik notifikasi lokal saat sebelumnya mati.
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) onRoute(payload);
    }
  }

  // ---------------------------------------------------------------------
  // Praktikum 2 - Langkah 3: token lifecycle
  // ---------------------------------------------------------------------
  Future<void> _initToken(TokenCallback onToken) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      fcmToken.value = token;
      _log('Token didapat: ${previewToken(token)}');
      await onToken(token);
    }

    // WAJIB: token bisa berubah (reinstall, clear data, rotasi).
    await _tokenSub?.cancel();
    _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      fcmToken.value = newToken;
      _log('onTokenRefresh: ${previewToken(newToken)}');
      onToken(newToken);
    });
  }

  // ---------------------------------------------------------------------
  // Praktikum 3: handler foreground / background / terminated
  // ---------------------------------------------------------------------
  void _listenMessages(RouteCallback onRoute) {
    // Foreground: sistem TIDAK menampilkan banner -> tampilkan manual.
    FirebaseMessaging.onMessage.listen((message) async {
      final route = routeFromMessage(message.data);
      _log('[FG] ${message.notification?.title} -> $route');
      await _local.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Pengumuman',
        body: message.notification?.body ?? '',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: route,
      );
    });

    // Background -> banner sistem diklik.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = routeFromMessage(message.data);
      _log('[BG-click] -> $route');
      onRoute(route);
    });
  }

  // Terminated -> aplikasi dibuka dari notifikasi.
  Future<void> _handleTerminated(RouteCallback onRoute) async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final route = routeFromMessage(initial.data);
      _log('[Terminated-click] -> $route');
      onRoute(route);
    }
  }

  // ---------------------------------------------------------------------
  // Topic messaging
  // ---------------------------------------------------------------------
  Future<void> setSubscribed(bool value) async {
    if (!firebaseReady) return;
    try {
      if (value) {
        await FirebaseMessaging.instance.subscribeToTopic(kCampusTopic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(kCampusTopic);
      }
      subscribed.value = value;
      _log('${value ? 'Subscribe' : 'Unsubscribe'} topik $kCampusTopic');
    } catch (e) {
      _log('Topic gagal (${e.runtimeType})');
    }
  }

  // ---------------------------------------------------------------------
  // Entry point: panggil sekali setelah frame pertama (router sudah siap).
  // ---------------------------------------------------------------------
  Future<void> init({
    required TokenCallback onToken,
    required RouteCallback onRoute,
  }) async {
    if (_initialized) return;
    _initialized = true;

    if (!firebaseReady) return;

    try {
      await _initLocalNotifications(onRoute);

      final granted = await requestNotificationPermission();
      if (!granted) {
        status.value = 'Izin notifikasi ditolak';
        _log('Izin notifikasi ditolak');
        return;
      }

      await _initToken(onToken);
      _listenMessages(onRoute);
      await setSubscribed(true);
      await _handleTerminated(onRoute);
      status.value = 'FCM aktif';
    } catch (e) {
      status.value = 'FCM error: ${e.runtimeType}';
      _log('init gagal: $e');
    }
  }
}