import '../entities/note.dart';

/// UseCase murni Dart untuk memfilter catatan berdasarkan judul.
/// Sesuai prinsip Clean Architecture (Domain Layer):
/// - Tidak mengimpor Flutter SDK (material/widgets).
/// - Tidak mengimpor database (sqflite) atau network (dio).
/// - Murni logika bisnis / aturan penyaringan.
class SearchNotes {
  const SearchNotes();

  /// Menyaring daftar [notes] berdasarkan [query] pada [Note.title].
  ///
  /// Aturan filter:
  /// 1. Query dinormalisasi dengan `.trim().toLowerCase()`.
  /// 2. Jika query kosong setelah di-trim, seluruh [notes] dikembalikan utuh.
  /// 3. Pencarian bersifat case-insensitive dan mencocokkan substring judul.
  List<Note> call(List<Note> notes, String query) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      return note.title.toLowerCase().contains(trimmedQuery);
    }).toList();
  }
}
