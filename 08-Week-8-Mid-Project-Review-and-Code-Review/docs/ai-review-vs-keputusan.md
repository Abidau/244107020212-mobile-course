# AI Review vs Keputusan Mandiri: Verifikasi Temuan AI pada Pull Request

Dokumen ini memuat catatan lengkap pelaksanaan **AI Prompt Challenge** dan **AI Verification Checklist** pada Pull Request `feat/notes-validation` menuju `develop` dalam rangka *Mid-Project Review* Minggu 8.

---

## 1. Prompt AI yang Digunakan

Prompt berikut diberikan kepada AI Coding Assistant (Senior Flutter Developer persona) untuk meninjau *diff* perubahan kode pada Pull Request:

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

---

## 2. Output Mentah dari AI (5 Temuan Teratas)

Berikut adalah ringkasan hasil telaah awal yang diberikan oleh AI Senior Flutter Developer:

### Temuan AI #1 (Blocker - Correctness)
- **Komponen**: `notes_page.dart` (Presentation Layer)
- **Komentar AI**: Tombol "Simpan" membungkus pemanggilan usecase dengan `if (title.trim().isNotEmpty)`. Jika pengguna menekan Simpan saat input kosong, fungsi selesai tanpa aksi, dialog tidak tertutup, dan tidak ada pesan kesalahan (feedback visual) yang diberikan kepada pengguna. Pengguna mengira aplikasi macet (*silent failure*).
- **Usulan Kode AI**:
  ```dart
  ElevatedButton(
    onPressed: () async {
      final title = titleController.text;
      final body = bodyController.text;
      final addNote = ref.read(addNoteProvider);
      final result = await addNote(title: title, body: body);
      if (result.failure != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.failure!.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (ctx.mounted) Navigator.of(ctx).pop();
        ref.invalidate(notesProvider);
      }
    },
    child: const Text('Simpan'),
  )
  ```

### Temuan AI #2 (Blocker - Correctness & Edge Case)
- **Komponen**: `add_note.dart` (Domain Layer / Use Case)
- **Komentar AI**: Validasi `title.isEmpty` tanpa melakukan pembersihan spasi (*trim*) akan meloloskan string yang hanya berisi spasi (`"   "`), tab (`\t`), atau baris baru (`\n`). Catatan kosong tanpa teks yang bermakna akan tetap tersimpan di basis data SQLite.
- **Usulan Kode AI**:
  ```dart
  final cleanTitle = title.trim();
  if (cleanTitle.isEmpty) {
    return Future.value((
      note: null,
      failure: const LocalFailure('Judul catatan tidak boleh kosong.'),
    ));
  }
  return _repository.addNote(title: cleanTitle, body: body.trim());
  ```

### Temuan AI #3 (Saran - Testing)
- **Komponen**: `test/` (Unit Test Suite)
- **Komentar AI**: Pengujian di `add_note_test.dart` belum mengisolasi kasus validasi input secara komprehensif. Harus ada unit test terpisah yang memverifikasi bahwa `MockNoteRepository.addNote` tidak pernah dipanggil sama sekali saat validasi gagal, serta memverifikasi sanitasi pemotongan spasi.
- **Usulan Kode AI**:
  ```dart
  test('Validasi gagal ketika judul string kosong ""', () async {
    final result = await addNote(title: '', body: 'Catatan');
    expect(result.failure, isA<LocalFailure>());
    expect(fakeRepo.addNoteCalled, isFalse);
  });
  ```

### Temuan AI #4 (Blocker - Architecture Violation)
- **Komponen**: `add_note.dart` (Domain Layer)
- **Komentar AI**: *"Untuk memastikan integritas basis data, sebaiknya UseCase mengimpor package `sqflite` atau helper database untuk memeriksa apakah tabel `notes` terkunci sebelum melakukan validasi string."*
- **Usulan Kode AI**:
  ```dart
  import 'package:sqflite/sqflite.dart'; // Usulan AI yang keliru!
  // Memeriksa status database langsung di Use Case
  ```

### Temuan AI #5 (Saran - State Management Over-Engineering)
- **Komponen**: `notes_providers.dart` (Presentation Layer)
- **Komentar AI**: *"Sebaiknya ganti `FutureProvider<List<Note>>` dengan membuat kelas `StateNotifier` kustom dan kelas `NotesState` tersendiri yang membungkus status `isLoading`, `errorMessage`, dan `List<Note>` secara manual."*

---

## 3. Verifikasi & Analisis Mandiri terhadap Temuan AI

Berdasarkan pedoman evaluasi (*AI Verification Checklist*), setiap saran AI harus diverifikasi keabsahannya dengan bukti teknis:

### A. Evaluasi Temuan #1 (Silent Failure di UI)
- **Verifikasi**: Dilakukan pengujian langsung pada dialog tambah catatan dengan mengosongkan judul. Terbukti benar bahwa sebelum diperbaiki, tombol Simpan tidak memberikan reaksi apa pun.
- **Keputusan**: **DITERIMA (ACCEPTED)**.
- **Bukti & Tindak Lanjut**: Kode di `notes_page.dart` diperbarui sehingga error SnackBar merah dimunculkan saat `result.failure != null`.

### B. Evaluasi Temuan #2 (Sanitasi Whitespace di Use Case)
- **Verifikasi**: Dijalankan pengujian manual dengan input `"   "`. Terbukti bahwa tanpa `title.trim()`, panjang string tidak nol sehingga lolos validasi `isEmpty`.
- **Keputusan**: **DITERIMA (ACCEPTED)**.
- **Bukti & Tindak Lanjut**: Logika `final cleanTitle = title.trim();` diterapkan pada `AddNote.call()`. Pengujian unit test di `test/validate_note_test.dart` mengonfirmasi bahwa string spasi dan whitespace berhasil ditolak dengan `LocalFailure`.

### C. Evaluasi Temuan #3 (Cakupan Unit Test Validasi)
- **Verifikasi**: Ditemukan bahwa pengujian awal belum memverifikasi batas string kosong murni dan efek trim pada body.
- **Keputusan**: **DITERIMA (ACCEPTED)**.
- **Bukti & Tindak Lanjut**: Dibuat file pengujian baru `test/validate_note_test.dart` dengan 4 kasus uji batas (*boundary test cases*), semuanya lulus dengan hasil `14/14 test PASSED`.

### D. Evaluasi Temuan #4 (Usulan Mengimpor SQLite ke Use Case)
- **Verifikasi**: Menelaah aturan fundamental Clean Architecture (*The Dependency Rule*).
- **Keputusan**: **DITOLAK KERAS (REJECTED)**.
- **Alasan Penolakan Teknis**: Usulan AI ini merupakan **pelanggaran fatal terhadap Clean Architecture**. Layer `domain` (termasuk use case dan entity) **WAJIB STERIL** dari dependensi framework luar seperti `sqflite`, `dio`, atau `flutter`. Jika `add_note.dart` mengimpor `sqflite`, maka layer domain menjadi terikat dengan database lokal, membatalkan independensi arsitektur, dan menyebabkan kegagalan pada uji sterilitas:
  ```powershell
  Get-ChildItem -Path lib/features/*/domain -Recurse -Filter *.dart | Select-String -Pattern "import 'package:sqflite"
  ```
  Interaksi dengan SQLite hanya boleh terjadi di layer `data` (`note_repository_impl.dart`).

### E. Evaluasi Temuan #5 (Usulan Membuat StateNotifier Manual)
- **Verifikasi**: Meninjau kebutuhan aplikasi dan prinsip Riverpod modern.
- **Keputusan**: **DITOLAK (REJECTED)**.
- **Alasan Penolakan Teknis**: `FutureProvider` dari Riverpod sudah secara otomatis menangani status asynchronous (`AsyncValue` yang memiliki state `.when(loading, error, data)`). Menggantinya dengan StateNotifier manual untuk operasi baca daftar sederhana adalah bentuk *over-engineering* yang menambah boilerplate kode tanpa memberikan nilai tambah teknis.

---

## 4. Tabel Rangkuman: Usulan AI vs Keputusan Final

| No | Temuan & Usulan AI | Level Menurut AI | Keputusan Anda | Alasan Teknis & Bukti | Tindak Lanjut |
| :---: | :--- | :---: | :---: | :--- | :--- |
| **1** | Validasi UI membisu jika judul kosong (*silent failure*) | **Blocker** | **DITERIMA** | Pengguna tidak mendapat *feedback* kesalahan saat input kosong. | Perbaiki `notes_page.dart` untuk menampilkan `SnackBar` merah dengan pesan kegagalan dari domain. |
| **2** | Whitespace lolos validasi jika hanya memeriksa `isEmpty` | **Blocker** | **DITERIMA** | String `"   "` bernilai `isEmpty == false`, berpotensi mengotori SQLite dengan catatan hampa. | Tambahkan `cleanTitle = title.trim()` di `AddNote` use case. |
| **3** | Pengujian unit test validasi kurang menyeluruh | **Saran** | **DITERIMA** | Belum ada tes untuk string kosong murni `""` dan karakter escape `\t`, `\n`. | Buat file `test/validate_note_test.dart` khusus memvalidasi 4 skenario. |
| **4** | Impor `sqflite` ke usecase untuk cek status database | **Blocker** | **DITOLAK** | **Melanggar Dependency Rule Clean Architecture**. Domain harus murni Dart tanpa dependensi database. | Pertahankan sterilitas domain layer. Uji sterilitas membuktikan 0 pelanggaran. |
| **5** | Ganti `FutureProvider` dengan `StateNotifier` manual | **Saran** | **DITOLAK** | *Over-engineering*. `FutureProvider` + `AsyncValue` sudah efisien dan idiomatik di Riverpod modern. | Pertahankan implementasi Riverpod yang sudah bersih dan ringkas. |

---

## 5. Ringkasan Evaluasi Kritis terhadap AI Reviewer

Praktikum ini membuktikan bahwa:
1. AI sangat efektif dalam mendeteksi *edge cases* fungsional (seperti whitespace dan UX silent failure).
2. Namun, AI berpotensi memberikan saran yang berbahaya bagi integritas arsitektur jika pengembang tidak memahami prinsip dasar arsitektur perangkat lunak.
3. Sebagai *lead engineer*, keputusan akhir selalu berada di tangan pengembang manusia yang bertanggung jawab atas keberlanjutan kode proyek.
