import 'dart:convert';

class Post {
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  final int userId;
  final int id;
  final String title;
  final String body;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'id': id,
        'title': title,
        'body': body,
      };

  // ---------- Tambahan untuk cache SQLite (tabel cached_posts) ----------

  /// Ubah jadi baris yang cocok dengan skema tabel `cached_posts`:
  /// id INTEGER, payload TEXT, cached_at TEXT
  Map<String, Object?> toMap() => {
        'id': id,
        'payload': jsonEncode(toJson()), // simpan seluruh objek sebagai JSON string
        'cached_at': DateTime.now().toIso8601String(),
      };

  /// Baca kembali dari baris tabel `cached_posts` menjadi objek Post
  factory Post.fromRow(Map<String, Object?> row) {
    final decoded = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    return Post.fromJson(decoded);
  }
}