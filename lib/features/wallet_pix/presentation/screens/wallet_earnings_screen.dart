import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/wallet_controller.dart';
import 'pix_transfer_cpf_screen.dart';
import 'transfer_details_screen.dart';

class WalletEarningsScreen extends ConsumerWidget {
  const WalletEarningsScreen({super.key, this.embedded = false, this.onBack});

  static const Color _bg = Color(0xFF000000);
  static const Color _primary = Color(0xFFC62F78);
  final bool embedded;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletControllerProvider);
    final controller = ref.read(walletControllerProvider.notifier);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, embedded ? 12 : 24, 16, 20),
          children: [
            _WalletHeader(embedded: embedded, onBack: onBack),
            const SizedBox(height: 32),
            const Text(
              'Saldo Disponível',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA1A1AA),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currency(state.availableBalance),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PixTransferCpfScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0, // Flat design como no mockup
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Transferir para conta',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ganhos da Semana',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: state.isLoading ? null : controller.load,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Ver detalhes',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF27272A), width: 1),
              ),
              child: Column(
                children: [
                  const _WeekBars(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total acumulado',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _currency(state.totalAccumulated),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Atividade Recente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            else if (state.history.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Sem movimentações recentes.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              )
            else
              ...state.history.map((tx) {
                final isPix = tx.type == 'PIX_TRANSFER_DEBIT';
                final isCredit = tx.type == 'RIDE_CREDIT' || tx.type == 'BONUS';
                final title =
                    isPix
                        ? 'Transferência concluída'
                        : (isCredit
                            ? (tx.type == 'BONUS'
                                ? 'Bônus de indicação'
                                : 'Corrida ${tx.referenceId == null ? '' : '#${tx.referenceId!.substring(0, tx.referenceId!.length.clamp(0, 5))}'}')
                            : 'Lançamento');
                final amountPrefix = isCredit ? '' : '- ';
                final amountColor =
                    isCredit ? Colors.white : const Color(0xFF94A3B8);
                final iconColor =
                    isPix
                        ? const Color(0xFF60A5FA)
                        : (tx.type == 'BONUS'
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFC62F78));
                final icon =
                    isPix
                        ? Icons.account_balance_wallet_outlined
                        : (tx.type == 'BONUS'
                            ? Icons.card_giftcard_outlined
                            : Icons.local_taxi_outlined);

                return _ActivityTile(
                  title: title,
                  subtitle: _relativeDate(tx.createdAt),
                  amountLabel: '$amountPrefix${_currency(tx.amount)}',
                  amountColor: amountColor,
                  icon: icon,
                  iconColor: iconColor,
                  onTap:
                      tx.referenceId == null
                          ? () {}
                          : () async {
                            final details = await controller
                                .fetchTransferDetails(tx.referenceId!);
                            if (!context.mounted || details == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => TransferDetailsScreen(
                                      transaction: details,
                                    ),
                              ),
                            );
                          },
                );
              }),
          ],
        ),
      ),
    );
  }

  static String _relativeDate(DateTime d) {
    final now = DateTime.now();
    final date = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    String two(int v) => v.toString().padLeft(2, '0');
    final time = '${two(d.hour)}:${two(d.minute)}';
    if (date == today) return 'Hoje, $time';
    if (date == yesterday) return 'Ontem, $time';
    return '${two(d.day)} ${_monthAbbr(d.month)}, $time';
  }

  static String _currency(double value) {
    final text = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $text';
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.embedded, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Carteira',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars();

  @override
  Widget build(BuildContext context) {
    const bars = [48.0, 80.0, 96.0, 112.0, 64.0, 32.0, 16.0];
    const labels = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];

    return SizedBox(
      height: 142,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (i) {
          final active = i == 3;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: bars[i],
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color:
                        active
                            ? const Color(0xFFC62F78)
                            : const Color(0xFF27272A),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  labels[i],
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.amountColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String amountLabel;
  final Color amountColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amountLabel,
              style: TextStyle(
                color: amountColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _monthAbbr(int month) {
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  return months[month - 1];
}
