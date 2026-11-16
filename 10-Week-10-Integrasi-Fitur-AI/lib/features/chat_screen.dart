import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/ai_service.dart';
import 'multimodal_screen.dart';

/// Model representasi pesan percakapan
class ChatMessage {
  final String id;
  String text;
  final bool isUser;
  final DateTime timestamp;
  bool isStreaming;
  bool isError;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isStreaming = false,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Layar Antarmuka Chat dengan AI (Praktikum Langkah 3)
/// Dilengkapi dengan streaming response, indikator loading, dan filter privasi data sensitif.
class ChatScreen extends StatefulWidget {
  final AiService? aiService;

  const ChatScreen({super.key, this.aiService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final AiService _aiService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _isStreaming = false;
  bool _hasApiKey = false;
  StreamSubscription<String>? _streamSubscription;

  // Daftar saran pertanyaan cepat
  final List<String> _quickPrompts = [
    'Ringkas materi Clean Architecture',
    'Beri ide judul catatan produktivitas',
    'Bagaimana cara mengamankan API key di Flutter?',
    'Jelaskan perbedaan REST API dan GraphQL',
  ];

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService();
    _checkApiKey();
    _addInitialBotGreeting();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final key = await _aiService.getApiKey();
    if (mounted) {
      setState(() {
        _hasApiKey = key != null && key.trim().isNotEmpty;
      });
    }
  }

  void _addInitialBotGreeting() {
    _messages.add(
      ChatMessage(
        id: 'bot_greeting',
        text:
            'Halo! Saya asisten AI Anda. Tanyakan apa saja seputar materi atau pengembangan aplikasi Flutter Anda.\n\n'
            '🔒 Catatan Keamanan: Mohon tidak mengirimkan data sensitif seperti NIK, nomor telepon, atau alamat pribadi.',
        isUser: false,
      ),
    );
  }

  /// Memeriksa dan menyamarkan data sensitif pengguna (Catatan Keamanan Codelab)
  String _sanitizeInput(String input) {
    var sanitized = input;

    // Deteksi NIK (16 digit berurutan)
    final nikRegex = RegExp(r'\b\d{16}\b');
    sanitized = sanitized.replaceAllMapped(nikRegex, (match) {
      final nik = match.group(0)!;
      return '[REDACTED_NIK: ${nik.substring(0, 4)}********${nik.substring(12)}]';
    });

    // Deteksi Nomor Telepon Indonesia (+62 / 08xx dengan minimal 9-13 digit)
    final phoneRegex = RegExp(r'(\+62|62|0)8[1-9][0-9]{6,10}\b');
    sanitized = sanitized.replaceAllMapped(phoneRegex, (match) {
      final phone = match.group(0)!;
      return '[REDACTED_PHONE: ${phone.substring(0, 4)}****]';
    });

    // Deteksi Alamat Email
    final emailRegex =
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    sanitized = sanitized.replaceAllMapped(emailRegex, (match) {
      return '[REDACTED_EMAIL]';
    });

    return sanitized;
  }

  /// Menangani pengiriman pesan dan streaming response
  Future<void> _handleSendMessage([String? predefinedText]) async {
    final rawText = predefinedText ?? _textController.text;
    final trimmedText = rawText.trim();
    if (trimmedText.isEmpty || _isLoading || _isStreaming) return;

    // Catatan keamanan: Sensor data sensitif (NIK, telepon, email)
    final sanitizedText = _sanitizeInput(trimmedText);
    final wasSanitized = sanitizedText != trimmedText;

    if (!wasSanitized) {
      _textController.clear();
    } else {
      _textController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Data sensitif (NIK/telepon/email) disamarkan demi privasi pengguna.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final botMessageId = 'bot_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _messages.add(
        ChatMessage(
          id: userMessageId,
          text: sanitizedText,
          isUser: true,
        ),
      );

      // Placeholder bot message untuk menampung streaming chunks
      _messages.add(
        ChatMessage(
          id: botMessageId,
          text: '',
          isUser: false,
          isStreaming: true,
        ),
      );

      _isLoading = true;
      _isStreaming = true;
    });

    _scrollToBottom();

    final botMessage = _messages.firstWhere((m) => m.id == botMessageId);

    try {
      final apiKey = await _aiService.getApiKey();
      if (apiKey == null || apiKey.trim().isEmpty) {
        throw Exception(
          'API key tidak tersedia. Silakan atur di tombol kunci (pengaturan).',
        );
      }

      // Mengonsumsi stream respon secara bertahap (Streaming Response)
      final stream = _aiService.askStream(sanitizedText);
      final buffer = StringBuffer();

      _streamSubscription = stream.listen(
        (chunk) {
          if (mounted) {
            setState(() {
              _isLoading = false; // Chunk pertama diterima
              buffer.write(chunk);
              botMessage.text = buffer.toString();
            });
            _scrollToBottom();
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isStreaming = false;
              botMessage.isStreaming = false;
              botMessage.isError = true;
              botMessage.text =
                  'Terjadi kesalahan saat memanggil AI:\n$error\n\n'
                  'Pastikan API key valid dan koneksi internet aktif.';
            });
            _scrollToBottom();
            _showFallbackDialog(error.toString(), sanitizedText, botMessage);
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isStreaming = false;
              botMessage.isStreaming = false;
              if (botMessage.text.trim().isEmpty) {
                botMessage.text = 'Tidak ada balasan dari AI.';
              }
            });
            _scrollToBottom();
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isStreaming = false;
          botMessage.isStreaming = false;
          botMessage.isError = true;
          botMessage.text =
              '$e\n\n💡 Ketuk ikon kunci di pojok kanan atas untuk memasukkan Gemini API Key Anda.';
        });
        _scrollToBottom();
        _showFallbackDialog(e.toString(), sanitizedText, botMessage);
      }
    }
  }

  /// Praktikum Bagian 5: Dialog Fallback saat AI Sibuk / Error / Down
  void _showFallbackDialog(
    String error,
    String question,
    ChatMessage botMessage,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Layanan AI Sibuk'),
        content: const Text('Coba lagi nanti atau gunakan mode offline.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                botMessage.isError = false;
                botMessage.isStreaming = false;
                botMessage.text = _aiService.getOfflineFallback(question);
              });
              _scrollToBottom();
            },
            icon: const Icon(Icons.offline_bolt_outlined, size: 18),
            label: const Text('Gunakan Mode Offline'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Dialog pengaturan API Key (FlutterSecureStorage)
  Future<void> _showApiKeyDialog() async {
    final currentKey = await _aiService.getApiKey() ?? '';
    final dialogController = TextEditingController(text: currentKey);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Pengaturan API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key Anda. Kunci ini akan disimpan secara aman di FlutterSecureStorage.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dialogController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dapatkan API Key gratis di Google AI Studio (aistudio.google.com).',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          if (currentKey.isNotEmpty)
            TextButton(
              onPressed: () async {
                await _aiService.deleteApiKey();
                await _checkApiKey();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key berhasil dihapus')),
                  );
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final newKey = dialogController.text.trim();
              if (newKey.isNotEmpty) {
                await _aiService.saveApiKey(newKey);
                await _checkApiKey();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key berhasil disimpan!')),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Chat Assistant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _hasApiKey ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _hasApiKey ? 'Gemini AI Siap' : 'API Key Belum Disetel',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Fitur Multimodal (OCR & STT)',
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () {
              try {
                context.push('/multimodal');
              } catch (_) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MultimodalScreen()),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Pengaturan API Key',
            icon: Icon(
              _hasApiKey ? Icons.key : Icons.key_off_outlined,
              color: _hasApiKey ? Colors.amber[700] : Colors.grey,
            ),
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            tooltip: 'Bersihkan Chat',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addInitialBotGreeting();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner peringatan jika API key belum diatur
          if (!_hasApiKey)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.withOpacity(0.15),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'API Key belum disetel. Ketuk ikon kunci untuk mengonfigurasi.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _showApiKeyDialog,
                    child: const Text('Setel Kunci'),
                  ),
                ],
              ),
            ),

          // Daftar Pesan Chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),

          // Chips Rekomendasi Pertanyaan Cepat
          if (_messages.length <= 2 && !_isLoading && !_isStreaming)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        _quickPrompts[idx],
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _handleSendMessage(_quickPrompts[idx]),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 4),

          // Input Text & Tombol Kirim
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted:
                          (_isLoading || _isStreaming) ? null : (_) => _handleSendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan ke AI... (hindari data pribadi)',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: theme.hintColor,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Kirim Pesan',
                    onPressed: (_isLoading || _isStreaming)
                        ? null
                        : () => _handleSendMessage(),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget per item bubble percakapan
  Widget _buildMessageItem(ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isError
                  ? Colors.red[100]
                  : theme.colorScheme.primaryContainer,
              child: Icon(
                message.isError ? Icons.error_outline : Icons.auto_awesome,
                size: 16,
                color: message.isError
                    ? Colors.red
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : message.isError
                        ? Colors.red.withOpacity(0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Teks balasan / streaming text
                  if (message.text.isNotEmpty)
                    SelectableText(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUser
                            ? theme.colorScheme.onPrimary
                            : message.isError
                                ? Colors.red[900]
                                : theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),

                  // Indikator Loading / Streaming Response (Langkah 3)
                  if (message.isStreaming && message.text.isEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI sedang merespon...',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),

                  // Kursor berkedip saat sedang streaming response
                  if (message.isStreaming && message.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Streaming...',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 4),

                  // Waktu pengiriman
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: const Icon(Icons.person, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

