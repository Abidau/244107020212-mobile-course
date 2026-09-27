import 'package:dio/dio.dart';
import '../models/comment.dart';

/// Class Repository untuk mengelola pemanggilan API terkait data Komentar (Comment).
class CommentRepository {
  /// Instance Client Dio yang digunakan untuk melakukan HTTP request.
  final Dio _dio;

  /// Constructor untuk [CommentRepository] yang menerima instance [Dio].
  CommentRepository(this._dio);

  /// Mengambil daftar komentar berdasarkan [postId] dari endpoint GET /comments?postId={id}.
  ///
  /// Requirements:
  /// - Mengakses endpoint GET /comments
  /// - Menambahkan parameter query `postId` (?postId={id})
  /// - Memiliki batas waktu timeout 10 detik.
  Future<List<Comment>> fetchComments(int postId) async {
    try {
      // Melakukan HTTP GET request ke endpoint '/comments' dengan query parameters {'postId': postId}
      // dan durasi timeout 10 detik yang dikonfigurasi melalui Options.
      final response = await _dio.get<List<dynamic>>(
        '/comments',
        queryParameters: {
          'postId': postId,
        },
        options: Options(
          // Membatasi waktu kirim data (send timeout) selama 10 detik
          sendTimeout: const Duration(seconds: 10),
          // Membatasi waktu terima data (receive timeout) selama 10 detik
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      // Mengambil data body dari response (jika null, gunakan list kosong sebagai fallback)
      final data = response.data ?? [];

      // Melakukan mapping dari setiap elemen JSON Map ke objek Comment yang aman dari null
      return data
          .whereType<Map<String, dynamic>>()
          .map(Comment.fromJson)
          .toList();
    } on DioException {
      // Meneruskan DioException agar dapat ditangkap oleh AsyncNotifierProvider / Error Handler
      rethrow;
    } catch (e) {
      // Menangkap error umum lainnya dan melemparnya kembali
      rethrow;
    }
  }
}
