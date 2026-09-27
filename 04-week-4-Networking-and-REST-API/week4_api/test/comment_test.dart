import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/comment_providers.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Unit Test Comment Model', () {
    /// Requirements: Satu unit test untuk fromJson dengan field yang hilang.
    test('Comment.fromJson harus menangani JSON dengan field yang hilang tanpa throw error', () {
      // 1. Arrange: Menyiapkan data JSON di mana beberapa field utama (postId, id, name, email, body) hilang atau bernilai null.
      final Map<String, dynamic> jsonWithMissingFields = {
        'postId': null,
        // field 'id' sengaja tidak dimasukkan (missing)
        'name': null,
        // field 'email' sengaja tidak dimasukkan (missing)
        'body': null,
      };

      // 2. Act: Mengonversi JSON menjadi objek Comment menggunakan factory method Comment.fromJson.
      final comment = Comment.fromJson(jsonWithMissingFields);

      // 3. Assert: Memastikan parsing aman dan memberikan nilai fallback default tanpa melempar Exception/TypeError.
      expect(comment.postId, equals(0), reason: 'postId null/missing harus fallback ke 0');
      expect(comment.id, equals(0), reason: 'id null/missing harus fallback ke 0');
      expect(comment.name, equals(''), reason: 'name null/missing harus fallback ke string kosong');
      expect(comment.email, equals(''), reason: 'email null/missing harus fallback ke string kosong');
      expect(comment.body, equals(''), reason: 'body null/missing harus fallback ke string kosong');
    });

    test('Comment.fromJson harus memproses JSON lengkap dengan benar', () {
      // 1. Arrange: Menyiapkan data JSON lengkap.
      final Map<String, dynamic> fullJson = {
        'postId': 1,
        'id': 10,
        'name': 'John Doe',
        'email': 'john@example.com',
        'body': 'Ini adalah isi komentar unit test.',
      };

      // 2. Act: Mengonversi JSON ke objek Comment.
      final comment = Comment.fromJson(fullJson);

      // 3. Assert: Memastikan seluruh field terisi sesuai data input JSON.
      expect(comment.postId, equals(1));
      expect(comment.id, equals(10));
      expect(comment.name, equals('John Doe'));
      expect(comment.email, equals('john@example.com'));
      expect(comment.body, equals('Ini adalah isi komentar unit test.'));
    });

    /// Edge Case Test: Menguji tipe data tidak terduga (misal postId dalam bentuk String "99", name dalam bentuk angka) & null json.
    test('Comment.fromJson [Edge Case] harus menangani tipe data string/mismatched dan input null', () {
      // 1. Edge Case: Map dengan String berformat angka untuk ID dan tipe lain untuk name
      final Map<String, dynamic> mismatchedJson = {
        'postId': '42', // String berformat angka
        'id': '105',     // String berformat angka
        'name': 9999,    // Num bukannya String
        'email': true,   // Bool bukannya String
        'body': null,
      };

      final commentFromMismatched = Comment.fromJson(mismatchedJson);
      expect(commentFromMismatched.postId, equals(42), reason: 'postId string "42" harus di-parse ke 42');
      expect(commentFromMismatched.id, equals(105), reason: 'id string "105" harus di-parse ke 105');
      expect(commentFromMismatched.name, equals('9999'), reason: 'name non-string harus di-cast ke string');
      expect(commentFromMismatched.email, equals('true'), reason: 'email non-string harus di-cast ke string');

      // 2. Edge Case: Input null map secara penuh
      final commentFromNull = Comment.fromJson(null);
      expect(commentFromNull.postId, equals(0));
      expect(commentFromNull.id, equals(0));
      expect(commentFromNull.name, equals(''));
      expect(commentFromNull.email, equals(''));
      expect(commentFromNull.body, equals(''));
    });
  });

  group('Unit Test Penanganan Error Ramah Pengguna (getFriendlyCommentErrorMessage)', () {
    test('Harus mengembalikan pesan yang sesuai untuk Connection Timeout (Timeout 10 detik)', () {
      // 1. Arrange: DioException dengan tipe timeout
      final error = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.receiveTimeout,
      );

      // 2. Act: Memanggil fungsi pemeta pesan error
      final message = getFriendlyCommentErrorMessage(error);

      // 3. Assert: Memastikan pesan ramah pengguna memuat informasi timeout 10 detik
      expect(message, contains('Timeout 10 detik'));
    });

    test('Harus mengembalikan pesan yang sesuai untuk Connection Error', () {
      // 1. Arrange: DioException dengan tipe connection error
      final error = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.connectionError,
      );

      // 2. Act: Memanggil fungsi pemeta pesan error
      final message = getFriendlyCommentErrorMessage(error);

      // 3. Assert: Memastikan pesan memuat petunjuk koneksi internet
      expect(message, contains('Tidak dapat terhubung ke server'));
    });

    test('Harus mengembalikan pesan yang sesuai untuk HTTP 404 (Not Found)', () {
      // 1. Arrange: DioException badResponse dengan status code 404
      final error = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/comments'),
          statusCode: 404,
        ),
      );

      // 2. Act: Memanggil fungsi pemeta pesan error
      final message = getFriendlyCommentErrorMessage(error);

      // 3. Assert: Memastikan pesan memuat keterangan 404 tidak ditemukan
      expect(message, contains('404'));
      expect(message, contains('Komentar tidak ditemukan'));
    });

    test('Harus mengembalikan pesan yang sesuai untuk HTTP 500 (Internal Server Error)', () {
      // 1. Arrange: DioException badResponse dengan status code 500
      final error = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/comments'),
          statusCode: 500,
        ),
      );

      // 2. Act: Memanggil fungsi pemeta pesan error
      final message = getFriendlyCommentErrorMessage(error);

      // 3. Assert: Memastikan pesan memuat keterangan error 500 server
      expect(message, contains('500'));
      expect(message, contains('kesalahan pada server'));
    });
  });
}
