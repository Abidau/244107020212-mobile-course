import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../services/ai_service.dart';

/// Halaman Praktikum Bagian 4:
/// OCR (Optical Character Recognition), Speech-to-Text, dan Image Understanding
class MultimodalScreen extends StatefulWidget {
  final AiService? aiService;

  const MultimodalScreen({super.key, this.aiService});

  @override
  State<MultimodalScreen> createState() => _MultimodalScreenState();
}

class _MultimodalScreenState extends State<MultimodalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AiService _aiService;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // State OCR
  XFile? _ocrImage;
  String _ocrResult = '';
  bool _isOcrLoading = false;

  // State Speech-to-Text
  bool _isRecording = false;
  String? _recordedAudioPath;
  String _speechResult = '';
  bool _isSpeechLoading = false;

  // State Image Understanding
  XFile? _understandingImage;
  String _understandingResult = '';
  bool _isUnderstandingLoading = false;
  final TextEditingController _promptController = TextEditingController(
    text: 'Deskripsikan objek dan isi gambar ini secara detail.',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _aiService = widget.aiService ?? AiService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioRecorder.dispose();
    _promptController.dispose();
    super.dispose();
  }

  // ==================== LOGIKA OCR ====================
  Future<void> _pickOcrImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _ocrImage = picked;
          _ocrResult = '';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih gambar: $e');
    }
  }

  Future<void> _processOcr() async {
    if (_ocrImage == null) {
      _showErrorSnackBar('Silakan pilih atau ambil gambar terlebih dahulu.');
      return;
    }

    setState(() {
      _isOcrLoading = true;
      _ocrResult = '';
    });

    try {
      // Pemanggilan praktikum Langkah 4:
      // final result = await aiService.recognizeText(imageFile);
      final result = await _aiService.recognizeText(_ocrImage);
      setState(() {
        _ocrResult = result;
      });
    } catch (e) {
      setState(() {
        _ocrResult = 'Terjadi kesalahan OCR: $e';
      });
    } finally {
      setState(() {
        _isOcrLoading = false;
      });
    }
  }

  // ==================== LOGIKA SPEECH-TO-TEXT ====================
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // Hentikan perekaman suara
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _recordedAudioPath = path;
        });
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perekaman audio selesai!')),
          );
        }
      } else {
        // Cek izin mikrofon dan mulai merekam
        if (await _audioRecorder.hasPermission()) {
          final tempDir = io.Directory.systemTemp;
          final filePath =
              '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: filePath,
          );

          setState(() {
            _isRecording = true;
            _speechResult = '';
          });
        } else {
          _showErrorSnackBar('Izin mikrofon tidak diberikan.');
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _showErrorSnackBar('Kesalahan perekaman audio: $e');
    }
  }

  Future<void> _processSpeechToText() async {
    if (_recordedAudioPath == null) {
      _showErrorSnackBar('Silakan rekam suara Anda terlebih dahulu.');
      return;
    }

    setState(() {
      _isSpeechLoading = true;
      _speechResult = '';
    });

    try {
      // Pemanggilan praktikum Langkah 4:
      // final text = await aiService.speechToText(audioFile);
      final text = await _aiService.speechToText(_recordedAudioPath!);
      setState(() {
        _speechResult = text;
      });
    } catch (e) {
      setState(() {
        _speechResult = 'Terjadi kesalahan Speech-to-Text: $e';
      });
    } finally {
      setState(() {
        _isSpeechLoading = false;
      });
    }
  }

  // ==================== LOGIKA IMAGE UNDERSTANDING ====================
  Future<void> _pickUnderstandingImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _understandingImage = picked;
          _understandingResult = '';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih gambar: $e');
    }
  }

  Future<void> _processImageUnderstanding() async {
    if (_understandingImage == null) {
      _showErrorSnackBar('Pilih gambar objek/produk terlebih dahulu.');
      return;
    }

    setState(() {
      _isUnderstandingLoading = true;
      _understandingResult = '';
    });

    try {
      final prompt = _promptController.text.trim();
      final result = await _aiService.describeImage(
        _understandingImage,
        prompt: prompt.isNotEmpty ? prompt : null,
      );
      setState(() {
        _understandingResult = result;
      });
    } catch (e) {
      setState(() {
        _understandingResult = 'Terjadi kesalahan analisis gambar: $e';
      });
    } finally {
      setState(() {
        _isUnderstandingLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks berhasil disalin ke clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Vision & Speech'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.document_scanner_outlined), text: 'OCR'),
            Tab(icon: Icon(Icons.mic_outlined), text: 'Speech-to-Text'),
            Tab(icon: Icon(Icons.image_search_outlined), text: 'Vision'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOcrTab(theme),
          _buildSpeechTab(theme),
          _buildUnderstandingTab(theme),
        ],
      ),
    );
  }

  // ==================== TAB 1: OCR ====================
  Widget _buildOcrTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.indigo),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OCR mengekstrak teks dari foto KTM, kuitansi/struk belanja, dokumen, atau papan pengumuman.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Preview Gambar
        _buildImagePreview(
          image: _ocrImage,
          placeholderText: 'Belum ada gambar dokumen yang dipilih',
        ),

        const SizedBox(height: 12),

        // Tombol Kamera & Galeri
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickOcrImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickOcrImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeri'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Tombol Proses OCR
        FilledButton.icon(
          onPressed: (_ocrImage == null || _isOcrLoading) ? null : _processOcr,
          icon: _isOcrLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.text_fields),
          label: Text(_isOcrLoading ? 'Sedang Mengekstrak...' : 'Ekstrak Teks (OCR)'),
        ),

        const SizedBox(height: 16),

        // Kotak Hasil
        _buildResultBox(
          title: 'Hasil Ekstraksi OCR:',
          resultText: _ocrResult,
          isLoading: _isOcrLoading,
          theme: theme,
        ),
      ],
    );
  }

  // ==================== TAB 2: SPEECH-TO-TEXT ====================
  Widget _buildSpeechTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.mic, size: 20, color: Colors.teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Speech-to-Text mengubah suara pengguna menjadi teks tertulis untuk input cepat dan aksesibilitas.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Tombol Lingkaran Rekam Suara
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : theme.colorScheme.primary)
                            .withOpacity(0.35),
                        blurRadius: _isRecording ? 18 : 8,
                        spreadRadius: _isRecording ? 6 : 2,
                      )
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isRecording
                    ? 'Sedang merekam suara... Ketuk untuk berhenti'
                    : (_recordedAudioPath != null
                        ? 'Rekaman tersimpan! Siap dikonversi.'
                        : 'Ketuk mikrofon untuk mulai berbicara'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                  color: _isRecording ? Colors.red : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Tombol Konversi Speech-to-Text
        FilledButton.icon(
          onPressed: (_recordedAudioPath == null || _isSpeechLoading || _isRecording)
              ? null
              : _processSpeechToText,
          icon: _isSpeechLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.transcribe),
          label: Text(_isSpeechLoading ? 'Mengonversi Suara...' : 'Konversi ke Teks AI'),
        ),

        const SizedBox(height: 16),

        // Kotak Hasil
        _buildResultBox(
          title: 'Hasil Transkripsi Suara:',
          resultText: _speechResult,
          isLoading: _isSpeechLoading,
          theme: theme,
        ),
      ],
    );
  }

  // ==================== TAB 3: IMAGE UNDERSTANDING ====================
  Widget _buildUnderstandingTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.tertiaryContainer.withOpacity(0.4),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.remove_red_eye_outlined, size: 20, color: Colors.deepPurple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Image Understanding meminta AI mendeskripsikan produk, mengidentifikasi objek, atau membantu aksesibilitas visual.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Preview Gambar
        _buildImagePreview(
          image: _understandingImage,
          placeholderText: 'Belum ada gambar objek/produk yang dipilih',
        ),

        const SizedBox(height: 12),

        // Tombol Ambil Gambar
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickUnderstandingImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickUnderstandingImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeri'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Input Prompt Kustom
        TextField(
          controller: _promptController,
          decoration: const InputDecoration(
            labelText: 'Instruksi / Pertanyaan ke AI',
            hintText: 'Misal: Jelaskan merek, fungsi, dan kondisi objek ini',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),

        const SizedBox(height: 12),

        // Tombol Analisis
        FilledButton.icon(
          onPressed: (_understandingImage == null || _isUnderstandingLoading)
              ? null
              : _processImageUnderstanding,
          icon: _isUnderstandingLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(
            _isUnderstandingLoading ? 'Menganalisis Gambar...' : 'Minta Deskripsi AI',
          ),
        ),

        const SizedBox(height: 16),

        // Kotak Hasil
        _buildResultBox(
          title: 'Hasil Deskripsi Gambar:',
          resultText: _understandingResult,
          isLoading: _isUnderstandingLoading,
          theme: theme,
        ),
      ],
    );
  }

  // ==================== WIDGET KOMPONEN BANTU ====================
  Widget _buildImagePreview({required XFile? image, required String placeholderText}) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(image.path, fit: BoxFit.cover)
                  : Image.file(io.File(image.path), fit: BoxFit.cover),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    placeholderText,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildResultBox({
    required String title,
    required String resultText,
    required bool isLoading,
    required ThemeData theme,
  }) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('AI sedang memproses input multimodal...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (resultText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Salin Teks',
                onPressed: () => _copyToClipboard(resultText),
              ),
            ],
          ),
          const Divider(),
          SelectableText(
            resultText,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

