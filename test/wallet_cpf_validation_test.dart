import 'package:flutter_test/flutter_test.dart';
import 'package:tmjappdrive/features/wallet_pix/application/wallet_controller.dart';

void main() {
  group('CPF para transferência PIX', () {
    test('normaliza CPF digitado com pontuação', () {
      expect(WalletController.normalizeCpf('529.982.247-25'), '52998224725');
    });

    test('aceita CPF válido com ou sem máscara', () {
      expect(WalletController.isValidCpf('529.982.247-25'), isTrue);
      expect(WalletController.isValidCpf('52998224725'), isTrue);
    });

    test('rejeita CPF incompleto, repetido ou com dígitos inválidos', () {
      expect(WalletController.isValidCpf('5299822472'), isFalse);
      expect(WalletController.isValidCpf('11111111111'), isFalse);
      expect(WalletController.isValidCpf('52998224724'), isFalse);
    });
  });
}
