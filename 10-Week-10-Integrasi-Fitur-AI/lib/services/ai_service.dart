import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service untuk menangani komunikasi dengan Google Gemini AI API
/// Dilengkapi dengan:
/// - Enkripsi penyimpanan API key (Keystore/Keychain)
/// - Caching lokal respons untuk menekan biaya API (Screenshot 5: Mitigasi Biaya)
/// - Pembatasan kuota request harian (Screenshot 5: Batasi request per user/hari)
/// - Fallback respons offline ketika API down atau tidak ada jaringan
class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;

  // Endpoint Gemini API (Gemini 1.5 Flash mendukung input teks, gambar, dan audio)
  final String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  final String _streamApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent';

  // Cache lokal in-memory untuk mencegah biaya ganda pada prompt yang sama
  final Map<String, String> _responseCache = {};

  // Batas kuota request per hari untuk mitigasi biaya melonjak
  static const int maxRequestsPerDay = 50;

  AiService({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  /// Memeriksa dan mencatat kuota penggunaan harian (Mitigasi Risiko Biaya)
  Future<void> _checkAndUpdateQuota() async {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final savedDate = await _storage.read(key: 'ai_quota_date');
    final savedCountStr = await _storage.read(key: 'ai_quota_count');

    int currentCount = 0;
    if (savedDate == todayKey && savedCountStr != null) {
      currentCount = int.tryParse(savedCountStr) ?? 0;
    }

    if (currentCount >= maxRequestsPerDay) {
      throw Exception(
        'Batas kuota harian tercapai ($maxRequestsPerDay request/hari). '
        'Coba lagi besok atau gunakan mode offline.',
      );
    }

    await _storage.write(key: 'ai_quota_date', value: todayKey);
    await _storage.write(key: 'ai_quota_count', value: '${currentCount + 1}');
  }

  /// Praktikum Langkah 2: Mengirim prompt ke Gemini AI API (Non-Streaming)
  Future<String> ask(String question) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final trimmed = question.trim();

    // 1. Cek Cache Lokal (Menghemat Biaya Token)
    if (_responseCache.containsKey(trimmed)) {
      return _responseCache[trimmed]!;
    }

    // 2. Cek Kuota Harian
    await _checkAndUpdateQuota();

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': trimmed}
            ]
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      _responseCache[trimmed] = text;
      return text;
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
  }

  /// Praktikum Langkah 3: Streaming response secara real-time dari AI API menggunakan SSE
  Stream<String> askStream(String question) async* {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final trimmed = question.trim();

    // Jika sudah ada di cache lokal, langsung kirim utuh
    if (_responseCache.containsKey(trimmed)) {
      yield _responseCache[trimmed]!;
      return;
    }

    // Periksa batas kuota harian
    await _checkAndUpdateQuota();

    final request = http.Request(
      'POST',
      Uri.parse('$_streamApiUrl?alt=sse&key=$apiKey'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': trimmed}
          ]
        }
      ],
    });

    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      throw Exception(
        'Gagal memanggil AI API: ${streamedResponse.statusCode} - $body',
      );
    }

    final fullResponseBuffer = StringBuffer();

    // Mendengarkan chunks stream secara asinkron
    final lines = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6).trim();
        if (jsonStr.isEmpty) continue;
        try {
          final data = jsonDecode(jsonStr);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.isNotEmpty) {
                fullResponseBuffer.write(text);
                yield text;
              }
            }
          }
        } catch (_) {
          // Lanjutkan jika format baris SSE kosong / komentar
        }
      }
    }

    // Simpan hasil akhir ke cache
    if (fullResponseBuffer.isNotEmpty) {
      _responseCache[trimmed] = fullResponseBuffer.toString();
    }
  }

  /// Praktikum Bagian 4: OCR (Optical Character Recognition)
  Future<String> recognizeText(dynamic imageFile) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    await _checkAndUpdateQuota();

    final bytes = await _extractBytes(imageFile);
    final mimeType = _detectImageMimeType(imageFile);
    final base64Image = base64Encode(bytes);

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Lakukan OCR (Optical Character Recognition) pada gambar ini. '
                    'Ekstrak seluruh teks yang terbaca (seperti pada KTM, struk/receipt, dokumen, atau papan pengumuman) '
                    'secara akurat dan terstruktur tanpa menambah kata pengantar pembuka atau penutup.'
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gagal melakukan OCR melalui AI API: ${response.statusCode}');
    }
  }

  /// Praktikum Bagian 4: Image Understanding
  Future<String> describeImage(dynamic imageFile, {String? prompt}) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    await _checkAndUpdateQuota();

    final bytes = await _extractBytes(imageFile);
    final mimeType = _detectImageMimeType(imageFile);
    final base64Image = base64Encode(bytes);

    final instruction = prompt ??
        'Deskripsikan objek dan isi gambar ini secara detail dan terstruktur untuk '
        'kebutuhan identifikasi objek, deskripsi produk, atau aksesibilitas.';

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': instruction},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gagal menganalisis gambar: ${response.statusCode}');
    }
  }

  /// Praktikum Bagian 4: Speech-to-Text
  Future<String> speechToText(dynamic audioFile) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    await _checkAndUpdateQuota();

    final bytes = await _extractBytes(audioFile);
    final mimeType = _detectAudioMimeType(audioFile);
    final base64Audio = base64Encode(bytes);

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Lakukan Speech-to-Text (transkripsi audio suara) secara persis dan akurat. '
                    'Tuliskan kembali ucapan suara dalam teks bahasa Indonesia atau bahasa asalnya tanpa teks pengantar.'
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Audio,
                }
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gagal melakukan Speech-to-Text: ${response.statusCode}');
    }
  }

  /// Praktikum Bagian 5: Fallback Respons Offline ketika AI Down / Error / Jaringan Terputus
  String getOfflineFallback(String question) {
    final lower = question.toLowerCase();

    if (lower.contains('clean arch') || lower.contains('arsitektur')) {
      return '[Mode Offline]: Clean Architecture membagi kode menjadi 3 layer independen: '
          'Presentation (UI/Widget & Provider), Domain (Entities & Use Cases murni Dart), '
          'dan Data (Models, Data Sources, Repositories Implementation). Aturan dependensi '
          'selalu mengarah ke dalam (Domain tidak bergantung layer lain).';
    }

    if (lower.contains('riverpod') || lower.contains('state')) {
      return '[Mode Offline]: Riverpod adalah state management deklaratif compile-safe untuk Flutter. '
          'Gunakan Provider untuk data immutable, NotifierProvider untuk state dinamis, '
          'dan AsyncNotifierProvider untuk data asinkron/jaringan.';
    }

    if (lower.contains('api key') || lower.contains('keamanan') || lower.contains('privasi')) {
      return '[Mode Offline]: Kunci API wajib disimpan dalam FlutterSecureStorage (Keystore/Keychain), '
          'bukan di SharedPreferences plain-text. Jangan pernah mengirimkan NIK, telepon, atau alamat '
          'pengguna langsung ke AI API.';
    }

    if (lower.contains('ringkas') || lower.contains('catatan')) {
      return '[Mode Offline]: Catatan Anda tersimpan aman secara offline di database lokal SQLite. '
          'Anda dapat meninjau, mengedit, dan mencari catatan kapan saja tanpa koneksi internet.';
    }

    return '[Mode Offline]: Layanan AI saat ini tidak dapat dihubungi. '
        'Aplikasi dialihkan ke pangkalan pengetahuan lokal offline. '
        'Silakan periksa koneksi internet Anda atau coba kembali nanti.';
  }

  /// Helper untuk mengekstrak byte array dari berbagai jenis input file
  Future<List<int>> _extractBytes(dynamic file) async {
    if (file is List<int>) {
      return file;
    }
    if (file is XFile) {
      return await file.readAsBytes();
    }
    if (file is io.File) {
      return await file.readAsBytes();
    }
    if (file is String) {
      return await io.File(file).readAsBytes();
    }
    throw ArgumentError('Tipe berkas tidak didukung: ${file.runtimeType}');
  }

  /// Helper deteksi mime type gambar
  String _detectImageMimeType(dynamic file) {
    String? path;
    if (file is XFile) path = file.path;
    if (file is io.File) path = file.path;
    if (file is String) path = file;

    if (path != null) {
      final ext = path.split('.').last.toLowerCase();
      if (ext == 'png') return 'image/png';
      if (ext == 'webp') return 'image/webp';
      if (ext == 'gif') return 'image/gif';
      if (ext == 'bmp') return 'image/bmp';
    }
    return 'image/jpeg';
  }

  /// Helper deteksi mime type audio
  String _detectAudioMimeType(dynamic file) {
    String? path;
    if (file is XFile) path = file.path;
    if (file is io.File) path = file.path;
    if (file is String) path = file;

    if (path != null) {
      final ext = path.split('.').last.toLowerCase();
      if (ext == 'wav') return 'audio/wav';
      if (ext == 'aac') return 'audio/aac';
      if (ext == 'm4a') return 'audio/m4a';
      if (ext == 'ogg') return 'audio/ogg';
    }
    return 'audio/mp3';
  }

  /// Mengambil informasi kuota request hari ini
  Future<int> getTodayUsageCount() async {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final savedDate = await _storage.read(key: 'ai_quota_date');
    if (savedDate == todayKey) {
      final count = await _storage.read(key: 'ai_quota_count');
      return int.tryParse(count ?? '0') ?? 0;
    }
    return 0;
  }

  /// Praktikum Langkah 2: Menyimpan API Key ke FlutterSecureStorage
  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key.trim());
  }

  /// Membaca API Key dari Secure Storage
  Future<String?> getApiKey() async {
    return await _storage.read(key: 'ai_api_key');
  }

  /// Menghapus API Key dari Secure Storage
  Future<void> deleteApiKey() async {
    await _storage.delete(key: 'ai_api_key');
  }
}
