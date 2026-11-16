# Dokumentasi Bukti Mesin & Tangkapan Layar (Screenshots)

Folder ini memuat bukti eksekusi analisis kode otomatis, hasil uji unit & widget, serta skenario pengujian antarmuka aplikasi Minggu 10: Integrasi Fitur AI.

## Berkas Log Pengujian Mesin

1. **[`01_flutter_analyze_log.txt`](01_flutter_analyze_log.txt)**  
   Bukti luaran terminal `flutter analyze` yang menunjukkan **No issues found!** (analisis statis bersih tanpa *warning* atau *lint error*).

2. **[`02_flutter_test_log.txt`](02_flutter_test_log.txt)**  
   Bukti eksekusi **45 pengujian otomatis (All tests passed!)** yang mencakup:
   - Pengujian unit `AiService` (Chat, Multimodal OCR, Speech-to-Text, Vision Understanding, Error Handling, Quota Management, dan Caching Lokal).
   - Pengujian widget `ChatScreen` (Render antarmuka, sanitasi data NIK & Telepon, dan dialog API Key).
   - Pengujian widget `MultimodalScreen` (Navigasi tab OCR, Speech-to-Text, dan Vision AI).
   - Pengujian regresi eksisting Clean Architecture (Use Cases, Repository, dan Notifiers).

## Skenario Visual Antarmuka

| No | Skenario Pengujian | Deskripsi Antarmuka |
|:--:|:---|:---|
| 1 | **Chat Streaming & Loading** | Menampilkan bubble chat AI yang bertambah karakternya secara real-time (*SSE streaming*) dengan kursor berkedip dan status *AI sedang merespon...*. |
| 2 | **Sanitasi Data Sensitif** | Pengguna mengetik NIK 16 digit dan nomor HP; teks disensor menjadi `[REDACTED_NIK]` dan `[REDACTED_PHONE]` disertai SnackBar peringatan oranye. |
| 3 | **OCR Dokumen / KTM** | Pemilihan foto KTM via kamera/galeri, pemanggilan `aiService.recognizeText(imageFile)`, dan ekstraksi teks terstruktur. |
| 4 | **Speech-to-Text Mikrofon** | Perekaman suara lokal via `record` dengan tombol berdenyut merah, lalu konversi ke teks ucapan oleh AI. |
| 5 | **Vision / Image Understanding** | Pemilihan foto objek/produk dan analisis visual deskriptif oleh Gemini AI. |
| 6 | **Dialog Fallback & Offline** | Dialog peringatan *"Layanan AI Sibuk"* saat jaringan mati, dan tombol pengalihan ke mode offline lokal. |

