import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmjappdrive/features/dashboard/data/passenger_evaluation_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('guarda e recupera a avaliação feita pelo motorista', () async {
    final store = PassengerEvaluationStore();
    const evaluation = PassengerEvaluation(
      rating: 5,
      comment: 'Passageiro pontual e respeitoso.',
    );

    await store.save('ride-123', evaluation);
    final saved = await store.load('ride-123');

    expect(saved?.rating, 5);
    expect(saved?.comment, 'Passageiro pontual e respeitoso.');
  });

  test(
    'descarta avaliação armazenada com quantidade de estrelas inválida',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'driver_passenger_evaluation_ride-123': '{"rating":6}',
      });

      expect(await PassengerEvaluationStore().load('ride-123'), isNull);
    },
  );
}
