# AI Review vs Keputusan Pengembang: AI Challenge Minggu 9

Dokumen ini mendokumentasikan pelaksanaan **AI Challenge** pada praktikum Minggu 9, mencakup prompt tinjauan kode (*code review prompt*), telaah kritis terhadap 3 temuan kecerdasan buatan, matriks keputusan per berkas, serta justifikasi teknis independen.

---

## 1. Prompt AI Code Review Challenge

Sesuai panduan Codelab, prompt berikut dijalankan untuk mereview implementasi fitur pencarian catatan:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod 3.4.3, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan teknis.
```

---

## 2. Tabel 3 Temuan AI vs Keputusan Teknis Pengembang

| No | Temuan AI | Level | Status Keputusan | Alasan Teknis & Bukti Pengujian |
|:--:|:---|:---:|:---:|:---|
| 1 | **Validasi Query Whitespace & Trimming Spasi.**<br>Query yang hanya terdiri dari karakter spasi (`"   "`) dapat menghasilkan hasil tak terduga jika tidak dibersihkan dengan `.trim()`. Query spasi harus dianggap kosong dan mengembalikan seluruh catatan tanpa filter. | **Blocker / Major** | **DITERIMA** | **Bukti Uji:** Dibuat unit test pada `test/search_filter_test.dart`:<br>`test('query hanya spasi whitespace mengembalikan semua catatan utuh', ...)`.<br>Aturan ini diimplementasikan langsung pada usecase domain: `if (trimmedQuery.isEmpty) return notes;`. Menjamin konsistensi data bagi pengguna. |
| 2 | **Memindahkan Pencarian ke Query Database SQLite (`LIKE %query%`).**<br>AI menyarankan untuk menambahkan metode `searchNotes(String query)` pada `NoteRepository` dan mengeksekusi query SQL `SELECT * FROM notes WHERE title LIKE ?` ke disk lokal setiap ada perubahan karakter pada search bar. | **Saran / Major** | **DITOLAK** | **Justifikasi Penolakan:**<br>1. *Efisiensi & Responsivitas:* Pada aplikasi catatan offline berukuran kecil-menengah (< ratusan entri), komputasi *in-memory filtering* di CPU memakan waktu < 1 ms, jauh lebih cepat daripada latensi Disk I/O SQLite.<br>2. *Mencegah Disk Thrashing:* Mengetik cepat di `TextField` tanpa debounce dapat memicu puluhan read I/O bersamaan ke penyimpanan flash mobile.<br>3. *Clean Architecture & SRP:* Data layer tetap murni mengelola sinkronisasi dan persistensi. Domain use case memegang kendali atas aturan bisnis penyaringan.<br>4. *Testability:* Unit test domain murni dapat dijalankan dalam hitungan milidetik tanpa memerlukan engine SQLite FFI atau mock repository yang kompleks. |
| 3 | **Diferensiasi Empty State Database vs Empty State Pencarian.**<br>Pengguna perlu dibedakan antara kondisi saat database lokal memang kosong (*zero notes stored*) dengan kondisi catatan ada namun kata kunci pencarian tidak ditemukan. Sediakan pula tombol aksi cepat untuk mereset query. | **Saran / Minor** | **DITERIMA + REFACTOR** | **Tindakan Implementasi:**<br>Dibuat dua widget visual terpisah:<br>- `NotesEmptyState`: Pesan "Belum ada catatan" dengan instruksi menekan tombol tambah (+).<br>- `NotesSearchEmptyState`: Pesan ramah "Tidak ada catatan yang cocok dengan \"$query\"" dilengkapi tombol `Reset Pencarian` (`ElevatedButton`) yang memanggil `ref.read(searchQueryProvider.notifier).clear()`. |

---

## 3. Matriks Keputusan Per Berkas Proyek

| Berkas Sumber Kode | Peran & Layer | Keputusan | Tindakan Pengembang |
|:---|:---|:---:|:---|
| [`lib/features/notes/domain/usecases/search_notes.dart`](../lib/features/notes/domain/usecases/search_notes.dart) | Domain Layer (Logika Bisnis Murni) | **Terima + Refactor** | Mengadopsi struktur callable class `SearchNotes`, memastikan nol dependensi framework, menambahkan `.trim().toLowerCase()`, dan penanganan query whitespace. |
| [`lib/features/notes/presentation/providers/notes_providers.dart`](../lib/features/notes/presentation/providers/notes_providers.dart) | Presentation Layer (State Management) | **Terima + Refactor** | Mengganti `StateProvider` usulan AI yang sudah usang dengan `NotifierProvider` dan `SearchQueryNotifier` resmi standar Riverpod 3+. |
| [`lib/features/notes/presentation/pages/notes_page.dart`](../lib/features/notes/presentation/pages/notes_page.dart) | Presentation Layer (UI Komponen) | **Terima + Refactor** | Menolak kode monolitik AI. Memecah halaman menjadi komponen modular (< 40 baris per fungsi/widget): `NotesSearchBar`, `NotesEmptyState`, `NotesSearchEmptyState`, dan `NotesList`. |
| [`test/search_filter_test.dart`](../test/search_filter_test.dart) | Unit Test Suite (Domain) | **Terima + Sempurnakan** | Mengembangkan skenario uji lengkap: case-insensitivity, substring matching, empty query, whitespace trimming, dan list kosong. |
| [`test/notes_search_widget_test.dart`](../test/notes_search_widget_test.dart) | Widget Test Suite (Presentation) | **Tulis Mandiri** | Ditulis mandiri untuk menguji interaksi visual `NotesPage`, simulasi ketikan teks pencarian, kemunculan empty state, dan aksi tombol reset query. |

---

## 4. Penjelasan Teknis Mandiri (Tanpa Membuka AI)

Sebagai pengembang perangkat lunak, seluruh keputusan di atas dapat dipertanggungjawabkan secara mandiri:
1. **Mengapa Use Case `SearchNotes` berada di Domain Layer?**
   Aturan bahwa pencarian harus *case-insensitive*, mengabaikan spasi berlebih, dan mencocokkan substring adalah aturan bisnis aplikasi (*business logic*), bukan urutan render UI ataupun detail teknis database. Menempatkannya di domain menjamin portabilitas kode jika UI kelak diganti atau jika data berpindah sumber.
2. **Mengapa Menggunakan `NotifierProvider` dan bukan `StateProvider`?**
   Riverpod versi 3 telah menstandarkan pengelolaan state menggunakan class berbasis `Notifier` untuk meningkatkan prediktabilitas mutasi state dan mengurangi kebocoran lifecycle, sehingga `StateProvider` lawas dihapus.
3. **Mengapa Widget Dipecah Menjadi Banyak Kelas Terpisah?**
   Widget berukuran kecil memiliki siklus rebuild yang terisolasi (*granular rebuild*), mengurangi beban render ulang elemen yang tidak berubah saat pengguna mengetik huruf di kolom pencarian, serta memenuhi standar Clean Code (panjang fungsi < 40–80 baris).
