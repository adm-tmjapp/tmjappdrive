import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmjappdrive/api/base_api.dart';
import 'package:tmjappdrive/features/dashboard/data/dashboard_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('envia a avaliação do motorista para o passageiro da corrida', () async {
    late http.Request request;
    final api = BaseApi();
    api.client = MockClient((value) async {
      request = value;
      return http.Response('', 204);
    });

    await DashboardApi(
      baseApi: api,
    ).ratePassenger(rideId: 'ride-123', rating: 5);

    expect(request.method, 'POST');
    expect(request.url.path, '/api/v2/driver/rides/ride-123/rating');
    expect(jsonDecode(request.body), <String, dynamic>{'rating': 5});
  });

  test('não aceita uma avaliação fora do intervalo de estrelas', () async {
    expect(
      DashboardApi().ratePassenger(rideId: 'ride-123', rating: 0),
      throwsA(isA<DashboardApiException>()),
    );
  });
}
