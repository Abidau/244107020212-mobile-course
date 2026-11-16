import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week7_clean_architecture/features/chat_screen.dart';
import 'package:week7_clean_architecture/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatScreen Widget Tests', () {
    testWidgets('Renders ChatScreen elements properly', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AiService(storage: const FlutterSecureStorage());

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(aiService: service),
        ),
      );
      await tester.pump();

      // Memeriksa judul dan greeting bot awal
      expect(find.text('AI Chat Assistant'), findsOneWidget);
      expect(find.textContaining('Halo! Saya asisten AI Anda'), findsOneWidget);

      // Memeriksa kolom input dan tombol kirim
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Memeriksa banner peringatan API Key
      expect(find.textContaining('API Key belum disetel'), findsWidgets);
    });

    testWidgets('Sanitizes sensitive data (NIK and phone) before displaying/sending',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'dummy-api-key'});

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Pesan diterima aman.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = AiService(
        storage: const FlutterSecureStorage(),
        client: mockClient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(aiService: service),
        ),
      );
      await tester.pump();

      // Input pesan berisi NIK 16 digit dan nomor HP
      final input = find.byType(TextField);
      await tester.enterText(
        input,
        'Halo AI, ini data saya: NIK 3507123456789012 dan nomor 081234567890 tolong bantu.',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Memeriksa bahwa NIK dan nomor telepon berhasil disamarkan (redacted)
      expect(find.textContaining('3507123456789012'), findsNothing);
      expect(find.textContaining('[REDACTED_NIK: 3507********9012]'), findsOneWidget);
      expect(find.textContaining('[REDACTED_PHONE: 0812****]'), findsOneWidget);

      // Memeriksa SnackBar keamanan muncul
      expect(
        find.textContaining('Data sensitif (NIK/telepon/email) disamarkan'),
        findsOneWidget,
      );
    });

    testWidgets('Opens API Key dialog when key icon is pressed', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AiService(storage: const FlutterSecureStorage());

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(aiService: service),
        ),
      );
      await tester.pump();

      // Tekan tombol pengaturan API key di AppBar
      await tester.tap(find.byTooltip('Pengaturan API Key'));
      await tester.pumpAndSettle();

      // Memeriksa dialog pengaturan API Key muncul
      expect(find.text('Pengaturan API Key'), findsOneWidget);
      expect(find.text('Gemini API Key'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });
  });
}

