/// Fungsi murni: RemoteMessage.data -> rute tujuan (Refactoring Challenge #2).
/// Tidak bergantung pada Firebase sehingga mudah di-unit-test.
String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route'];
  final route = raw is String ? raw.trim() : '';
  if (route.isEmpty) return '/';
  return route.startsWith('/') ? route : '/$route';
}