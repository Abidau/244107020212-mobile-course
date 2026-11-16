import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/domain/usecases/search_notes.dart';

void main() {
  late SearchNotes searchNotes;
  late List<Note> sampleNotes;

  setUp(() {
    searchNotes = const SearchNotes();
    sampleNotes = [
      Note(
        id: 1,
        title: 'Belanja Mingguan Pasar',
        body: 'Beli sayur, buah, dan susu.',
        updatedAt: DateTime(2026, 10, 20, 9, 30),
      ),
      Note(
        id: 2,
        title: 'Tugas Kuliah Flutter Clean Arch',
        body: 'Selesaikan modul praktikum dan testing.',
        updatedAt: DateTime(2026, 10, 21, 14, 0),
      ),
      Note(
        id: 3,
        title: 'Rencana Belanja Elektronik',
        body: 'Cari keyboard mechanical dan mouse.',
        updatedAt: DateTime(2026, 10, 22, 18, 15),
      ),
      Note(
        id: 4,
        title: 'Ide Proyek Akhir',
        body: 'Aplikasi manajemen kampus berbasis FCM.',
        updatedAt: DateTime(2026, 10, 23, 11, 45),
      ),
    ];
  });

  group('Praktikum 2 & 3: SearchNotes Domain UseCase Unit Tests', () {
    test('filter abaikan huruf besar/kecil (case-insensitive test bukti)', () {
      // Query huruf kecil 'belanja' harus mencocokkan 'Belanja Mingguan Pasar' & 'Rencana Belanja Elektronik'
      final result = searchNotes(sampleNotes, 'belanja');
      expect(result, hasLength(2));
      expect(result[0].title, 'Belanja Mingguan Pasar');
      expect(result[1].title, 'Rencana Belanja Elektronik');
    });

    test('query tak cocok kembalikan kosong', () {
      final result = searchNotes(sampleNotes, 'zzz-tak-ada');
      expect(result, isEmpty);
    });

    test('query string kosong mengembalikan semua catatan utuh', () {
      final result = searchNotes(sampleNotes, '');
      expect(result, hasLength(4));
      expect(result, equals(sampleNotes));
    });

    test('query dengan spasi di awal atau akhir tetap mencocokkan kata kunci (trimming)', () {
      final result = searchNotes(sampleNotes, '  flutter  ');
      expect(result, hasLength(1));
      expect(result.first.title, 'Tugas Kuliah Flutter Clean Arch');
    });

    test('query hanya spasi whitespace mengembalikan semua catatan utuh', () {
      // Mencegah bug di mana spasi membuat filter kosong atau halusinasi substring
      final result = searchNotes(sampleNotes, '    ');
      expect(result, hasLength(4));
    });

    test('pencarian substring di tengah kata berhasil dicocokkan', () {
      final result = searchNotes(sampleNotes, 'elektronik');
      expect(result, hasLength(1));
      expect(result.first.title, 'Rencana Belanja Elektronik');
    });

    test(
      'daftar catatan kosong kembalikan list kosong tanpa melempar Exception',
      () {
        final result = searchNotes([], 'belanja');
        expect(result, isEmpty);
      },
    );
  });
}
