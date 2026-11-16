import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week7_clean_architecture/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiService Unit Tests', () {
    test('Throws Exception if API key is not set', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AiService(
        storage: const FlutterSecureStorage(),
      );

      expect(
        () async => await service.ask('Halo AI'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API key tidak tersedia. Silakan atur di pengaturan.'),
          ),
        ),
      );
    });

    test('Returns parsed response on successful 200 response', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'test-key-123'});

      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['key'], 'test-key-123');
        expect(request.headers['Content-Type'], 'application/json');

        final payload = jsonDecode(request.body);
        expect(payload['contents'][0]['parts'][0]['text'], 'Halo Gemini');

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Halo! Ada yang bisa saya bantu?'}
                  ]
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(
        storage: const FlutterSecureStorage(),
        client: mockClient,
      );

      final reply = await service.ask('Halo Gemini');
      expect(reply, 'Halo! Ada yang bisa saya bantu?');
    });

    test('Throws Exception on non-200 status code', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'test-key-123'});

      final mockClient = MockClient((request) async {
        return http.Response('Rate limit exceeded', 429);
      });

      final service = AiService(
        storage: const FlutterSecureStorage(),
        client: mockClient,
      );

      expect(
        () async => await service.ask('Pertanyaan'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Gagal memanggil AI API: 429'),
          ),
        ),
      );
    });

    test('Saves, reads, and deletes API key correctly', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AiService(
        storage: const FlutterSecureStorage(),
      );

      expect(await service.getApiKey(), isNull);

      await service.saveApiKey('my-secret-key');
      expect(await service.getApiKey(), 'my-secret-key');

      await service.deleteApiKey();
      expect(await service.getApiKey(), isNull);
    });

    test('recognizeText successfully extracts OCR text from image bytes', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'test-key-ocr'});

      final mockClient = MockClient((request) async {
        final payload = jsonDecode(request.body);
        final parts = payload['contents'][0]['parts'] as List;
        expect(parts[0]['text'], contains('Lakukan OCR'));
        expect(parts[1]['inline_data']['mime_type'], isNotNull);
        expect(parts[1]['inline_data']['data'], isNotNull);

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text':
                          'KARTU TANDA MAHASISWA\nNIM: 244107020212\nNama: Naufal Abid Aurizky'
                    }
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

      final fakeBytes = [0xFF, 0xD8, 0xFF, 0xE0]; // JPEG magic bytes
      final result = await service.recognizeText(fakeBytes);
      expect(result, contains('KARTU TANDA MAHASISWA'));
      expect(result, contains('NIM: 244107020212'));
    });

    test('speechToText successfully transcribes audio bytes', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'test-key-stt'});

      final mockClient = MockClient((request) async {
        final payload = jsonDecode(request.body);
        final parts = payload['contents'][0]['parts'] as List;
        expect(parts[0]['text'], contains('Speech-to-Text'));
        expect(parts[1]['inline_data']['mime_type'], isNotNull);
        expect(parts[1]['inline_data']['data'], isNotNull);

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Halo selamat pagi, ini adalah catatan belanja.'}
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

      final fakeAudioBytes = [0x49, 0x44, 0x33]; // MP3 header
      final result = await service.speechToText(fakeAudioBytes);
      expect(result, 'Halo selamat pagi, ini adalah catatan belanja.');
    });

    test('describeImage successfully returns vision description', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'test-key-vision'});

      final mockClient = MockClient((request) async {
        final payload = jsonDecode(request.body);
        final parts = payload['contents'][0]['parts'] as List;
        expect(parts[0]['text'], contains('Deskripsikan'));

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text':
                          'Gambar menampilkan sebuah cangkir kopi keramik berwarna putih di atas meja kayu.'
                    }
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

      final fakeBytes = [0x89, 0x50, 0x4E, 0x47]; // PNG header
      final result = await service.describeImage(fakeBytes);
      expect(result, contains('sebuah cangkir kopi keramik'));
    });
  });
}
