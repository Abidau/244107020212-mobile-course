# Galeri Bukti Pengujian & Visualisasi (Screenshots)

Folder ini berisi dokumentasi visual hasil pengujian aplikasi, verifikasi mesin, dan antarmuka fitur pencarian (*Search Notes*) pada **Praktikum Minggu 9: AI-Assisted Development & Vibe Coding**.

---

## 1. Daftar Berkas Bukti

| No | Berkas | Deskripsi |
|:--:|:---|:---|
| 1 | [`01_flutter_analyze_log.txt`](01_flutter_analyze_log.txt) | Log eksekusi `flutter analyze` yang membuktikan **No issues found!** (nol warning, nol error). |
| 2 | [`02_flutter_test_log.txt`](02_flutter_test_log.txt) | Log eksekusi `flutter test` yang membuktikan **26/26 tests passed!** (Unit test domain usecase, format utilitas, repository, serta widget test empty state). |
| 3 | [`03_manual_test_empty_query.jpg`](03_manual_test_empty_query.jpg) | Tangkapan layar antarmuka aplikasi saat query pencarian kosong: menampilkan seluruh daftar catatan secara lengkap. |
| 4 | [`04_manual_test_matching_query.jpg`](04_manual_test_matching_query.jpg) | Tangkapan layar antarmuka aplikasi saat query `belanja`: memfilter daftar secara real-time menampilkan hanya catatan yang cocok. |
| 5 | [`05_manual_test_unmatched_empty_state.jpg`](05_manual_test_unmatched_empty_state.jpg) | Tangkapan layar antarmuka aplikasi saat query tidak cocok (`zzz-tak-ada`): menampilkan `NotesSearchEmptyState` dengan pesan ramah pengguna dan tombol **Reset Pencarian**. |

---

## 2. Rincian Tampilan Antarmuka

### A. Tampilan Awal (Query Kosong)
- **Komponen:** Top AppBar `Catatan Offline (Clean Arch)`, input bar `Cari judul catatan...`, dan daftar kartu catatan.
- **Hasil:** Seluruh entri catatan tampil tanpa filter.

### B. Tampilan Filter Berhasil (Query Cocok)
- **Kata Kunci:** `belanja`
- **Hasil:** Filter case-insensitive menghasilkan kartu:
  1. *Belanja Mingguan Pasar*
  2. *Rencana Belanja Elektronik*
- **Aksi Cepat:** Terdapat tombol silang (`x`) di dalam input bar untuk menghapus kata kunci seketika.

### C. Tampilan Empty State (Query Tidak Ditemukan)
- **Kata Kunci:** `zzz-tak-ada`
- **Komponen:** Ikon `search_off_rounded`, judul *"Tidak ada catatan yang cocok"*, keterangan teks eksplisit, dan tombol *"Reset Pencarian"*.
- **Interaksi:** Menekan tombol mereset query ke string kosong dan menampilkan kembali seluruh catatan.
