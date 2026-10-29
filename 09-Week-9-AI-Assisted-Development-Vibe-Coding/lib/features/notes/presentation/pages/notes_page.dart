import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';

/// Halaman Catatan (Clean Architecture - Presentation Layer)
/// Menampilkan daftar catatan dengan kemampuan pencarian judul real-time dan empty state.
/// Seluruh logika filter didelegasikan ke [SearchNotes] usecase via Riverpod.
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredState = ref.watch(filteredNotesProvider);
    final allNotesState = ref.watch(notesProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline (Clean Arch)'),
        actions: [
          IconButton(
            key: const Key('refresh_button'),
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(notesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          const NotesSearchBar(),
          Expanded(
            child: filteredState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: '$err',
                onRetry: () => ref.invalidate(notesProvider),
              ),
              data: (filteredNotes) {
                final allNotes = allNotesState.value ?? [];
                if (allNotes.isEmpty) {
                  return const NotesEmptyState();
                }
                if (filteredNotes.isEmpty && currentQuery.trim().isNotEmpty) {
                  return NotesSearchEmptyState(query: currentQuery);
                }
                return NotesList(notes: filteredNotes);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_note_fab'),
        onPressed: () =>
            showDialog(context: context, builder: (_) => const AddNoteDialog()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Widget pencarian judul catatan mandiri dengan controller terisolasi.
class NotesSearchBar extends ConsumerStatefulWidget {
  const NotesSearchBar({super.key});

  @override
  ConsumerState<NotesSearchBar> createState() => _NotesSearchBarState();
}

class _NotesSearchBarState extends ConsumerState<NotesSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState({Key? key}) {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onClear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    if (_controller.text != query) {
      _controller.text = query;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        key: const Key('search_notes_field'),
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Cari judul catatan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  key: const Key('clear_search_button'),
                  icon: const Icon(Icons.close),
                  onPressed: _onClear,
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onChanged: (val) {
          ref.read(searchQueryProvider.notifier).setQuery(val);
        },
      ),
    );
  }
}

/// Tampilan ketika belum ada satupun catatan di database lokal.
class NotesEmptyState extends StatelessWidget {
  const NotesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Belum ada catatan.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            'Tekan tombol + di pojok kanan bawah untuk menambah catatan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// Tampilan empty state ketika filter pencarian tidak menemukan hasil.
class NotesSearchEmptyState extends ConsumerWidget {
  const NotesSearchEmptyState({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada catatan yang cocok',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kata kunci "$query" tidak ditemukan di judul catatan mana pun.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('reset_search_button'),
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Pencarian'),
              onPressed: () {
                ref.read(searchQueryProvider.notifier).clear();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan error jika fetching catatan gagal.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daftar list card catatan.
class NotesList extends StatelessWidget {
  const NotesList({super.key, required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final timeText = formatRelativeTime(note.updatedAt);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            title: Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note.body),
                ],
                const SizedBox(height: 6),
                Text(
                  timeText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: note.dirty
                ? const Chip(
                    label: Text('Offline', style: TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// Dialog tambah catatan baru terisolasi.
class AddNoteDialog extends ConsumerStatefulWidget {
  const AddNoteDialog({super.key});

  @override
  ConsumerState<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends ConsumerState<AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text;
    final body = _bodyController.text;
    final addNote = ref.read(addNoteProvider);
    final result = await addNote(title: title, body: body);

    if (!mounted) return;

    if (result.failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failure!.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } else {
      Navigator.of(context).pop();
      ref.invalidate(notesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Catatan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('note_title_input'),
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Judul',
              hintText: 'Masukkan judul catatan',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('note_body_input'),
            controller: _bodyController,
            decoration: const InputDecoration(
              labelText: 'Isi',
              hintText: 'Masukkan isi catatan',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          key: const Key('save_note_button'),
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
