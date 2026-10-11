import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/domain/repositories/note_repository.dart';
import 'package:week7_clean_architecture/features/notes/domain/usecases/add_note.dart';

class MockNoteRepository implements NoteRepository {
  bool addNoteCalled = false;
  String? lastTitle;
  String? lastBody;

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    addNoteCalled = true;
    lastTitle = title;
    lastBody = body;
    return (
      note: Note(
        id: 1,
        title: title,
        body: body,
        updatedAt: DateTime(2026, 10, 11),
      ),
      failure: null,
    );
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() =>
      throw UnimplementedError();
}

void main() {
  late MockNoteRepository repository;
  late AddNote addNote;

  setUp(() {
    repository = MockNoteRepository();
    addNote = AddNote(repository);
  });

  test('AddNote berhasil menambahkan catatan ketika judul valid', () async {
    final result = await addNote(
      title: 'Tugas Clean Architecture',
      body: 'Selesaikan laporan dan screenshot',
    );

    expect(result.failure, isNull);
    expect(result.note, isNotNull);
    expect(result.note!.title, 'Tugas Clean Architecture');
    expect(repository.addNoteCalled, isTrue);
    expect(repository.lastTitle, 'Tugas Clean Architecture');
  });

  test('AddNote mengembalikan ValidationFailure/LocalFailure ketika judul kosong', () async {
    final result = await addNote(
      title: '   ',
      body: 'Tanpa judul',
    );

    expect(result.failure, isA<LocalFailure>());
    expect(result.note, isNull);
    expect(repository.addNoteCalled, isFalse);
  });
}
