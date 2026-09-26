import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'local/db.dart';
import 'local/post.dart';
import 'repositories/note_repository.dart';

// ================= Cache-first Posts =================

Future<List<Post>> readCachedPosts() async {
  final db = await openNotesDb();
  final rows = await db.query('cached_posts', orderBy: 'id ASC');
  return rows.map(Post.fromRow).toList();
}

Future<void> saveCachedPosts(List<Post> posts) async {
  final db = await openNotesDb();
  final batch = db.batch();
  batch.delete('cached_posts');
  for (final post in posts) {
    batch.insert('cached_posts', post.toMap());
  }
  await batch.commit(noResult: true);
}

Future<void> refreshPostsInBackground({bool forceOffline = false}) async {
  if (forceOffline) return; // simulasi offline: jangan fetch network

  try {
    final dio = Dio();
    final response = await dio.get(
      'https://jsonplaceholder.typicode.com/posts',
    );
    final data = response.data as List;
    final posts = data
        .take(20)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
    await saveCachedPosts(posts);
  } catch (_) {
    // gagal fetch (offline/error jaringan) -> biarkan cache lama tetap dipakai
  }
}

Future<List<Post>> loadPostsCacheFirst({bool forceOffline = false}) async {
  final cached = await readCachedPosts();
  // 1. Segera kembalikan cache agar UI tidak blank saat offline.
  // 2. Di background: fetch -> simpan ke cached_posts (tidak di-await).
  refreshPostsInBackground(forceOffline: forceOffline);
  return cached;
}

// ================= Sync Notes (dirty) =================

Future<int> syncNotes(NoteRepository repo, {bool forceOffline = false}) async {
  if (forceOffline) return 0; // simulasi offline: tidak melakukan sync

  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;

  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}