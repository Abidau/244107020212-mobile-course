import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week3_todo/providers/stats_provider.dart';

void main() {
  test('StatsNotifier berhasil mengambil data statistik', () async {
    final container = ProviderContainer(
      overrides: [
        statsFailureRateProvider.overrideWithValue(0.0),
      ],
    );

    addTearDown(container.dispose);

    final result = await container.read(statsProvider.future);

    expect(result, [
      'Total Pengguna: 120',
      'Total Produk: 45',
      'Total Pesanan: 78',
    ]);
  });

  test('StatsNotifier menghasilkan error ketika request gagal', () async {
    final container = ProviderContainer(
      overrides: [
        statsFailureRateProvider.overrideWithValue(1.0),
      ],
    );

    addTearDown(container.dispose);

    container.read(statsProvider);

    await Future<void>.delayed(
      const Duration(seconds: 3),
    );

    final state = container.read(statsProvider);

    expect(state.hasError, isTrue);
    expect(state.error, isA<Exception>());
  });
}