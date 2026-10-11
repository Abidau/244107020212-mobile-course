# AI Prompt Challenge & Dokumentasi Arsitektur (Minggu 7 - Clean Architecture)

Dokumen ini memuat dokumentasi **AI Prompt Challenge**, evaluasi kritis terhadap usulan AI, tabel komparasi usulan vs keputusan final, serta justifikasi teknis arsitektur Clean Architecture yang diterapkan.

---

## 1. AI Prompt yang Digunakan

Prompt berikut diberikan kepada AI Coding Assistant sesuai standar instruksi Codelab Minggu 7:

```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman). Kondisi kini: folder lib/{data, providers, pages, messaging}, repository tercampur dengan implementasi, widget memanggil Dio langsung. 

Tugas:
1. Usulkan struktur feature-first Clean Architecture (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana, dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan). 
5. Jelaskan trade-off setiap keputusan arsitektur.
```

---

## 2. Struktur Final Proyek (Sesuai Diagram Codelab Bagian 3)

Sesuai instruksi dan diagram arsitektur target pada Codelab Minggu 7, struktur folder yang diterapkan adalah:

```text
lib/
├── core/
│   ├── failures.dart        # Failure domain (murni Dart)
│   ├── format.dart          # formatting tanggal murni & parsing rute
│   └── providers.dart       # (opsional) provider lintas fitur
├── features/
│   └── notes/
│       ├── domain/
│       │   ├── entities/note.dart
│       │   ├── repositories/note_repository.dart  # interface!
│       │   └── usecases/get_notes.dart
│       │   └── usecases/add_note.dart
│       ├── data/
│       │   ├── models/note_model.dart
│       │   └── repositories/note_repository_impl.dart
│       └── presentation/
│           ├── providers/notes_providers.dart     # notifier + DI
│           └── pages/notes_page.dart
├── routes.dart              # GoRouter + konstanta rute
└── main.dart                # ProviderScope & MaterialApp.router
```

---

## 3. Tabel Verifikasi AI vs Keputusan Final

| Kriteria Checklist Codelab | Usulan Awal AI | Keputusan Final Pengembang | Alasan Teknis & Trade-off |
| :--- | :--- | :--- | :--- |
| **Pemisahan Interface vs Implementasi** | Menempatkan interface di `domain/repositories` dan implementasi di `data/repositories`. | **Diterima Penuh** | Memenuhi *Dependency Inversion Principle (DIP)*. Domain tidak bergantung pada SQLite/jaringan luar. |
| **Sterilitas Domain dari Framework** | Entity murni tanpa package `flutter`, `dio`, `sqflite`. | **Diterima Penuh** | Memungkinkan logika bisnis diuji secara unit test murni dalam hitungan milidetik tanpa emulator. |
| **Entity vs Model Serialization** | Menaruh `toMap`/`fromMap` hanya di `NoteModel`. Entity `Note` murni tanpa serialisasi. | **Diterima Penuh** | Mengisolasi perubahan struktur skema basis data SQLite agar tidak merusak representasi entitas bisnis domain. |
| **Jumlah Use Case pada CRUD Sederhana** | Membuat use case per operasi CRUD (`GetNotes`, `AddNote`). | **Diterima Sesuai Codelab** | `GetNotes` memisahkan pengambilan data dari UI, sedangkan `AddNote` menyertakan validasi logika bisnis judul non-empty. Untuk operasi satu-baris murni tanpa logika, use case bersifat opsional untuk menghindari *boilerplate* berlebih pada tim kecil. |
| **Dependency Injection** | Riverpod providers tanpa package DI tambahan (`get_it`). | **Diterima Penuh** | Riverpod menyatukan manajemen state dan DI container, mempermudah penggantian repository palsu saat testing via provider override. |
| **Pemisahan Formatting & Rute** | Diekstrak ke `lib/core/format.dart` dan `lib/routes.dart`. | **Diterima Penuh** | Widget di presentation terbebas dari format mentah `DateFormat` atau `toIso8601String()`. |

---

## 4. Analisis Trade-Off & Kapan Use Case Dibutuhkan

### A. Kapan Use Case Benar-Benar Dibutuhkan?
1. **Terdapat Aturan Bisnis / Validasi**: Pada `AddNote`, sebelum data disimpan ke database, use case memvalidasi bahwa judul catatan tidak boleh kosong atau hanya berupa spasi.
2. **Penggabungan Multi-Repository**: Ketika suatu proses bisnis melibatkan lebih dari satu repositori (misalnya membaca data lokal dari SQLite dan mengirimkannya ke remote API).
3. **Logika Bisnis yang Kompleks**: Transformasi data, enkripsi, sinkronisasi *offline-first*, atau penghitungan bisnis tertentu.

### B. Kapan Use Case Tergolong Over-Engineering?
- Ketika use case hanya menjadi "pass-through" 1-baris tanpa logika bisnis apa pun.
- Biaya bagi tim kecil: jumlah file bertambah dua kali lipat, waktu navigasi kode lebih lama (*cognitive load* meningkat).
- Namun, biayanya sepadan saat sistem berskala besar atau membutuhkan isolasi unit test yang ketat.

---

## 5. Hasil Tiga Uji Verifikasi Sterilitas

### Pemeriksaan 1: Presentation Steril dari Data Mentah
Perintah:
```powershell
Get-ChildItem -Path lib/features/*/presentation -Recurse -Filter *.dart | Select-String -Pattern "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode"
```
**Hasil: 0 temuan (Bersih / Lolos)**.

### Pemeriksaan 2: Domain & Core Steril dari Framework Luar
Perintah:
```powershell
Get-ChildItem -Path lib/features/*/domain, lib/core -Recurse -Filter *.dart | Select-String -Pattern "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase"
```
**Hasil: 0 temuan (Bersih / Lolos)**.

### Pemeriksaan 3: Static Analysis & Testing
- `flutter analyze` : **No issues found! (0 warnings, 0 errors)**
- `flutter test` : **10/10 tests passed! (100% lulus)**
