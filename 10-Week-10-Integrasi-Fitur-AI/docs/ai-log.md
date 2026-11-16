# Log Interaksi AI & Verifikasi Model (AI Interaction Log)

| Parameter | Data Mahasiswa |
|:---|:---|
| **Mata Kuliah** | Pemrograman Mobile |
| **NIM** | 244107020212 |
| **Nama** | Naufal Abid Aurizky |
| **Kelas** | TI - 3G |
| **Topik Praktikum** | Minggu 10: Integrasi Fitur AI (Chat, Multimodal OCR, STT, Vision, Privacy & Fallback) |
| **Model AI yang Digunakan** | Google Gemini 1.5 Flash (`gemini-1.5-flash`) via Generative Language API |

---

## 1. System Prompt (Peran dan Batasan Sistem)

Dalam arsitektur aplikasi `10-Week-10-Integrasi-Fitur-AI`, peran sistem dikonfigurasi melalui instruksi baku (*system instruction/prompt*) untuk memandu perilaku model dan menjaga kepatuhan privasi pengguna.

### Format System Prompt Baku:
```text
Role: Asisten Cerdas Mobile Flutter (AI Assistant).
Tugas:
1. Menjawab pertanyaan pengguna seputar materi pemrograman mobile, Clean Architecture, Riverpod, dan database SQLite secara ringkas, akurat, dan edukatif.
2. Melakukan Optical Character Recognition (OCR) pada citra dokumen (KTM, struk kuitansi, dokumen resmi) secara murni dan terstruktur tanpa menambah kata pembuka atau basa-basi.
3. Mentranskripsikan rekaman audio pengguna (Speech-to-Text) ke teks bahasa Indonesia secara presisi.
4. Memberikan deskripsi visual (Image Understanding) yang jelas, netral, dan membantu aksesibilitas.
Batasan Keamanan (Security Constraints):
- Jangan pernah meminta atau mencatat data identitas pribadi (NIK, password, nomor kartu kredit, alamat rumah).
- Jika menerima teks dengan format sensor ([REDACTED_*]), proseslah konteks tanpa berusaha menebak data aslinya.
- Format teks balasan rapi dengan Markdown agar mudah dibaca di layar mobile.
```

---

## 2. Log Interaksi 1: Chat Interface & Sanitasi Data Sensitif (Langkah 3)

### A. Skenario Uji 1: Tanya Jawab Konseptual
- **User Prompt:**
  ```text
  "Jelaskan prinsip pemisahan layer pada Clean Architecture di Flutter dan mengapa layer Domain harus murni Dart?"
  ```
- **Output Awal AI (Gemini 1.5 Flash):**
  ```text
  Clean Architecture di Flutter membagi kode ke dalam 3 layer utama:
  1. Presentation Layer: Berisi Widget UI dan State Management (seperti Riverpod). Layer ini hanya menampilkan data dan menangkap input pengguna.
  2. Domain Layer: Berisi entitas bisnis (Entities) dan aturan use case (Use Cases). Layer ini dibuat murni bahasa Dart tanpa mengimpor pustaka UI (package:flutter) maupun database agar independen dari framework, mudah diuji secara instan dengan unit test, dan tahan terhadap perubahan teknologi eksternal.
  3. Data Layer: Berisi implementasi repository, model transfer data (Data Transfer Object / DTO), serta koneksi ke SQLite atau REST API eksternal.
  
  Aturan Ketergantungan (Dependency Rule): Ketergantungan selalu mengarah ke dalam. Presentation dan Data bergantung pada Domain, sedangkan Domain tidak bergantung pada siapapun.
  ```

### B. Skenario Uji 2: Pengujian Filter Keamanan Privasi (Sanitization Test)
- **User Input Mentah (Mengandung Data Sensitif):**
  ```text
  "Halo AI, tolong simpan data anggota ini: NIK 3507123456789012 dan nomor HP 081234567890 atas nama mahasiswa TI Polinema."
  ```
- **Hasil Sanitasi di Sisi Klien (Sebelum HTTP Request Dikirim):**
  ```text
  "Halo AI, tolong simpan data anggota ini: NIK [REDACTED_NIK: 3507********9012] dan nomor HP [REDACTED_PHONE: 0812****] atas nama mahasiswa TI Polinema."
  ```
- **Output AI:**
  ```text
  Halo! Baik, data anggota telah dicatat dengan identitas terproteksi ([REDACTED_NIK] dan [REDACTED_PHONE]) sebagai mahasiswa TI Polinema. Informasi sensitif telah disamarkan demi menjaga keamanan dan privasi data pribadi Anda sesuai standar perlindungan data digital.
  ```
- **Status:** **TERVERIFIKASI AMAN** (Data mentah tidak pernah meninggalkan perangkat pengguna).

---

## 3. Log Interaksi 2: Optical Character Recognition / OCR (Langkah 4)

- **Instruksi Ekstraksi AI:**
  ```text
  "Lakukan OCR (Optical Character Recognition) pada gambar ini. Ekstrak seluruh teks yang terbaca (seperti pada KTM, struk/receipt, dokumen, atau papan pengumuman) secara akurat dan terstruktur tanpa menambah kata pengantar pembuka atau penutup."
  ```
- **Input Media:** Citra Kartu Tanda Mahasiswa (KTM) Politeknik Negeri Malang format JPEG (base64 payload).
- **Output Awal AI:**
  ```text
  POLITEKNIK NEGERI MALANG
  KARTU TANDA MAHASISWA
  NIM     : 244107020212
  NAMA    : NAUFAL ABID AURIZKY
  PRODI   : D4 TEKNIK INFORMATIKA
  JURUSAN : TEKNOLOGI INFORMASI
  STATUS  : MAHASISWA AKTIF
  ```
- **Verifikasi:** Ekstraksi tepat 100% pada nama, NIM, dan program studi tanpa halusinasi karakter.

---

## 4. Log Interaksi 3: Speech-to-Text / Transkripsi Audio (Langkah 4)

- **Instruksi Transkripsi AI:**
  ```text
  "Lakukan Speech-to-Text (transkripsi audio suara) secara persis dan akurat. Tuliskan kembali ucapan suara dalam teks bahasa Indonesia atau bahasa asalnya tanpa teks pengantar."
  ```
- **Input Media:** Rekaman suara mikrofon via pustaka `record` (audio AAC/M4A durasi 4 detik).
- **Ucapan Asli Pengguna:** *"Tolong tambahkan catatan belanja sayur bayam dan telur ayam."*
- **Output Awal AI:**
  ```text
  Tolong tambahkan catatan belanja sayur bayam dan telur ayam.
  ```
- **Verifikasi:** Transkripsi bahasa Indonesia bersih tanpa ada pemenggalan kata (*word clipping*).

---

## 5. Log Interaksi 4: Image Understanding / Vision AI (Langkah 4)

- **User Prompt:**
  ```text
  "Deskripsikan objek dan isi gambar ini secara detail dan terstruktur untuk kebutuhan identifikasi objek, deskripsi produk, atau aksesibilitas."
  ```
- **Input Media:** Foto buku catatan fisik di atas meja belajar dengan cangkir kopi.
- **Output Awal AI:**
  ```text
  Gambar menampilkan area kerja belajar dengan objek-objek berikut:
  1. Objek Utama: Sebuah buku catatan bersampul kulit cokelat terbuka di bagian tengah, memperlihatkan tulisan tangan bergaris rapi.
  2. Objek Pendukung:
     - Satu cangkir keramik putih berisi kopi hitam di sisi kanan atas.
     - Sebuah bolpoin tinta hitam tergeletak di atas lembaran buku catatan.
     - Permukaan meja berbahan kayu dengan serat cokelat muda alami.
  3. Pencahayaan: Cahaya alami hangat dari arah kiri dengan kontras bayangan lembut.
  4. Manfaat Aksesibilitas: Objek teridentifikasi dengan kontras tinggi, aman untuk panduan pengguna tuna netra.
  ```

---

## 6. Log Interaksi 5: Error Handling & Fallback ke Mode Offline (Langkah 5)

### Skenario: Jaringan Terputus / API Key Belum Diatur / Status HTTP 429
- **Kondisi:** Simulasi kegagalan koneksi internet atau batas kuota harian tercapai.
- **Respon Penanganan Sistem:**
  1. Sistem mendeteksi `SocketException` atau kode error HTTP `429 Too Many Requests`.
  2. Dialog fallback muncul di layar:
     - **Judul:** `Layanan AI Sibuk`
     - **Pesan:** `Coba lagi nanti atau gunakan mode offline.`
     - **Opsi Aksi:** `[Tutup]` dan `[Gunakan Mode Offline]`.
  3. Saat pengguna memilih `Gunakan Mode Offline`, sistem memanggil generator pengetahuan lokal `AiService.getOfflineFallback(question)`:
     ```text
     [Mode Offline]: Clean Architecture membagi kode menjadi 3 layer independen: 
     Presentation (UI/Widget & Provider), Domain (Entities & Use Cases murni Dart), 
     dan Data (Models, Data Sources, Repositories Implementation). Aturan dependensi 
     selalu mengarah ke dalam (Domain tidak bergantung layer lain).
     ```
- **Kesimpulan:** Pengalaman pengguna (*User Experience*) tetap terjaga dengan lancar tanpa crash aplikasi.

