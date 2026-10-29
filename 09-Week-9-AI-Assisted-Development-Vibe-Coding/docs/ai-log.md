# AI Development Log: Fitur Pencarian & Empty State (Minggu 9)

Dokumen ini mencatat seluruh jejak rekayasa prompt (*prompt engineering*), konteks arsitektur, verifikasi kode hasil kecerdasan buatan, penemuan bug dan halusinasi, serta proses refactoring pada proyek **Notes App (Clean Architecture & Riverpod 3)**.

---

## 1. Konsep Workflow AI & Vibe Coding

Dalam rekayasa perangkat lunak modern, AI berperan sebagai asisten pengusul (*generator & reviewer awal*), sedangkan pengembang (*software engineer*) memegang kendali penuh atas keputusan arsitektural dan verifikasi kebenaran (*decider*):

```text
1. Prompt    -> Instruksi spesifik + konteks proyek terarah
2. Generate  -> AI mengusulkan draft implementasi
3. Verify    -> Membaca kritis baris demi baris, cek API nyata, static analysis
4. Test      -> Menulis unit test & widget test pembukti (TDD / red-green test)
5. Refactor  -> Restrukturisasi kode ke layer Clean Architecture & isolasi fungsi
6. Explain   -> Menjelaskan dasar keputusan teknis secara mandiri tanpa AI
```

> **Catatan Kritis:** Melewatkan langkah 3 hingga 6 adalah definisi **Vibe Coding**—tampak cepat menghasilkan kode di awal, namun berbiaya sangat mahal (*technical debt*, bug laten, pelanggaran arsitektur, dan ketidakmampuan maintenance) di akhir.

---

## 2. Praktikum 1: Prompt & Context Engineering

### A. Formula 5 Slot Prompt

Penyusunan prompt berkualitas tinggi wajib mengisi 5 slot spesifikasi teknis:

1. **Peran (*Role*):** Senior Flutter Developer & Clean Architecture Specialist.
2. **Konteks (*Context*):** Fitur Catatan (*feature-first*), arsitektur 3 layer (`presentation -> domain <- data`), Riverpod `^3.4.3`, SQLite lokal via `sqflite`.
3. **Tugas (*Task*):** Membuat fitur pencarian catatan berdasarkan judul (*Search Notes by Title*) yang reaktif dan dilengkapi visualisasi *empty state*.
4. **Batas (*Constraints*):**
   - Domain layer murni Dart (nol impor ke `flutter/material.dart`, `sqflite`, atau `dio`).
   - Tidak boleh memanggil database atau logika filter mentah di dalam widget (*Presentation Layer*).
   - Panjang fungsi/widget modular tidak melebihi 40–80 baris.
5. **Output (*Deliverables*):** Berkas Use Case domain, Notifier/Provider Riverpod, komponen UI modular, unit test komprehensif, dan petunjuk pengujian.

### B. Perbandingan Prompt Buruk vs Baik

| Aspek | Prompt Buruk (Vibe Coding) | Prompt Baik (Context Engineering) |
|:---|:---|:---|
| **Formulasi** | *"Buatkan fitur search catatan yang keren dan responsif di Flutter."* | *"Bertindaklah sebagai senior Flutter dev. Pada proyek Clean Architecture (Riverpod 3, Sqflite), buatkan fitur pencarian judul catatan. Pisahkan aturan filter ke domain UseCase murni Dart tanpa dependensi Flutter. Sediakan Provider Riverpod dan widget terpisah untuk Empty State ketika kata kunci tidak ditemukan. Maksimal 80 baris per modul."* |
| **Dampak Hasil** | Menghasilkan kode monolitik di mana SQL mentah dipanggil dari `TextField.onChanged`, mencampur UI dan database, menggunakan API kadaluarsa, dan sulit diuji secara otomatis. | Menghasilkan kode modular, mengikuti prinsip *Single Responsibility*, mudah dibuatkan *unit test*, dan mematuhi batas arsitektur. |

### C. Prinsip Konteks Tanpa Rahasia (*Context without Secrets*)
- **Informasi yang disertakan:** Struktur pohon folder, kontrak entitas `Note`, antarmuka repository, versi library pada `pubspec.yaml`.
- **Informasi yang dihilangkan / dilindungi:** Tidak pernah menempel token otentikasi, JWT, kredensial Firebase/FCM, atau database URL asli. Placeholder digunakan jika dibutuhkan (`API_TOKEN_PLACEHOLDER`).

---

## 3. Praktikum 2: Generate & Verifikasi 6 Langkah

### A. Prompt Mentah yang Diberikan ke AI
```text
Peran: Senior Flutter Developer
Konteks: Notes App Clean Architecture (presentation -> domain <- data), Riverpod 3.4.3, local SQLite.
Tugas: Tambahkan fitur pencarian judul catatan (Search Notes) + visual empty state.
Batas: Domain use case murni Dart tanpa import Flutter/Dio/Sqflite. Widget hanya menangani UI.
Output: Kode UseCase domain, provider Riverpod, integrasi halaman NotesPage, dan unit test.
```

### B. Output Awal AI (Sebelum Verifikasi Human Developer)
AI mengusulkan implementasi awal sebagai berikut:
```dart
// Usulan AI untuk Provider & Filtering
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchNotesProvider = Provider<List<Note>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final notes = ref.watch(notesProvider).value ?? [];
  return notes.where((note) => note.title.contains(query)).toList();
});
```

### C. Pelaksanaan 6 Langkah Verifikasi

1. **Membaca Kritis Kode:** Terlihat bahwa fungsi filter langsung diletakkan di dalam provider file tanpa domain use case, menggunakan `StateProvider`, dan metode pencarian menggunakan `title.contains(query)` biasa.
2. **Cek Dependensi & Impor Layer:** Memastikan berkas domain usecase yang akan dibuat tidak mengimpor pustaka UI maupun database eksternal.
3. **Cek API Nyata (Verifikasi SDK & Library):** Ditemukan bahwa pada `flutter_riverpod: ^3.4.3`, fungsi `StateProvider` telah dihilangkan / tidak lagi didukung.
4. **Pemeriksaan Mesin Otomatis (`flutter analyze`):**
   ```text
   error - The function 'StateProvider' isn't defined.
   Try importing the library that defines 'StateProvider', correcting the name...
   - lib\features\notes\presentation\providers\notes_providers.dart:36:29
   ```
   *Bukti mesin langsung menangkap ketidakcocokan versi paket.*
5. **Uji Red Test (Test Gagal Pembukti Bug):**
   Menulis unit test untuk membuktikan bug *case-sensitivity*:
   ```dart
   test('filter abaikan huruf besar/kecil', () {
     final result = searchNotes(sampleNotes, 'belanja');
     expect(result, hasLength(2)); // Gagal jika menggunakan .contains() bawaan
   });
   ```
   *Hasil uji awal:* **FAIL** (ekspektasi 2, aktual 0 karena judul di database adalah "Belanja Mingguan Pasar").
6. **Uji Manual:** Menguji 3 skenario nyata:
   - Query kosong `""` -> seluruh catatan tampil.
   - Query cocok `"belanja"` -> tampil catatan belanja.
   - Query tidak ada `"zzz-tak-ada"` -> tampil `NotesSearchEmptyState`.

---

## 4. Temuan Bug & Halusinasi AI (Bukti Wajib)

| No | Tipe Temuan | Deskripsi Halusinasi / Bug | Bukti Verifikasi | Solusi Perbaikan |
|:--:|:---|:---|:---|:---|
| 1 | **Halusinasi Versi Paket (*Outdated API*)** | AI memakai `StateProvider<String>` yang merupakan pola lawas Riverpod v1/v2. Pada Riverpod v3+, `StateProvider` tidak lagi tersedia. | Error dari `flutter analyze`: `The function 'StateProvider' isn't defined`. | Di-refactor menggunakan `NotifierProvider` dan class `SearchQueryNotifier extends Notifier<String>` resmi Riverpod 3. |
| 2 | **Bug Logika Bisnis (*Case-Sensitivity*)** | AI menulis `note.title.contains(query)`. Filter gagal mencocokkan kata dengan kapitalisasi berbeda (misal input `"belanja"` tidak mendeteksi `"Belanja Mingguan"`). | Eksekusi test `search_filter_test.dart` menghasilkan status merah (*AssertionError: Expected 2 items, got 0*). | Normalisasi kedua sisi string menggunakan `.trim().toLowerCase()` di dalam usecase `SearchNotes`. |
| 3 | **Pelanggaran Arsitektur (*Architectural Leak*)** | AI menyarankan menaruh logika filter in-line di dalam berkas UI widget atau langsung mengeksekusi query database SQLite baru setiap tombol diketik. | Review kode manual & Clean Architecture Dependency Rule: UI tidak boleh berisi *business rules*. | Isolasi aturan filter ke Use Case murni `lib/features/notes/domain/usecases/search_notes.dart`. |

---

## 5. Praktikum 3: Debug & Refactoring Terarah

### A. 5 Langkah Debugging Red-to-Green
1. **Reproduksi:** Memasukkan teks `"belanja"` pada daftar catatan berisi judul berawalan huruf kapital `"Belanja Mingguan Pasar"`. Daftar catatan menjadi kosong tak terduga.
2. **Isolasi:** Memindahkan seluruh algoritma filter ke domain use case `SearchNotes`.
3. **Test Merah:** Menulis unit test pada `test/search_filter_test.dart` yang menegaskan case-insensitivity dan whitespace handling. Test gagal membuktikan bug.
4. **Perbaiki Kecil:** Memperbaiki fungsi use case:
   ```dart
   final trimmedQuery = query.trim().toLowerCase();
   if (trimmedQuery.isEmpty) return notes;
   return notes.where((n) => n.title.toLowerCase().contains(trimmedQuery)).toList();
   ```
5. **Catat Solusi:** Menyimpan dokumentasi bahwa pemfilteran teks wajib dinormalisasi terhadap kapitalisasi dan spasi tak disengaja.

### B. Refaktor ke Layer Bersih (Clean Architecture)
Struktur layer setelah dilakukan refactoring:
- **Presentation (UI):** `NotesPage` dipecah menjadi widget modular:
  - `NotesSearchBar` (Input teks & tombol reset)
  - `NotesEmptyState` (Keadaan database kosong)
  - `NotesSearchEmptyState` (Keadaan hasil pencarian nihil)
  - `NotesList` (Tampilan deretan catatan)
- **Presentation (State Notifier):**
  - `SearchQueryNotifier` mengelola state kata kunci pencarian.
  - `filteredNotesProvider` menggabungkan data catatan dan query secara reaktif.
- **Domain Layer:** `SearchNotes` use case murni Dart (nol ketergantungan framework).
- **Data Layer:** `NoteRepositoryImpl` tetap bertugas mengelola persistensi data lokal tanpa beban komputasi filter teks berulang.

---

## 6. Hasil Verifikasi Akhir Mesin

Pemeriksaan akhir pada terminal membuktikan kode 100% sehat:

```bash
# 1. Format Kode
$ dart format --set-exit-if-changed .
Formatted 20 files (0 changed) in 0.10 seconds.

# 2. Analisis Statis
$ flutter analyze
Analyzing 09-Week-9-AI-Assisted-Development-Vibe-Coding...
No issues found! (ran in 3.8s)

# 3. Pengujian Otomatis
$ flutter test
00:02 +26: All tests passed!
```
