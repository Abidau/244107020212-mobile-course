/// Model data [Comment] yang merepresentasikan response dari endpoint GET /comments?postId={id}
/// pada API JSONPlaceholder.
class Comment {
  /// Unique identifier untuk Post yang memiliki komentar ini.
  final int postId;

  /// Unique identifier untuk Komentar.
  final int id;

  /// Nama pembuat komentar.
  final String name;

  /// Email pembuat komentar.
  final String email;

  /// Isi pesan/konten dari komentar.
  final String body;

  /// Constructor utama untuk class [Comment] dengan parameter required.
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  /// Factory constructor [fromJson] untuk melakukan konversi data `Map<String, dynamic>` dari JSON
  /// menjadi objek [Comment] secara aman dari nilai null (null-safe).
  ///
  /// Menggunakan konversi tipe dengan fallback (default value) jika key tidak ada atau bernilai null:
  /// - `postId`: fallback ke 0
  /// - `id`: fallback ke 0
  /// - `name`: fallback ke string kosong ''
  /// - `email`: fallback ke string kosong ''
  /// - `body`: fallback ke string kosong ''
  factory Comment.fromJson(Map<String, dynamic>? json) {
    // Jika json bernilai null (misalnya payload bermasalah), kembalikan objek Comment default
    if (json == null) {
      return const Comment(
        postId: 0,
        id: 0,
        name: '',
        email: '',
        body: '',
      );
    }

    return Comment(
      // Mengonversi json['postId'] ke int secara aman, berikan nilai default 0 jika null/missing
      postId: (json['postId'] is num)
          ? (json['postId'] as num).toInt()
          : int.tryParse(json['postId']?.toString() ?? '') ?? 0,

      // Mengonversi json['id'] ke int secara aman, berikan nilai default 0 jika null/missing
      id: (json['id'] is num)
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,

      // Mengonversi json['name'] ke String secara aman, berikan string kosong jika null/missing
      name: json['name']?.toString() ?? '',

      // Mengonversi json['email'] ke String secara aman, berikan string kosong jika null/missing
      email: json['email']?.toString() ?? '',

      // Mengonversi json['body'] ke String secara aman, berikan string kosong jika null/missing
      body: json['body']?.toString() ?? '',
    );
  }

  /// Mengonversi objek [Comment] menjadi `Map<String, dynamic>` untuk serialisasi ke JSON.
  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'id': id,
      'name': name,
      'email': email,
      'body': body,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        other.postId == postId &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.body == body;
  }

  @override
  int get hashCode => Object.hash(postId, id, name, email, body);

  @override
  String toString() {
    return 'Comment(postId: $postId, id: $id, name: $name, email: $email, body: $body)';
  }
}
