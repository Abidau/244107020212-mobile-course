import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/features/multimodal_screen.dart';
import 'package:week7_clean_architecture/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MultimodalScreen Widget Tests', () {
    testWidgets('Renders all 3 tabs: OCR, Speech-to-Text, Vision', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AiService(storage: const FlutterSecureStorage());

      await tester.pumpWidget(
        MaterialApp(
          home: MultimodalScreen(aiService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Memeriksa judul AppBar dan 3 tab
      expect(find.text('AI Vision & Speech'), findsOneWidget);
      expect(find.text('OCR'), findsOneWidget);
      expect(find.text('Speech-to-Text'), findsOneWidget);
      expect(find.text('Vision'), findsOneWidget);

      // Memeriksa elemen Tab 1 (OCR) aktif
      expect(find.textContaining('OCR mengekstrak teks dari foto KTM'), findsOneWidget);
      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);
      expect(find.text('Ekstrak Teks (OCR)'), findsOneWidget);
    });

    testWidgets('Switches to Speech-to-Text tab and shows recording controls',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AiService(storage: const FlutterSecureStorage());

      await tester.pumpWidget(
        MaterialApp(
          home: MultimodalScreen(aiService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Beralih ke Tab 2 (Speech-to-Text)
      await tester.tap(find.text('Speech-to-Text'));
      await tester.pumpAndSettle();

      // Memeriksa komponen tab Speech-to-Text
      expect(find.textContaining('Speech-to-Text mengubah suara pengguna'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsWidgets);
      expect(find.text('Konversi ke Teks AI'), findsOneWidget);
    });

    testWidgets('Switches to Vision tab and shows image understanding controls',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AiService(storage: const FlutterSecureStorage());

      await tester.pumpWidget(
        MaterialApp(
          home: MultimodalScreen(aiService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Beralih ke Tab 3 (Vision / Image Understanding)
      await tester.tap(find.text('Vision'));
      await tester.pumpAndSettle();

      // Memeriksa komponen Image Understanding
      expect(find.textContaining('Image Understanding meminta AI mendeskripsikan produk'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Minta Deskripsi AI'), findsOneWidget);
    });
  });
}

