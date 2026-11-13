import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmjappdrive/api/base_api.dart';
import 'package:tmjappdrive/features/chat/data/ride_chat_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test(
    'envia conteúdo do chat como JSON para o endpoint do motorista',
    () async {
      late http.Request request;
      final baseApi = BaseApi();
      baseApi.client = MockClient((value) async {
        request = value;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'message': <String, dynamic>{
              'id': 'message-1',
              'content': 'Olá, estou chegando.',
              'senderRole': 'driver',
            },
          }),
          201,
        );
      });

      final message = await RideChatApi(
        api: baseApi,
      ).send('ride-123', '  Olá, estou chegando.  ');

      expect(request.method, 'POST');
      expect(request.url.path, '/api/v2/driver/rides/ride-123/messages');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), <String, dynamic>{
        'content': 'Olá, estou chegando.',
      });
      expect(message.content, 'Olá, estou chegando.');
      expect(message.isMine, isTrue);
    },
  );

  test('não envia conteúdo em branco', () async {
    expect(RideChatApi().send('ride-123', '   '), throwsA(isA<Exception>()));
  });
}
