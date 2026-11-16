import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/domain/repositories/note_repository.dart';
import 'package:week7_clean_architecture/features/notes/domain/usecases/add_note.dart';

class FakeNoteRepository implements NoteRepository {
  bool addNoteCalled = false;
  String? savedTitle;
  String? savedBody;

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addNoteCalled = true;
    savedTitle = title;
    savedBody = body;
    return (
      note: Note(
        id: 99,
        title: title,
        body: body,
        updatedAt: DateTime(2026, 10, 29),
      ),
      failure: null,
    );
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    throw UnimplementedError();
  }
}

void main() {
  group('Validate Note UseCase & Domain Unit Tests', () {
    late FakeNoteRepository fakeRepo;
    late AddNote addNote;

    setUp(() {
      fakeRepo = FakeNoteRepository();
      addNote = AddNote(fakeRepo);
    });

    test('Validasi gagal ketika judul string kosong ""', () async {
      final result = await addNote(title: '', body: 'Catatan tanpa judul');

      expect(result.failure, isA<LocalFailure>());
      expect(result.failure?.message, 'Judul catatan tidak boleh kosong.');
      expect(result.note, isNull);
      expect(fakeRepo.addNoteCalled, isFalse);
    });

    test(
      'Validasi gagal ketika judul hanya spasi dan karakter whitespace',
      () async {
        final result = await addNote(title: '    \t \n  ', body: 'Isi catatan');

        expect(result.failure, isA<LocalFailure>());
        expect(result.failure?.message, 'Judul catatan tidak boleh kosong.');
        expect(result.note, isNull);
        expect(fakeRepo.addNoteCalled, isFalse);
      },
    );

    test('Validasi berhasil dan melakukan trim pada judul dan isi', () async {
      final result = await addNote(
        title: '   Review Pertengahan Semester   ',
        body: '   Persiapan evaluasi sprint 8   ',
      );

      expect(result.failure, isNull);
      expect(result.note, isNotNull);
      expect(fakeRepo.addNoteCalled, isTrue);
      expect(fakeRepo.savedTitle, 'Review Pertengahan Semester');
      expect(fakeRepo.savedBody, 'Persiapan evaluasi sprint 8');
    });

    test('Validasi berhasil dengan body kosong default', () async {
      final result = await addNote(title: 'Judul Saja');

      expect(result.failure, isNull);
      expect(result.note, isNotNull);
      expect(fakeRepo.addNoteCalled, isTrue);
      expect(fakeRepo.savedTitle, 'Judul Saja');
      expect(fakeRepo.savedBody, '');
    });
  });
}
