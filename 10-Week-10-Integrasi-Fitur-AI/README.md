# Laporan Praktikum Minggu 10: Integrasi Fitur AI (AI Feature Integration)

| Parameter | Data Mahasiswa |
|:---|:---|
| **Mata Kuliah** | Pemrograman Mobile |
| **NIM** | 244107020212 |
| **Nama** | Naufal Abid Aurizky |
| **Kelas** | TI - 3G |
| **Topik Praktikum** | Minggu 10: Integrasi Fitur AI (Chat Interface, OCR, Speech-to-Text, Vision, Privacy & Fallback) |
| **Repositori / Direktori** | `10-Week-10-Integrasi-Fitur-AI` |

---

## 1. Pendahuluan & Tujuan Pembelajaran

Praktikum Minggu 10 berfokus pada **Integrasi Fitur Kecerdasan Buatan (*Artificial Intelligence*)** ke dalam aplikasi mobile Flutter. Setelah pada minggu sebelumnya mempelajari alur kerja pengembangan berbantuan AI (*AI-assisted development*), pada minggu ini mahasiswa secara langsung menghubungkan dan menanamkan kapabilitas AI (khususnya *Generative AI / Large Language Model* seperti Google Gemini 1.5 Flash) ke dalam antarmuka aplikasi.

### Tujuan Pembelajaran:
1. Memahami arsitektur integrasi AI API pada aplikasi mobile berbasis Flutter.
2. Mengonfigurasi dependensi jaringan (`http`), penyimpanan aman (`flutter_secure_storage`), pemilihan gambar (`image_picker`), dan perekaman audio (`record`) pada `pubspec.yaml`.
3. Membangun service abstraksi AI (`lib/services/ai_service.dart`) yang memanggil REST API AI endpoint dengan enkripsi penyimpanan kredensial.
4. Mengembangkan antarmuka obrolan (*Chat Interface*) pada `lib/features/chat_screen.dart` dengan fitur *streaming response* dan indikator *loading* yang interaktif.
5. Menerapkan fitur **Multimodal AI** (`lib/features/multimodal_screen.dart`):
   - **OCR (Optical Character Recognition):** Ekstraksi teks dari foto dokumen, struk kuitansi, atau KTM.
   - **Speech-to-Text (STT):** Konversi rekaman suara menjadi teks tertulis untuk input cepat dan aksesibilitas.
   - **Image Understanding:** Pemahaman konten visual, identifikasi objek, dan deskripsi produk.
6. Menerapkan manajemen risiko, perlindungan privasi data pengguna (*Data Sanitization & Redaction*), mitigasi lonjakan biaya (*rate limit & local cache*), serta strategi *fallback* jika API mengalami *downtime*.
7. Memvalidasi kebenaran kode melalui pengujian otomatis (*Unit Testing* & *Widget Testing*) dengan bukti mesin bersih (*green build*).

---

## 2. Dependensi Proyek ([`pubspec.yaml`](pubspec.yaml))

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Dependensi Inti Integrasi Fitur AI:
  http: ^1.2.1                  # Komunikasi REST API & SSE Streaming
  flutter_secure_storage: ^9.0.0 # Enkripsi Keystore/Keychain untuk API Key
  riverpod: ^2.5.0              # State management deklaratif
  flutter_riverpod: ^2.5.1      # Integrasi Riverpod pada Flutter UI
  image_picker: ^1.1.2          # Pengambilan foto dari Kamera & Galeri (OCR & Vision)
  record: ^5.1.2                # Perekaman audio mikrofon untuk Speech-to-Text

  # Dependensi Arsitektur & Penyimpanan Lokal:
  cupertino_icons: ^1.0.8
  sqflite: ^2.4.4+1
  path: ^1.9.1
  sqflite_common_ffi: ^2.4.3
  intl: ^0.20.3
  dio: ^5.11.1
  go_router: ^18.0.2
```

---

## 3. Praktikum Bagian 3: Chat Interface dengan AI

### A. Implementasi AI Service ([`lib/services/ai_service.dart`](lib/services/ai_service.dart))
`AiService` mengabstraksi pemanggilan REST API ke model Google Gemini (`gemini-1.5-flash`):
- Membaca API Key dari penyimpanan terenkripsi `FlutterSecureStorage`.
- Jika API key tidak ada, melempar eksepsi informatif: `Exception('API key tidak tersedia. Silakan atur di pengaturan.')`.
- Mengirimkan *prompt* teks dan mengurai respon JSON `candidates[0].content.parts[0].text`.
- Menyediakan metode `askStream(String question)` menggunakan Server-Sent Events (SSE) untuk menampilkan teks balasan kata demi kata secara *real-time*.

### B. Implementasi Chat Screen ([`lib/features/chat_screen.dart`](lib/features/chat_screen.dart))
- **Streaming Response:** Menggunakan `StreamSubscription` untuk mendengarkan potongan teks AI dan memperbarui bubble percakapan seketika dengan animasi auto-scroll.
- **Indikator Loading:** Menampilkan *spinner* animasi dan teks *"AI sedang merespon..."* saat transmisi data berlangsung.
- **Dialog Pengaturan API Key:** Pengguna dapat memasukkan, memperbarui, atau menghapus Gemini API Key melalui ikon kunci di AppBar tanpa perlu *hardcode* di kode sumber.

---

## 4. Praktikum Bagian 4: OCR, Speech-to-Text, dan Image Understanding

Sesuai panduan Codelab Minggu 10:
```dart
final result = await aiService.recognizeText(imageFile);
final text = await aiService.speechToText(audioFile);
```

### A. Tiga Pilar Multimodal AI
1. **OCR (Optical Character Recognition):**  
   Mengambil foto dokumen (KTM, kuitansi/struk belanja, surat resmi, papan pengumuman) menggunakan `image_picker`. Byte citra dikonversi menjadi *inline base64 payload* dan diproses oleh Gemini untuk menghasilkan teks terstruktur murni.
2. **Speech-to-Text (STT):**  
   Merekam suara pengguna secara lokal menggunakan pustaka `record` (format AAC/M4A), lalu mengirimkannya ke endpoint multimodal AI untuk ditranskripsikan menjadi teks bahasa Indonesia demi kemudahan input cepat dan aksesibilitas.
3. **Image Understanding (Vision AI):**  
   Menerima input citra produk atau objek umum, disertai prompt pertanyaan khusus, lalu memberikan deskripsi analitis mendalam tentang objek, merek, kondisi, atau panduan visual bagi tunanetra.

### B. Layar Antarmuka Multimodal ([`lib/features/multimodal_screen.dart`](lib/features/multimodal_screen.dart))
Menyediakan 3 tab interaktif (`TabBar`):
- **Tab OCR:** Kontrol kamera/galeri, pratinjau citra dokumen, tombol aksi *"Ekstrak Teks (OCR)"*, dan fitur salin teks hasil ekstraksi ke clipboard.
- **Tab Speech-to-Text:** Tombol mikrofon berdenyut dinamis, visualisasi status rekaman audio, dan tombol *"Konversi ke Teks AI"*.
- **Tab Vision:** Pemilih foto objek, kolom kustom prompt instruksi, dan tombol analisis gambar cerdas.

---

## 5. Praktikum Bagian 5: Privasi, Biaya, Error Handling, dan Fallback

### A. Tabel Risiko dan Mitigasi (Sesuai Panduan Modul)

| Risiko | Dampak Potensial | Mitigasi yang Diterapkan di Aplikasi |
|:---|:---|:---|
| **Bocor Data Pengguna** | Data pribadi sensitif (NIK, nomor telepon, alamat, email) tersimpan di server pihak ketiga atau log AI. | **Jangan kirim data sensitif ke AI API:** Menerapkan filter sanitasi regex di sisi klien (`_sanitizeInput`) yang menyensor NIK 16 digit menjadi `[REDACTED_NIK: 3507********9012]` dan nomor HP menjadi `[REDACTED_PHONE: 0812****]` sebelum data meninggalkan perangkat. |
| **Biaya Melonjak (*Cost Overrun*)** | Pemanggilan API berulang-ulang menghabiskan kuota gratis / menimbulkan tagihan membengkak. | **Batasi request per user/hari & gunakan cache lokal:**<br>1. Mengimplementasikan kuota maksimal 50 request/hari (`maxRequestsPerDay = 50`) yang dicatat di `FlutterSecureStorage`.<br>2. Menggunakan `_responseCache` lokal in-memory; jika prompt yang sama diajukan kembali, hasil diambil dari memori tanpa mengirim HTTP request baru. |
| **API Error / Down** | Server AI mengalami gangguan (HTTP 500, 503), kuota habis (HTTP 429), atau jaringan seluler mati. | **Tampilkan pesan ramah, opsi coba lagi, dialog fallback:** Menampilkan dialog peringatan ramah *"Layanan AI Sibuk"* dengan opsi coba lagi nanti atau beralih ke mode offline. |
| **Respons Tidak Relevan (Halusinasi)** | AI mengarang informasi yang tidak sesuai fakta aplikasi atau format keluaran rusak. | **Terapkan validasi dan fallback ke data lokal:** Memvalidasi struktur respon JSON, dan jika terjadi kegagalan/anomali, sistem mengarahkan jawaban ke *local knowledge base* (`getOfflineFallback`). |

### B. Implementasi Kode Fallback Dialog
Sesuai contoh pada Codelab Minggu 10 Bagian 5:

```dart
try {
  final response = await aiService.ask(question);
} catch (e) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Layanan AI Sibuk'),
      content: const Text('Coba lagi nanti atau gunakan mode offline.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              botMessage.isError = false;
              botMessage.text = _aiService.getOfflineFallback(question);
            });
          },
          icon: const Icon(Icons.offline_bolt_outlined, size: 18),
          label: const Text('Gunakan Mode Offline'),
        ),
      ],
    ),
  );
}
```

---

## 6. Mini Project / Industry Challenge (Bagian 6)

### A. Rincian Implementasi Tugas
1. **Integrasi Fitur AI ke Proyek:** Fitur Chat Assistant, OCR, Speech-to-Text, dan Vision terintegrasi langsung dengan menu navigasi [`NotesPage`](lib/features/notes/presentation/pages/notes_page.dart) pada Clean Architecture proyek catatan offline.
2. **Dokumentasi AI Log:** Berkas [`docs/ai-log.md`](docs/ai-log.md) telah disusun mencakup:
   - System Prompt asisten mobile.
   - User Prompts (Chat, OCR KTM, Transkripsi Audio, Deskripsi Objek).
   - Output awal AI sebelum verifikasi.
   - Bukti log penyamaran data sensitif (sanitasi NIK & telepon).
   - Log skenario penanganan error fallback ke mode offline.
3. **Struktur Berkas Repositori:**
   ```text
   10-Week-10-Integrasi-Fitur-AI/
   ├── docs/
   │   └── ai-log.md                     # Catatan prompt sistem, user prompt & output AI
   ├── lib/
   │   ├── features/
   │   │   ├── chat_screen.dart          # Antarmuka Chat Streaming & Sanitasi Privasi
   │   │   ├── multimodal_screen.dart    # Antarmuka OCR, STT, dan Image Understanding
   │   │   └── notes/                    # Fitur Notes Clean Architecture eksisting
   │   ├── services/
   │   │   └── ai_service.dart           # Service API Gemini, Caching, Kuota, & Fallback
   │   ├── main.dart
   │   └── routes.dart                   # Rute GoRouter (/chat, /multimodal)
   ├── screenshots/
   │   ├── 01_flutter_analyze_log.txt    # Bukti analisis statis bersih
   │   ├── 02_flutter_test_log.txt       # Bukti 45 pengujian lolos (All tests passed)
   │   └── README.md                     # Deskripsi skenario visual antarmuka
   ├── test/
   │   ├── ai_service_test.dart          # Unit test AI Service, OCR, STT, Quota, Cache
   │   ├── chat_screen_test.dart         # Widget test Chat UI, Sanitasi NIK, API Dialog
   │   ├── multimodal_screen_test.dart   # Widget test Tab OCR, STT, Vision
   │   └── ...                           # Pengujian regresi eksisting
   ├── pubspec.yaml
   └── README.md
   ```

---

## 7. Bukti Mesin Hijau (*Automated Verification*)

### A. Hasil `flutter analyze`
```text
Analyzing 10-Week-10-Integrasi-Fitur-AI...
No issues found! (ran in 4.2s)
```
*(Tercatat pada berkas [`screenshots/01_flutter_analyze_log.txt`](screenshots/01_flutter_analyze_log.txt))*

### B. Hasil `flutter test`
```text
00:00 +0: loading test/ai_service_test.dart
00:00 +1: AiService Unit Tests Throws Exception if API key is not set
00:00 +2: AiService Unit Tests Returns parsed response on successful 200 response
00:00 +3: AiService Unit Tests Throws Exception on non-200 status code
00:00 +4: AiService Unit Tests Saves, reads, and deletes API key correctly
00:00 +5: AiService Unit Tests recognizeText successfully extracts OCR text from image bytes
00:00 +6: AiService Unit Tests speechToText successfully transcribes audio bytes
00:00 +7: AiService Unit Tests describeImage successfully returns vision description
00:01 +8: loading test/chat_screen_test.dart
00:01 +9: ChatScreen Widget Tests Renders ChatScreen elements properly
00:01 +10: ChatScreen Widget Tests Sanitizes sensitive data (NIK and phone) before displaying/sending
00:01 +11: ChatScreen Widget Tests Opens API Key dialog when key icon is pressed
00:02 +12: loading test/multimodal_screen_test.dart
00:02 +13: MultimodalScreen Widget Tests Renders all 3 tabs: OCR, Speech-to-Text, Vision
00:02 +14: MultimodalScreen Widget Tests Switches to Speech-to-Text tab and shows recording controls
00:02 +15: MultimodalScreen Widget Tests Switches to Vision tab and shows image understanding controls
...
00:05 +44: Widget Test: Notes Page Search & Empty States memfilter catatan secara real-time berdasarkan query yang cocok
00:05 +45: All tests passed!
```
*(Tercatat pada berkas [`screenshots/02_flutter_test_log.txt`](screenshots/02_flutter_test_log.txt))*

---

## 8. Refleksi Mahasiswa (Jawaban 4 Pertanyaan Wajib)

Sesuai instruksi Codelab Minggu 10 Bagian 6, berikut adalah refleksi mendalam atas pelaksanaan praktikum:

### 1. Fitur AI mana yang Anda integrasikan dan mengapa?
> **Jawaban:**  
> Saya mengintegrasikan **AI Chat Assistant interaktif berbasis streaming**, dilengkapi kapabilitas multimodal **OCR Dokumen** dan **Speech-to-Text**.  
> **Alasan:** Pada konteks aplikasi pencatat (*Notes App*), pengguna membutuhkan interaksi cepat dan cerdas. Chat Assistant membantu merangkum materi dan menyusun ide catatan. Fitur OCR memungkinkan mahasiswa mendigitalkan teks dari Kartu Tanda Mahasiswa (KTM), kuitansi pembayaran kuliah, atau lembar catatan fisik tanpa mengetik manual. Sementara fitur Speech-to-Text memfasilitasi pembuatan catatan secara hands-free saat sedang bergerak, sekaligus meningkatkan standar aksesibilitas aplikasi.

### 2. Bagaimana Anda melindungi privasi pengguna saat menggunakan AI API?
> **Jawaban:**  
> Perlindungan privasi pengguna diterapkan melalui strategi pertahanan berlapis:
> 1. **Penyimpanan Kunci Terenkripsi:** Gemini API Key tidak pernah di-*hardcode* di dalam kode sumber maupun disimpan di `SharedPreferences` biasa. Kunci disimpan di dalam **`FlutterSecureStorage`** yang memanfaatkan *Android Keystore* dan *iOS Keychain*.
> 2. **Client-Side Data Sanitization (Penyamaran Data Sensitif):** Sebelum permintaan dikirim ke API publik melalui jaringan, sistem secara otomatis memindai teks pengguna menggunakan ekspresi reguler (*regex*) untuk mendeteksi NIK 16 digit, nomor telepon Indonesia, dan alamat email. Data sensitif tersebut langsung disensor menjadi `[REDACTED_NIK]` dan `[REDACTED_PHONE]` di memori lokal ponsel.
> 3. **Prinsip Minimisasi Data:** Hanya data teks dan byte citra yang relevan yang dikirimkan ke model; identitas perangkat, metadata lokasi GPS, dan riwayat akun internal tidak pernah dilampirkan ke payload AI.

### 3. Fallback apa yang Anda sediakan jika layanan AI error?
> **Jawaban:**  
> Saya menyediakan penanganan kegagalan (*graceful degradation*) bertingkat:
> 1. **Dialog "Layanan AI Sibuk":** Jika terjadi kegagalan jaringan, timeout, atau kuota habis (HTTP 429), aplikasi tidak mengalami crash (*force close*), melainkan menampilkan dialog ramah yang menginformasikan bahwa layanan AI sedang sibuk.
> 2. **Mode Offline (Local Knowledge Fallback):** Pengguna diberikan tombol *"Gunakan Mode Offline"*. Fungsi `AiService.getOfflineFallback(question)` akan menjawab pertanyaan-pertanyaan umum seputar Clean Architecture, Riverpod, atau catatan lokal secara instan dari basis data offline internal perangkat.
> 3. **Local Response Caching:** Respon dari pertanyaan yang pernah berhasil dijawab disimpan dalam `_responseCache` lokal, sehingga jika pengguna menanyakan hal serupa saat koneksi internet terputus, respon tetap dapat disajikan tanpa memanggil API eksternal.

### 4. Satu hal yang Anda pelajari tentang UX fitur AI di mobile?
> **Jawaban:**  
> Hal terpenting yang saya pelajari tentang *User Experience* (UX) AI pada mobile adalah **pentingnya transparansi dan umpan balik progresif (*Progressive Feedback*)**.  
> Berbeda dengan operasi CRUD lokal yang berjalan instan (< 10 ms), pemanggilan Large Language Model membutuhkan latensi jaringan dan komputasi inferensi (1 hingga 4 detik). Pengguna ponsel akan mengira aplikasi mengalami *freeze* jika hanya disajikan layar statis. Dengan mengimplementasikan **Streaming Response (SSE)** dan **Indikator Loading Animasi**, pengguna dapat melihat teks mengalir kata demi kata secara *real-time*. Hal ini secara psikologis mengurangi persepsi waktu tunggu (*perceived latency*), meningkatkan keterikatan pengguna (*engagement*), dan memberikan kejelasan status sistem bahwa AI sedang aktif bekerja.

---

## 9. Kesimpulan & Penutup

Praktikum Minggu 10 berhasil mengimplementasikan seluruh kompetensi inti integrasi kecerdasan buatan pada aplikasi mobile Flutter:
1. Pembangunan antarmuka interaktif Chat dengan dukungan respon *streaming* dan proteksi privasi pengguna.
2. Penerapan kapabilitas *Multimodal AI* yang memadukan pengolahan teks, penglihatan komputer (OCR & Image Understanding), serta pendengaran mesin (Speech-to-Text).
3. Penerapan manajemen risiko industri melalui pembatasan kuota request, caching lokal penghemat biaya, penanganan error transparan, serta mekanisme *fallback* ke mode offline.
4. Seluruh kode terstruktur rapi, terbebas dari isu *linting*, dan lolos 100% pada 45 skenario pengujian otomatis.
