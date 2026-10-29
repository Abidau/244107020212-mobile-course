# Review Checklist & Mid-Project Review Readiness

Dokumen ini merupakan instrumen formal peninjauan kode (*peer code review*), audit riwayat Git, standarisasi konvensi commit, dan evaluasi kesiapan proyek tengah semester (*Mid-Project Review*) pada mata kuliah **Pemrograman Mobile Lanjut**.

---

## 1. Audit Riwayat Git & Git Flow

Berdasarkan audit riwayat commit repositori menggunakan perintah:
```bash
git log --oneline -15
git branch -a
git status
```

### Temuan Masalah pada Riwayat Git Sebelumnya:
1. **Commit Langsung ke Branch `main`**: Sebagian besar pekerjaan pada minggu-minggu awal di-commit langsung ke branch `main` tanpa melalui branch integrasi (`develop`) atau branch fitur (`feat/*`).
2. **Pesan Commit Tidak Deskriptif & Non-Konvensional**: Terdapat commit dengan pesan generik seperti `img`, `feat: new img`, `feat: report revision`, `feat: complete the report`, dan `feat: complete the praktikum`. Pesan tersebut tidak menjelaskan ruang lingkup (*scope*), modul yang terdampak, atau rincian teknis perubahan.
3. **Pencampuran Perubahan Dokumen dan Kode**: Commit laporan dan commit implementasi kode digabungkan dalam satu commit besar tanpa pemisahan atomik (*atomic commits*).
4. **File Untracked / Tidak Terabaikan**: Aset biner dan artefak IDE yang seharusnya diabaikan oleh `.gitignore` sempat terdeteksi di status git.

---

## 2. Tabel Simulasi Sebelum/Sesudah: Standarisasi Pesan Commit

Sesuai instruksi Praktikum 1 Langkah 3, berikut adalah penulisan ulang 3 pesan commit lama menjadi format **Conventional Commits** (`tipe(scope): deskripsi singkat`) beserta alasan teknisnya:

| No | Commit Lama (Hash) | Format Baru (Conventional Commit) | Alasan Teknis & Justifikasi Perubahan |
| :---: | :--- | :--- | :--- |
| **1** | `e58bd78 img` | `docs(week3): tambahkan screenshot demo provider & routing` | Pesan lama `img` sangat ambigu, tidak menyebutkan modul yang ditambahkan gambar, tipe perubahan, maupun tujuannya. Format baru dengan jelas menetapkan scope dokumentasi (`week3`), tipe `docs`, serta spesifikasi aset visual yang dilampirkan. |
| **2** | `fb60083 feat: complete the report` | `docs(week6): lengkapi laporan auth token refresh & fcm listener` | Pesan lama `feat: complete the report` keliru menggunakan tipe `feat` (seharusnya `docs`), serta tidak menginformasikan topik laporan. Format baru menegaskan materi otentikasi Minggu 6 dan implementasi Firebase Cloud Messaging. |
| **3** | `40f1847 feat: complete the praktikum` | `feat(notes): implementasi usecase validasi judul kosong + unit test` | Pesan lama `complete the praktikum` tidak memberikan petunjuk logis apa pun tentang fungsi atau modul yang diubah jika sewaktu-waktu perlu dilakukan `git revert` atau `git cherry-pick`. Format baru memetakan fitur validasi pada entitas catatan beserta buktinya pengujiannya. |

---

## 3. Template & Form Peer Review Pull Request

### Informasi Pull Request
- **Judul PR**: `feat(notes): validasi judul kosong + test`
- **Branch Asal**: `feat/notes-validation`
- **Branch Target**: `develop`
- **Author**: Ahmad Bidaus
- **Reviewer**: Peer Reviewer (Pair Programming Partner)
- **Status Akhir**: **APPROVED** (setelah perbaikan *Request Changes* ditindaklanjuti)
- **Terkait Issue**: Closes #12

---

### Deskripsi Pull Request (Author Submission)
- **Masalah**: Pengguna dapat menekan tombol Simpan pada catatan tanpa memasukkan judul, dan sistem sebelumnya tidak memberikan *feedback* kesalahan apa pun di UI sehingga membuat pengguna bingung.
- **Solusi**: 
  1. Menambahkan aturan validasi di domain layer (`AddNote` usecase) yang memeriksa string kosong dan whitespace, mengembalikan `LocalFailure('Judul catatan tidak boleh kosong.')`.
  2. Memperbaiki logika presentasi di `notes_page.dart` agar menangkap kegagalan dan menampilkan `SnackBar` berwarna merah dengan pesan error yang jelas.
- **Cara Uji**:
  1. *Manual Test*: Buka form tambah catatan, biarkan judul kosong atau hanya spasi, tekan Simpan. Pastikan muncul SnackBar merah "Judul catatan tidak boleh kosong." dan dialog tetap terbuka.
  2. *Automated Unit Test*: Jalankan `flutter test test/validate_note_test.dart` dan pastikan seluruh skenario lolos.

---

### Checklist Temuan Peer Review (15-Minute Review)

Gunakan pola: **Observasi $\rightarrow$ Dampak $\rightarrow$ Usulan Konkret**.

#### A. Temuan Kebenaran (Correctness & Edge Cases) - Minimal 2
1. **Temuan 1 (Observasi-Dampak-Usulan)**:
   - *Observasi*: Pada `notes_page.dart`, tombol Simpan sebelumnya menggunakan pengecekan `if (title.trim().isNotEmpty)`.
   - *Dampak*: Ketika judul kosong, tidak ada aksi yang terjadi. Dialog tetap diam tanpa ada notifikasi feedback ke pengguna bahwa input tidak valid.
   - *Usulan*: Panggil `addNote` langsung dari notifier/usecase dan tangani hasil `result.failure` dengan menampilkan `ScaffoldMessenger.of(context).showSnackBar` berwarna merah.

2. **Temuan 2 (Observasi-Dampak-Usulan)**:
   - *Observasi*: Pada `AddNote` usecase, parameter `title` dapat berisi spasi jamak (`"   "`), tab, atau newline.
   - *Dampak*: Tanpa `title.trim()`, catatan dengan hanya karakter spasi kosong dapat lolos tersimpan ke database lokal SQLite sebagai catatan tanpa teks.
   - *Usulan*: Lakukan sanitasi awal `final cleanTitle = title.trim(); if (cleanTitle.isEmpty) return Future.value((note: null, failure: const LocalFailure('Judul catatan tidak boleh kosong.')));`.

#### B. Temuan Arsitektur (Architecture & Clean Code) - Minimal 1
3. **Temuan 3 (Observasi-Dampak-Usulan)**:
   - *Observasi*: Muncul kecenderungan untuk memvalidasi string judul langsung menggunakan helper database atau controller di UI.
   - *Dampak*: Memindahkan aturan bisnis ke UI melanggar *Separation of Concerns* dan membuat logika validasi tidak dapat diuji murni tanpa dependensi widget Flutter.
   - *Usulan*: Tetap letakkan seluruh aturan validasi inti di dalam `AddNote` (Domain Layer / Use Case) agar layer domain tetap menjadi sumber kebenaran tunggal (*Single Source of Truth*).

#### C. Temuan Pengujian (Testing) - Minimal 1
4. **Temuan 4 (Observasi-Dampak-Usulan)**:
   - *Observasi*: Unit test awal di `add_note_test.dart` hanya menguji input string spasi `"   "`, belum menguji kombinasi whitespace kompleks (`\t`, `\n`) dan string kosong murni `""`.
   - *Dampak*: Regresi pada input edge case dapat lolos tanpa terdeteksi otomatis.
   - *Usulan*: Tambahkan file pengujian tersendiri `test/validate_note_test.dart` yang mencakup 4 skenario batas: string kosong, string whitespace, string valid dengan leading/trailing space, dan nilai default body.

#### D. Saran Keterbacaan & Kode Bersih (Readability & Clean Code) - Minimal 1
5. **Temuan 5 (Observasi-Dampak-Usulan)**:
   - *Observasi*: Format penulisan kode pada beberapa file memiliki spasi tidak konsisten dan melebihi batas panjang baris.
   - *Dampak*: Mengotori *git diff* dan memicu perdebatan gaya penulisan saat review kode manual.
   - *Usulan*: Wajibkan eksekusi `dart format --output=none --set-exit-if-changed .` pada workflow CI GitHub Actions sebelum PR di-merge.

---

### Tindak Lanjut & Resolusi Reviewer
- [x] Seluruh 5 poin review telah diimplementasikan pada branch `feat/notes-validation`.
- [x] Verifikasi pengujian ulang unit test: **14/14 test PASSED (Hijau)**.
- [x] Static analysis: **0 issues found (Bersih)**.
- [x] Keputusan akhir Reviewer: **APPROVED FOR MERGE (via Squash Merge)**.

---

## 4. Checklist Kesiapan Proyek Tengah Semester (Mid-Project Review)

| No | Kriteria Kesiapan Mid-Project | Standar Verifikasi Codelab | Status | Bukti / Catatan |
| :---: | :--- | :--- | :---: | :--- |
| **1** | **Struktur Feature-First & Layering** | Terbukti melalui 3 uji sterilitas (0 pelanggaran) | **LULUS** | Domain murni Dart tanpa import Flutter/Dio/SQLite. Presentation bebas manipulasi data mentah. |
| **2** | **Static Analysis Bersih** | `flutter analyze` exit code 0 | **LULUS** | 0 error, 0 warning, 0 info linter rules. |
| **3** | **Formatter Otomatis Konsisten** | `dart format --set-exit-if-changed .` exit code 0 | **LULUS** | Seluruh 17 file Dart terformat rapi sesuai panduan resmi Dart. |
| **4** | **Pengujian Unit Test Lengkap** | `flutter test` lulus 100% | **LULUS** | 14 test lulus tanpa kegagalan (usecase, format, validation, repository). |
| **5** | **Pull Request & Commit Hygiene** | PR berukuran < 300 baris, commit konvensional | **LULUS** | PR `feat(notes): validasi judul kosong + test` memenuhi format observasi $\rightarrow$ dampak $\rightarrow$ solusi. |
| **6** | **Otomatisasi Penolakan (CI)** | `.github/workflows/ci.yml` aktif | **LULUS** | Pipeline GitHub Actions memeriksa format, analyze, dan test pada setiap PR. |
| **7** | **Dokumentasi AI Review vs Keputusan** | Tabel verifikasi temuan AI di `docs/` | **LULUS** | Terdokumentasi lengkap di `docs/ai-review-vs-keputusan.md` dengan bukti uji. |
| **8** | **Kelengkapan README & Bukti Screenshot** | Status paruh semester, panduan jalan, screenshot | **LULUS** | Tersaji terstruktur pada README proyek beserta panduan verifikasi. |

---

## 5. Kesimpulan Penilaian Kesiapan

Proyek **Notes App Clean Architecture** berada dalam status **SIAP (Production-Ready for Second Half)**. Fondasi arsitektur, disiplin branching, pipeline CI otomatis, dan pengujian unit test telah terbukti solid dan siap untuk pengembangan fitur-fitur kompleks pada paruh kedua semester (Minggu 9–14).
