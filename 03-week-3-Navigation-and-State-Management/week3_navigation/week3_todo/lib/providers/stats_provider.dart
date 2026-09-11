import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider untuk menentukan kemungkinan terjadinya error.
final statsFailureRateProvider = Provider<double>((ref) => 0.0);

/// Notifier untuk mengambil data statistik secara asynchronous.
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return _fetchStats();
  }

  Future<List<String>> _fetchStats() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final failureRate = ref.read(statsFailureRateProvider);

    if (Random().nextDouble() < failureRate) {
      throw Exception(
        'Gagal mengambil data statistik',
      );
    }

    return [
      'Total Pengguna: 120',
      'Total Produk: 45',
      'Total Pesanan: 78',
    ];
  }

  Future<void> retry() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      _fetchStats,
    );
  }
}

/// Provider utama untuk StatsNotifier.
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);