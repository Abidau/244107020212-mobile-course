# Self-Verification & AI Audit Checklist (Minggu 9)

Dokumen ini merupakan instrumen audit mandiri pengembang (*Self-Verification Checklist*) untuk memverifikasi kualitas kode yang dihasilkan bersama AI, kepatuhan arsitektural (*Clean Architecture*), dan kesiapan deliverable praktikum Minggu 9: **AI-Assisted Development & Vibe Coding**.

---

## 1. Checklist Verifikasi Mandiri (Standar Codelab Minggu 9)

| Kriteria Verifikasi | Bukti / Berkas Rujukan | Status | Keterangan Evaluasi |
|:---|:---|:---:|:---|
| **Prompt 5 Slot + Konteks Proyek** | [`docs/ai-log.md`](ai-log.md#2-praktikum-1-prompt--context-engineering) | **LENGKAP** | Memenuhi 5 slot: Peran (Senior Dev), Konteks (Feature-First, Riverpod, SQLite), Tugas (Search + Empty State), Batas (No Flutter di domain, max 80 baris), Output (Code + Tests). Bebas dari secret/token. |
| **Pemeriksaan Statis Mesin (`flutter analyze`)** | [`screenshots/01_flutter_analyze_log.txt`](../screenshots/01_flutter_analyze_log.txt) | **BERSIH** | Nol error, nol warning, lolos aturan linter `flutter_lints: ^6.0.0`. |
| **Format Standar Dart (`dart format`)** | Seluruh repositori proyek | **RAPI** | Terformat otomatis dengan `dart format --set-exit-if-changed .` tanpa pelanggaran indentasi atau style. |
| **Pengujian Otomatis (`flutter test`)** | [`screenshots/02_flutter_test_log.txt`](../screenshots/02_flutter_test_log.txt) | **100% HIJAU** | 26 skenario pengujian lolos (Unit test usecase pencarian, unit test validasi lama, formatting utilitas, dan widget test empty state). |
| **Temuan AI Terbukti Benar & Diperbaiki** | [`docs/ai-review-vs-keputusan.md`](ai-review-vs-keputusan.md#2-tabel-3-temuan-ai-vs-keputusan-teknis-pengembang) | **TERVALIDASI** | Temuan 1 (Validasi whitespace & trimming string query) dibuktikan dengan unit test dan diperbaiki pada domain use case. |
| **Temuan AI Ditolak dengan Alasan Teknis** | [`docs/ai-review-vs-keputusan.md`](ai-review-vs-keputusan.md#2-tabel-3-temuan-ai-vs-keputusan-teknis-pengembang) | **TERVALIDASI** | Temuan 2 (Usulan pemindahan filter teks ke SQL `LIKE` database) ditolak demi efisiensi in-memory CPU, pencegahan disk thrashing, isolasi layer, dan testability. |
| **Kemampuan Menjelaskan Tanpa AI** | Laporan Resmi ([`README.md`](../README.md)) | **MANDIRI** | Mampu menguraikan alasan pemisahan layer domain vs presentation, pemilihan Notifier Riverpod 3, dan isolasi fungsi modular tanpa bantuan AI. |

---

## 2. Checklist Kepatuhan Clean Architecture

- [x] **Domain Layer Murni:** Berkas [`lib/features/notes/domain/usecases/search_notes.dart`](../lib/features/notes/domain/usecases/search_notes.dart) hanya mengimpor entitas `Note` bawaan Dart. Tidak ada import ke `package:flutter`, `sqflite`, atau `dio`.
- [x] **No DB Call from Widgets:** Berkas UI [`lib/features/notes/presentation/pages/notes_page.dart`](../lib/features/notes/presentation/pages/notes_page.dart) tidak mengeksekusi panggilan database atau SQL mentah. Semua data dialirkan melalui Riverpod Provider.
- [x] **Granular & Modular Widget Size:** Seluruh class/fungsi pada widget tidak melebihi 40–80 baris. Komponen dipecah menjadi `NotesSearchBar`, `NotesEmptyState`, `NotesSearchEmptyState`, dan `NotesList`.
- [x] **Modern State Management:** Menggunakan `NotifierProvider` dan `SearchQueryNotifier` yang didukung penuh oleh Riverpod 3, menolak halusinasi `StateProvider` yang sudah usang.

---

## 3. Checklist Uji Antarmuka Pengguna (Manual & Widget)

- [x] **Skenario 1 (Query Kosong):** Menampilkan seluruh catatan tanpa filter ([`03_manual_test_empty_query.jpg`](../screenshots/03_manual_test_empty_query.jpg)).
- [x] **Skenario 2 (Query Cocok):** Memfilter judul catatan secara real-time dan case-insensitive ([`04_manual_test_matching_query.jpg`](../screenshots/04_manual_test_matching_query.jpg)).
- [x] **Skenario 3 (Query Tidak Cocok):** Menampilkan visualisasi `NotesSearchEmptyState` lengkap dengan tombol aksi reset pencarian ([`05_manual_test_unmatched_empty_state.jpg`](../screenshots/05_manual_test_unmatched_empty_state.jpg)).
- [x] **Widget Test Terverifikasi:** [`test/notes_search_widget_test.dart`](../test/notes_search_widget_test.dart) menguji seluruh siklus interaksi di atas dalam simulasi widget tree tanpa flakiness.
