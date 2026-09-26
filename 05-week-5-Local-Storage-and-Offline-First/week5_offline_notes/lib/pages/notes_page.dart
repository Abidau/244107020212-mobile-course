import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/note_repository.dart';
import '../data/local/note.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';

// Providers

final noteRepositoryProvider = Provider((ref) => NoteRepository());

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() =>
      ref.watch(noteRepositoryProvider).fetchNotes();

  Future<void> addNote(String title) async {
    await ref.read(noteRepositoryProvider).addNote(title: title);
    ref.invalidateSelf();
  }

  Future<void> deleteNote(int id) async {
    await ref.read(noteRepositoryProvider).deleteNote(id);
    ref.invalidateSelf();
  }
}

final dirtyCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.countDirty();
});

// UI

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyCountAsync = ref.watch(dirtyCountProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Saya'),
        actions: [
          // Toggle simulasi offline
          IconButton(
            tooltip: forceOffline ? 'Mode: Offline (paksa)' : 'Mode: Online',
            icon: Icon(
              forceOffline ? Icons.wifi_off : Icons.wifi,
              color: forceOffline ? Colors.red : Colors.green,
            ),
            onPressed: () {
              ref.read(forceOfflineProvider.notifier).toggle();
            },
          ),
          // Badge jumlah dirty
          dirtyCountAsync.when(
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Chip(
                      avatar: const Icon(Icons.cloud_off, size: 16),
                      label: Text('$count belum sync'),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Tombol sync manual
          IconButton(
            tooltip: 'Sinkronkan catatan',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final repo = ref.read(noteRepositoryProvider);
              final synced = await syncNotes(
                repo,
                forceOffline: ref.read(forceOfflineProvider),
              );
              ref.invalidate(notesProvider);
              ref.invalidate(dirtyCountProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      synced > 0
                          ? '$synced catatan berhasil disinkronkan'
                          : 'Tidak ada catatan untuk disinkronkan',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('Belum ada catatan'));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteTile(
                note: note,
                onLongPress: () async {
                  if (note.id != null) {
                    await ref.read(notesProvider.notifier).deleteNote(note.id!);
                    ref.invalidate(dirtyCountProvider);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final controller = TextEditingController();
          final title = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Catatan Baru'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Judul catatan'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          );

          if (title != null && title.trim().isNotEmpty) {
            await ref.read(notesProvider.notifier).addNote(title.trim());
            ref.invalidate(dirtyCountProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}