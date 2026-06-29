import 'package:flutter/material.dart';

import '../../domain/wallet_models.dart';
import 'wallet_earnings_screen.dart';

class TransferDetailsScreen extends StatelessWidget {
  const TransferDetailsScreen({super.key, required this.transaction});

  static const Color _primary = Color(0xFFC62F78);
  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(transaction.status);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          children: [
            const _TopBar(title: 'Detalhes do Saque'),
            const SizedBox(height: 40),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _primary.withValues(alpha: 0.3),
                  width: 6,
                ),
              ),
              child: Center(
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 52),
                ),
              ),
            ),
            const SizedBox(height: 38),
            Text(
              _currency(transaction.amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Transferência $status',
              style: const TextStyle(
                color: _primary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 42),
            _detail('Data e Hora', _formatDateTime(transaction.createdAt)),
            _detail('Tipo', 'Saque via PIX (CPF)'),
            _detail('Destino', 'Conta Corrente (Sua conta)'),
            _detail('ID da Transação', transaction.id, trailingIcon: true),
            if (transaction.providerTxId != null)
              _detail('ID Provedor', transaction.providerTxId!),
            if (transaction.failureReason != null)
              _detail('Motivo da falha', transaction.failureReason!),
            const SizedBox(height: 26),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF14040D),
                border: Border.all(color: _primary.withValues(alpha: 0.28)),
              ),
              child: TextButton.icon(
                onPressed: transaction.receiptUrl == null ? null : () {},
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: _primary,
                ),
                label: const Text(
                  'Ver Comprovante Completo',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletEarningsScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(62),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Voltar para Carteira'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value, {bool trailingIcon = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _primary.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailingIcon)
                const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFFC62F78),
                  size: 22,
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} - ${two(d.hour)}:${two(d.minute)}';
  }

  static String _currency(double value) {
    final text = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $text';
  }

  static String _statusLabel(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return 'Pendente';
      case TransferStatus.completed:
        return 'Concluída';
      case TransferStatus.failed:
        return 'Falhou';
    }
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
