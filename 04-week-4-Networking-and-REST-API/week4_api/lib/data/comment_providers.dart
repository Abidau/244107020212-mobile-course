import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/comment.dart';
import 'providers.dart';
import 'repositories/comment_repository.dart';

/// Provider untuk instansiasi [CommentRepository].
/// Menggunakan `dioProvider` dari `providers.dart` sebagai dependency injection Dio.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CommentRepository(dio);
});

/// Class [CommentListNotifier] mengoperasikan logika bisnis asynchronous untuk memuat komentar.
/// Menyiapkan `AsyncNotifier<List<Comment>>` dengan parameter `postId` yang dikirim via constructor.
///
/// Error handling otomatis (AsyncError):
/// Di Riverpod, semua exception yang terjadi di dalam method `build()`
/// secara otomatis ditangkap oleh Riverpod dan disimpan sebagai state [AsyncError].
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  /// Unique identifier post untuk mengambil komentar terkait.
  final int postId;

  /// Constructor [CommentListNotifier] yang menerima parameter [postId].
  CommentListNotifier(this.postId);

  @override
  Future<List<Comment>> build() async {
    // Mengambil instance repository dari commentRepositoryProvider
    final repository = ref.watch(commentRepositoryProvider);

    // Mengambil data komentar dari repository berdasarkan postId.
    // Jika terjadi error (misalnya DioException), Riverpod secara otomatis
    // membungkus error tersebut menjadi state AsyncError.
    return repository.fetchComments(postId);
  }

  /// Method untuk memperbarui (refresh) daftar komentar secara manual.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      final result = await repository.fetchComments(postId);
      state = AsyncData(result);
    } catch (e, st) {
      // Menyimpan exception dan stacktrace ke dalam state AsyncError jika gagal
      state = AsyncError(e, st);
    }
  }
}

/// Provider family `commentListProvider` yang mengembalikan [AsyncNotifierProvider.family]
/// untuk memetakan `postId` (int) ke state asynchronous list komentar (`AsyncValue<List<Comment>>`).
final commentListProvider =
    AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>(
  (postId) => CommentListNotifier(postId),
  // Matikan retry otomatis agar error langsung diteruskan ke UI / unit test tanpa penundaan
  retry: (retryCount, error) => null,
);

/// Fungsi untuk mengubah objek error (khususnya [DioException]) menjadi pesan error
/// yang ramah pengguna (user-friendly error message).
///
/// Meng-handle skenario spesifik sesuai requirement:
/// 1. Timeout (connectionTimeout, sendTimeout, receiveTimeout)
/// 2. Connection error (connectionError)
/// 3. HTTP Status 404 (Data tidak ditemukan)
/// 4. HTTP Status 500 (Kesalahan internal server)
String getFriendlyCommentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      // 1. Penanganan error untuk kasus Timeout (Connection, Send, atau Receive Timeout)
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi mencapai batas waktu (Timeout 10 detik). Silakan periksa jaringan internet Anda dan coba lagi.';

      // 2. Penanganan error untuk kegagalan koneksi jaringan (Connection Error)
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.';

      // 3 & 4. Penanganan respon status code dari server (404 dan 500)
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Komentar tidak ditemukan (Error 404).';
        }
        if (statusCode == 500) {
          return 'Terjadi kesalahan pada server (Error 500). Silakan coba lagi beberapa saat lagi.';
        }
        return 'Gagal memuat data dari server (Status HTTP: $statusCode).';

      // Fallback untuk tipe DioException lainnya
      default:
        return 'Terjadi masalah pada koneksi jaringan. Coba lagi nanti.';
    }
  }

  // Fallback untuk error tipe umum lainnya di luar DioException
  return 'Terjadi kesalahan tidak terduga: ${error.toString()}';
}
