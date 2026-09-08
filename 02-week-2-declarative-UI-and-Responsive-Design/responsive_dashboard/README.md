|  | Pemrograman Mobile |
|--|--|
| NIM |  244107020212|
| Nama |  Naufal Abid Aurizky |
| Kelas | TI - 3G |

## Praktikum: layout sederhana (warm-up)

pada praktikum ini membuat sebuah layout kartu profile mahasiswa menggunakan widget Flutter.

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/warm-up1.jpeg)

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/warm-up2.jpeg)

## Praktikum: dashboard responsif

Untuk tahap ini, membuat dashboard akademik menggunakan Flutter dengan pendekatan declarative UI. Dashboard menampilkan informasi mahasiswa dan beberapa informasi akademik seperti assignments, attendance, portfolio, dan current week

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/DashboardResponsif1.jpeg)

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/DashboardResponsif2.jpeg)

## Tugas dan AI design exploration

### Tugas Utama

Tugas berikut ini adalah dashboard academic overview yang menggunakan layout responsif, light atau dark theme reusable widget, dan fitur aksesibilitas. Aplikasi juga melewati semua pengujian dasar dengan hasil All test passed!

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/TugasUtama1.jpeg)

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/TugasUtama2.jpeg)

### Refactoring challenge

1. Kartu informasi dibuat menjadi widget InfoCard yang dapat digunakan berulang kali dengan title dan value yang berbeda, sehingga mengurangi duplikasi kode

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/InfoCard1.png)

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/InfoCard2.png)

2. Warna dan gaya teks yang ditulis secara hardcode diganti menggunakan Theme.of(context)  agar tampilan dapat menyesuaikan secara otomatis dengan light theme dan dark theme

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/No2.1.png)

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/No2.2.png)

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/No2.3.png)

3. Nilai breakpoint 700 dipindah ke konstanta kWideBreakpoint sehingga nilai tersebut hanya didefinisikan satu kali dan lebih mudah dikelola 

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/kWideBreakpoint.png)

4. Perintah flutter analyze digunakan untuk memeriksa kode dari error dan warning, dengan Hasil pemeriksaan menunjukkan No issues found! sehingga kode tidak memiliki masalah 

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/No4.jpeg)

### Testing Dasar

![Screenshot](../02-week-2-declarative-UI-and-Responsive-Design/screenshots/TestingDasar.jpeg)