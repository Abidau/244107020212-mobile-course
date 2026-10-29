# Panduan Pengambilan Screenshot Praktikum Minggu 8

Folder ini disediakan untuk menampung seluruh berkas tangkapan layar (*screenshot*) sebagai bukti pelaksanaan Praktikum Minggu 8: **Mid Project Review & Code Review**.

Silakan ambil tangkapan layar sesuai dengan daftar di bawah ini dan simpan file gambar (format `.png`) dengan nama file yang telah ditentukan:

---

## Daftar Berkas Screenshot yang Perlu Diambil

| No | Nama Berkas | Konten / Objek yang Ditangkap | Panduan / Perintah Terminal |
| :---: | :--- | :--- | :--- |
| **01** | `01_git_log_and_branch_audit.png` | Output audit riwayat Git di terminal | Jalankan `git log --oneline -15` dan `git status` di terminal. |
| **02** | `02_branch_feat_and_commit.png` | Pembuatan branch fitur dan commit konvensional | Tampilkan perintah `git checkout -b feat/notes-validation` dan `git commit -m "feat(notes): validasi judul kosong + test"`. |
| **03** | `03_pull_request_submission.png` | Tampilan form Pull Request di GitHub | Buka halaman *New Pull Request* dari `feat/notes-validation` ke `develop` dengan template deskripsi lengkap (Masalah, Solusi, Cara Uji, Closes #12). |
| **04** | `04_peer_code_review_comments.png` | Komentar peer review dan keputusan Approve | Tampilan tab *Files Changed* atau *Conversation* pada PR yang memuat minimal 3 komentar review terstruktur dan status **Approved**. |
| **05** | `05_flutter_analyze_clean.png` | Hasil eksekusi `flutter analyze` | Jalankan `flutter analyze` di folder proyek hingga muncul teks `No issues found!`. |
| **06** | `06_dart_format_check.png` | Hasil verifikasi formatter Dart | Jalankan `dart format --output=none --set-exit-if-changed .` di terminal (exit 0). |
| **07** | `07_flutter_test_passed.png` | Hasil eksekusi unit test | Jalankan `flutter test` di terminal hingga muncul `All tests passed!`. |
| **08** | `08_ci_workflow_github_actions.png` | Status workflow CI di GitHub Actions | Tampilan tab *Actions* di GitHub yang menunjukkan job `ci` berjalan sukses (tanda centang hijau). |
| **09** | `09_notes_app_validation_demo.png` | Demonstrasi validasi pada aplikasi Notes | Jalankan aplikasi (`flutter run -d windows` atau Chrome/Android), tekan tombol Simpan saat judul kosong, tangkap layar saat pesan SnackBar error merah "Judul catatan tidak boleh kosong." muncul. |

---

> [!TIP]
> Begitu Anda meletakkan berkas gambar dengan nama di atas ke dalam folder `screenshots/` ini, gambar akan otomatis tampil pada tabel galeri di `README.md`.
