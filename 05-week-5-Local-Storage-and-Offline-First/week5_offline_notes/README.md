|  | Pemrograman Mobile |
|--|--|
| NIM |  244107020212|
| Nama |  Naufal Abid Aurizky |
| Kelas | TI - 3G |

## Praktikum 1 — Aplikasi multi-page dengan GoRouter

pada praktikum satu ini membuat sebuah flutter baru bernama `week3_navigation` yang akan digunakan untuk mempraktikkan navigasi menggunakan gorouter 

![Screenshot](../week3_navigation/screenshot/prak1.1.png)

dan langkah selanjutnya, menambahkan package `go_router` menggunakan perintah dibawah ini agar aplikasi dapat menggunakan sistem routing deklaratif dari gorouter

![Screenshot](../week3_navigation/screenshot/prak1.2.png)

### Hasil dari Praktikum 1

membuat struktur folder yang berisi `home_page.dart` dan `detail_page.dart` untuk memisahkan halaman utama dan halaman detail, dengan mendefinisikan gorouter di main.dart dengan route / untuk halaman Home dan route /detail/:id untuk halaman detail yang menerima parameter id tersebut

| Halaman Home | Halaman Detail |
|:---:|:---:|
| ![Screenshot](../week3_navigation/screenshot/prak1.home.jpeg) | ![Screenshot](../week3_navigation/screenshot/prak1.detail.jpeg) |

## Praktikum 2 — Aplikasi ToDo dengan Riverpod

membuat project flutter baru bernama `week3_todo` dan menambahkan package `flutter_riverpod` sebagai dependency untuk mengimplementasikan state management

![Screenshot](../week3_navigation/screenshot/prak2.1.png)

![Screenshot](../week3_navigation/screenshot/prak2.2.png)

### Hasil dari Praktikum 2

dari praktikum 2 ini, memahami pengguna Riverpod untuk mengelola state aplikasi dan mengetahui perbedaan penggunaan `ref.watch()` untuk memantau perubahan state dengan `ref.read()` untuk menjalankan aksi pada callback

| Halaman Home | Inputan Todo | Output Todo |
|:---:|:---:|:---:|
| ![Screenshot](../week3_navigation/screenshot/prak2.3.jpeg) | ![Screenshot](../week3_navigation/screenshot/prak2.4.jpeg) | ![Screenshot](../week3_navigation/screenshot/prak2.5.jpeg) |

## AsyncValue: loading, error, success

Melalu `AsyncValue`, memahami bahwa kondisi loading, error, dan success dapat dikelola dalam satu state sehinffa UI dapat memberikan tampilan yang sesuai tanpa harus menggunakan beberapa variabel boolean secara terpisah

![Screenshot](../week3_navigation/screenshot/AsyncValue.png)

## Praktikum 3 — Uji ketiga state

1. menjalankan aplikasi dan mengamati bahwa loading ditampilkan selama 2 detik sebelum data produk berhasil ditampilkan

| Loading | Masuk ke halaman utama |
|:---:|:---:|
| ![Screenshot](../week3_navigation/screenshot/prak3.1.jpeg) | ![Screenshot](../week3_navigation/screenshot/prak3.2.jpeg) |

2. mengubah sementara method build() dengan `throw Exception('Gagal terhubung ke server')` untuk mensimulasikan kegagalan koneksi ke server

| Before | After | Coba Lagi |
|:---:|:---:|:---:|
| ![Screenshot](../week3_navigation/screenshot/prak3.2build()_before.png) | ![Screenshot](../week3_navigation/screenshot/prak3.2build()_after.png) | ![Screenshot](../week3_navigation/screenshot/prak3.2CobaLagi.jpeg) |

3.menekan tombol `coba lagi` sehingga `ref.invalidate(productProvider)` menjalankan kembali provider yang sebelumnya mengalami error

### Kode

| Before | After |
|:---:|:---:|
| ![Screenshot](../week3_navigation/screenshot/prak3.3before.png) | ![Screenshot](../week3_navigation/screenshot/prak3.3after.png) |

### Hasil

| Gagal | Loading | Success |
|:---:|:---:|:---:|
| ![Screenshot](../week3_navigation/screenshot/prak3.3tombol_cobalagi0.jpeg) | ![Screenshot](../week3_navigation/screenshot/prak3.3tombol_cobalagi1.jpeg) | ![Screenshot](../week3_navigation/screenshot/prak3.3tombol_cobalagi2.jpeg) |

4. mempertahankan data lama atau stale data menampilkan indikator refresh dapat memberikan pengalam pengguna yang lebih baik karena pengguna tetap dapat melihat informasi yang tersedia selama proses pembaruan berlangsung

## AI Challenge

| Gagal | Loading | Success |
|:---:|:---:|:---:|
| ![Screenshot](../week3_navigation/screenshot/ai.3_error-gagal.jpeg) | ![Screenshot](../week3_navigation/screenshot/ai.4_loading.jpeg) | ![Screenshot](../week3_navigation/screenshot/ai.2_success.jpeg) |

### 1. Immutable State
**Status: Lolos**

State dikelola secara immutable. Tidak ditemukan penggunaan `state.add()`
atau mutasi list secara langsung. Perubahan state dilakukan dengan
memberikan nilai baru melalui assignment pada `state`.

### 2. Penggunaan ref.watch dan ref.read
**Status: Lolos**

`ref.watch(statsProvider)` digunakan di dalam method `build()` untuk
mengamati perubahan state provider. `ref.read(statsProvider.notifier)`
digunakan pada callback tombol Retry untuk menjalankan aksi.

### 3. Penanganan AsyncValue
**Status: Lolos**

UI menangani tiga kondisi asynchronous:
- Loading menggunakan `CircularProgressIndicator`.
- Error menggunakan pesan kesalahan dan tombol Retry.
- Success menggunakan `ListView.builder` yang menampilkan 3 item statistik.

Tombol Retry mengubah state menjadi `AsyncLoading` dan menjalankan
kembali proses pengambilan data menggunakan `AsyncValue.guard`.

### 4. Deklarasi Provider
**Status: Lolos**

Provider menggunakan tipe eksplisit:

`AsyncNotifierProvider<StatsNotifier, List<String>>`

Tidak ditemukan provider statistik yang duplikat.

### 5. Penggunaan API Riverpod
**Status: Lolos**

Implementasi menggunakan API Riverpod modern dengan `AsyncNotifier`,
`AsyncNotifierProvider`, dan `ConsumerWidget`. Tidak menggunakan
`StateProvider`, `StateNotifierProvider` lama, atau Consumer bertingkat
yang tidak diperlukan.

### 6. Flutter Analyze dan Test
**Status: Lolos**

Hasil `flutter analyze`:

No issues found!

Hasil `flutter test`:

All tests passed!

Sebanyak 2 unit test berhasil dijalankan, mencakup kondisi success
dan error pada `StatsNotifier`. 

![Screenshot](../week3_navigation/screenshot/ai.1.jpeg)

## Refactoring dan testing

### Refactoring

1. 

lib/widgets/note_tile.dart

lib/pages/notes_page.dart


2. 

#### Kode

| Kode 1 | Kode 2 |
|:---:|:---:|
| ![Screenshot](../week3_navigation/screenshot/refactoring2.1.png) | ![Screenshot](../week3_navigation/screenshot/refactoring2.2.png) |


#### Hasil

| Checklist | After Checklist |
|:---:|:---:|
| ![Screenshot](../week3_navigation/screenshot/refactoring2_checklist.jpeg) | ![Screenshot](../week3_navigation/screenshot/refactoring2_remove.jpeg) |

3. 

![Screenshot](../week3_navigation/screenshot/refactoring3_install.png)

#### Hasil

| ToDo | Statistik |
|:---:|:---:|
| ![Screenshot](../week3_navigation/screenshot/refactoring3_todo.jpeg) | ![Screenshot](../week3_navigation/screenshot/refactoring3_statistik.jpeg) |

### Testing

pada impementasi awal terjadi error dikarenakan `find.text('Kerjakan PR minggu 3')` menemukan dua widget, yaitu teks pada Todo yang baru ditambahkan dan teks yang masih terdapat pada `TextField` dialog, yang terjadi karena `tester.pump()` hanya menjalankan satu frame sehingga proses penutupan dialog belum sepenuhnya selesai. Perbaikan dilakukan dengan mengganti `pump()` menjadi `pumpAndSettle()` setelah tombol "Tambah" ditekan. maka dari itu, test menunggu seluruh perubahan UI dan animasi selesai sebelum melakukan assertion

#### Before

![Screenshot](../week3_navigation/screenshot/testing_flutter_analyze.png)

![Screenshot](../week3_navigation/screenshot/testing_flutter_test.png)

#### After

![Screenshot](../week3_navigation/screenshot/testing_success.png)

## Refleksi

1. `setState` masih cukup digunakan ketika state hanya dibutuhkan satu widget atau satu halaman, jika state perlu digunakan beberapa halaman a tau widget dan harus terjaga ketika berpindah halaman, maka Riverpod lebih sesuai karena state akan dikelola diluar widget dan dapat diakses oleh widget yang membutuhkan

2. `context.go` digunakan untuk berpindah ke suatu route dan mengganti lokasi halaman, sedangkan `context.push` digunakan untuk menambahkan halaman baru ke atas stack navigasi, sehingga halaman sebelumnya masih dapat kembali menggunakan tombol back

3. AsyncValue membantu mencegah bug karena dikelola dalam satu state yang terstruktur. Jika menggunakan tiga boolean terpisah, kombinasi status yang tidak sesuai dapat terjadi, misalnya `isloading` dan `isError` berinilai true. Dengan AsyncValue, aplikasi dapat menangani setiap kondisi menggunakan loading, error, dan data 

4. beberapa bagian kode yang belum sesuai dengan struktur project dan aturan Riverpod yang digunakan, memperbaiki pengguna `ref.watch dan `ref.read agar sesuai dengan tempat penggunaannya, memastikan state diubah secara immutable, serta memastikan UI menangani kondisi loading, error, dan success. Perbaikan tersebut dilakukan agar kode dapat dijalankan dengan benar, lebih mudah dipahami, dan sesuai dengan konsep yang dipelajari pada praktikum