import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/wallet_controller.dart';
import 'wallet_earnings_screen.dart';

class TransferSuccessScreen extends ConsumerWidget {
  const TransferSuccessScreen({super.key});

  static const Color _primary = Color(0xFFC62F78);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(walletControllerProvider).lastTransfer;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          children: [
            const _TopBar(title: 'Sucesso'),
            const SizedBox(height: 52),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.black, size: 42),
                ),
              ),
            ),
            const SizedBox(height: 42),
            const Text(
              'Transferência\nRealizada!',
              style: TextStyle(
                fontSize: 34,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              tx == null
                  ? 'Sua transferencia foi enviada com sucesso.'
                  : 'O valor de ${_currency(tx.amount)} foi enviado com sucesso para sua conta via PIX.',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 54),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF14040D),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DETALHES DA TRANSAÇÃO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA1A1AA),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _kv('Data e Hora', _formatNow()),
                  const Divider(color: Color(0xFF3A0F2B), height: 28),
                  _kv('ID da Transacao', tx?.id ?? '-'),
                  const Divider(color: Color(0xFF3A0F2B), height: 28),
                  _kv(
                    'Comprovante',
                    tx?.receiptUrl == null
                        ? 'Não disponível'
                        : 'PIX_Comp_45020.pdf',
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletEarningsScreen(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(62),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                label: const Text('Voltar para a Carteira'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: k == 'Comprovante' ? _primary : Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatNow() {
    final d = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} - ${two(d.hour)}:${two(d.minute)}';
  }

  static String _currency(double value) {
    final text = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $text';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 34),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}
