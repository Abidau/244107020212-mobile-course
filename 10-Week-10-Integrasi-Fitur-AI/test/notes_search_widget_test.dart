import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/features/notes/domain/entities/note.dart';
import 'package:week7_clean_architecture/features/notes/presentation/pages/notes_page.dart';
import 'package:week7_clean_architecture/features/notes/presentation/providers/notes_providers.dart';

void main() {
  final testNotes = [
    Note(
      id: 1,
      title: 'Belanja Pasar Tradisional',
      body: 'Beli bumbu dan sayur segar.',
      updatedAt: DateTime(2026, 10, 25, 10, 0),
    ),
    Note(
      id: 2,
      title: 'Belajar Flutter Riverpod',
      body: 'State management Clean Architecture.',
      updatedAt: DateTime(2026, 10, 26, 11, 0),
    ),
  ];

  Widget createTestWidget({List<Note> notes = const []}) {
    return ProviderScope(
      overrides: [notesProvider.overrideWith((ref) async => notes)],
      child: const MaterialApp(home: NotesPage()),
    );
  }

  group('Widget Test: Notes Page Search & Empty States', () {
    testWidgets('menampilkan NotesEmptyState ketika database catatan kosong', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(notes: []));
      await tester.pumpAndSettle();

      expect(find.byType(NotesEmptyState), findsOneWidget);
      expect(find.text('Belum ada catatan.'), findsOneWidget);
      expect(find.byType(NotesList), findsNothing);
    });

    testWidgets('menampilkan daftar catatan ketika data tersedia', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(notes: testNotes));
      await tester.pumpAndSettle();

      expect(find.byType(NotesList), findsOneWidget);
      expect(find.text('Belanja Pasar Tradisional'), findsOneWidget);
      expect(find.text('Belajar Flutter Riverpod'), findsOneWidget);
      expect(find.byType(NotesEmptyState), findsNothing);
      expect(find.byType(NotesSearchEmptyState), findsNothing);
    });

    testWidgets(
      'menampilkan NotesSearchEmptyState ketika pencarian tidak menemukan hasil',
      (tester) async {
        await tester.pumpWidget(createTestWidget(notes: testNotes));
        await tester.pumpAndSettle();

        // Masukkan kata kunci yang tidak ada di daftar
        final searchField = find.byKey(const Key('search_notes_field'));
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, 'zzz-tak-ada');
        await tester.pumpAndSettle();

        // Empty state pencarian harus muncul
        expect(find.byType(NotesSearchEmptyState), findsOneWidget);
        expect(find.text('Tidak ada catatan yang cocok'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(NotesSearchEmptyState),
            matching: find.textContaining('zzz-tak-ada'),
          ),
          findsOneWidget,
        );
        expect(find.byType(NotesList), findsNothing);
      },
    );

    testWidgets('tombol Reset Pencarian mengembalikan seluruh daftar catatan', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(notes: testNotes));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('search_notes_field'));
      await tester.enterText(searchField, 'zzz-tak-ada');
      await tester.pumpAndSettle();

      expect(find.byType(NotesSearchEmptyState), findsOneWidget);

      // Tekan tombol Reset Pencarian
      final resetButton = find.byKey(const Key('reset_search_button'));
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Daftar catatan kembali muncul utuh
      expect(find.byType(NotesList), findsOneWidget);
      expect(find.text('Belanja Pasar Tradisional'), findsOneWidget);
      expect(find.text('Belajar Flutter Riverpod'), findsOneWidget);
      expect(find.byType(NotesSearchEmptyState), findsNothing);
    });

    testWidgets(
      'memfilter catatan secara real-time berdasarkan query yang cocok',
      (tester) async {
        await tester.pumpWidget(createTestWidget(notes: testNotes));
        await tester.pumpAndSettle();

        final searchField = find.byKey(const Key('search_notes_field'));
        await tester.enterText(searchField, 'Riverpod');
        await tester.pumpAndSettle();

        // Hanya catatan kedua yang tampil
        expect(find.text('Belajar Flutter Riverpod'), findsOneWidget);
        expect(find.text('Belanja Pasar Tradisional'), findsNothing);

        // Tekan icon clear pada text field
        final clearButton = find.byKey(const Key('clear_search_button'));
        expect(clearButton, findsOneWidget);
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Kedua catatan tampil kembali
        expect(find.text('Belanja Pasar Tradisional'), findsOneWidget);
        expect(find.text('Belajar Flutter Riverpod'), findsOneWidget);
      },
    );
  });
}
