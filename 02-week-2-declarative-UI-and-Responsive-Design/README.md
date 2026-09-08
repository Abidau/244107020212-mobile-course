|  | Pemrograman Mobile |
|--|--|
| NIM |  244107020212|
| Nama |  Naufal Abid Aurizky |
| Kelas | TI - 3G |

## Praktikum: layout sederhana (warm-up)

pada praktikum ini membuat sebuah layout kartu profile mahasiswa menggunakan widget Flutter.

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/warm-up1.jpeg)

### Eksperimen warm-up

1. menghapus expanded, berfungsi untuk membatasi sebuah teks jika tidak menggunakan expanded teks akan terus menjadi panjang, dan jika menggunakan expanded teks akan terpotong sesuai container kartu tersebut

| Tanpa `Expanded` | Dengan `Expanded` |
|:---:|:---:|
| ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/eksperimen-warm-up1.jpeg) | ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/eksperimen-warm-up1.1.jpeg) |

2. mengganti mainAxisSize: MainAxisSize.min menjadi nilai default yang akan merubah tampilan menjadi lebih besar

| Nilai default `MainAxisSize.min` | Dengan `MainAxisSize.min` |
|:---:|:---:|
| ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/eksperimen-warm-up2.jpeg) | ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/warm-up2.1.jpeg) |

3. menambahkan satu baris data menggunakan pola Row + expanded

| Kode | Tampilan |
|:---:|:---:|
| ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/eksperimen-warm-up3.png) | ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/warm-up2.1.jpeg) |

## Praktikum: dashboard responsif

Untuk tahap ini, diawali dengan membuat flutter dengan menginstall melalui cmd seperti berikut ini

```
flutter create responsive_dashboard
```

Jika sudah penginstalan tersebut lanjut melakukan masuk kedalam sebuah flutter tersebut seperti berikut ini

```
cd responsive_dashboard
```

dan jika sudah memasuki folder tersebut jalankan perintah berikut ini

```
flutter run
```

Untuk tahap ini, membuat dashboard akademik menggunakan Flutter dengan pendekatan declarative UI. Dashboard menampilkan informasi mahasiswa dan beberapa informasi akademik seperti assignments, attendance, portfolio, dan current week

| Light Theme | Dark Theme |
|:---:|:---:|
| ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/DashboardResponsif1.jpeg) | ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/DashboardResponsif2.jpeg) |

## Tugas dan AI design exploration

### Tugas Utama

Tugas berikut ini adalah dashboard academic overview yang menggunakan layout responsif, light atau dark theme reusable widget, dan fitur aksesibilitas. Aplikasi juga melewati semua pengujian dasar dengan hasil All test passed!

| Vertical | Horizontal |
|:---:|:---:|
| ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/TugasUtama1.jpeg) | ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/TugasUtama2.jpeg) |

### AI Prompt Challenge

1. Prompt desain
![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/aiNo1.1.png)
![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/aiNo1.2.png)
![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/aiNo1.3.png)
![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/aiNo1.4.png)

2. Prompt penguatan konsep
![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/aiNo2.1.png)
![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/aiNo2.2.png)
![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/aiNo2.3.png)

3. Verification prompt
![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/aiNo3.1.png)
![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/aiNo3.2.png)

### Refactoring challenge

1. Kartu informasi dibuat menjadi widget `InfoCard` yang dapat digunakan berulang kali dengan title dan value yang berbeda, sehingga mengurangi duplikasi kode

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/InfoCard1.png)

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/InfoCard2.png)

2. Warna dan gaya teks yang ditulis secara hardcode diganti menggunakan `Theme.of(context)`  agar tampilan dapat menyesuaikan secara otomatis dengan light theme dan dark theme

|  | Kode Program |  |
|:---:|:---:|:---:|
| ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/No2.1.png) | ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/No2.2.png) | ![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/No2.3.png) |

3. Nilai breakpoint 700 dipindah ke konstanta kWideBreakpoint sehingga nilai tersebut hanya didefinisikan satu kali dan lebih mudah dikelola 

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/kWideBreakpoint.png)

4. Perintah `flutter analyze` digunakan untuk memeriksa kode dari error dan warning, dengan Hasil pemeriksaan menunjukkan No issues found! sehingga kode tidak memiliki masalah 

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/No4.jpeg)

### Testing Dasar

Kode pada praktikum tersebut gagal saat `flutter test` dikarenakan kode pada `find.byType(Card)` mencari semua widget Card yang terdapat pada halaman. Pada dashboard tersebut terdapat 4 Card , sehingga `tester.getSize()` menerima lebih dari satu widget yang akan menghasilkan error `Bad state: Too many elements`. untuk cara mengatasinya, digunakan `.first` pada `find.byType(Card)` yang akan menjadi `flutter test` mengambil hannya satu card pertama yang ditemukan. Setelah perubahan tersebut, saat menjalankan `flutter test` akan dapat berjalan dengan baik dan menghasilkan `All tests passed!`

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/TestingDasar.jpeg)