import 'package:flutter_test/flutter_test.dart';
import 'package:tmjappdrive/features/dashboard/data/passenger_photo_url.dart';

void main() {
  test('lê profilePhotoUrl do contrato do aplicativo do passageiro', () {
    expect(
      resolvePassengerPhotoUrl(<String, dynamic>{
        'profilePhotoUrl': 'https://cdn.tmjapp.com/passengers/ana.jpg',
      }),
      'https://cdn.tmjapp.com/passengers/ana.jpg',
    );
  });

  test('lê foto do perfil aninhado e resolve caminho relativo', () {
    expect(
      resolvePassengerPhotoUrl(<String, dynamic>{
        'profile': <String, dynamic>{
          'profile_photo_url': 'uploads/passengers/ana.jpg',
        },
      }),
      'https://api.tmjapp.com.br/uploads/passengers/ana.jpg',
    );
  });

  test('aceita foto no payload de corrida em tempo real', () {
    expect(
      resolvePassengerPhotoUrl(
        null,
        ride: <String, dynamic>{'passengerPhotoUrl': '/media/ana.jpg'},
      ),
      'https://api.tmjapp.com.br/media/ana.jpg',
    );
  });

  test('lê objeto de imagem do passageiro aceito', () {
    expect(
      resolvePassengerPhotoUrl(<String, dynamic>{
        'user': <String, dynamic>{
          'avatar': <String, dynamic>{'secureUrl': '/files/passenger.jpg'},
        },
      }),
      'https://api.tmjapp.com.br/files/passenger.jpg',
    );
  });

  test('lê identidade no usuário aninhado do rider', () {
    final rider = <String, dynamic>{
      'user': <String, dynamic>{
        'first_name': 'Ana',
        'last_name': 'Souza',
        'profile_photo_url': '/files/ana.jpg',
      },
    };
    expect(resolvePassengerName(rider), 'Ana Souza');
    expect(
      resolvePassengerPhotoUrl(rider),
      'https://api.tmjapp.com.br/files/ana.jpg',
    );
  });
}
