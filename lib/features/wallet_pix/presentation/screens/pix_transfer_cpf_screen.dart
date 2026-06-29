import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/wallet_controller.dart';
import '../../../../utils/strings.dart';
import 'transfer_success_screen.dart';

class PixTransferCpfScreen extends ConsumerStatefulWidget {
  const PixTransferCpfScreen({super.key});

  @override
  ConsumerState<PixTransferCpfScreen> createState() =>
      _PixTransferCpfScreenState();
}

class _PixTransferCpfScreenState extends ConsumerState<PixTransferCpfScreen> {
  final _cpfCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _cpfMaskedHint;
  String? _walletMaskedHint;

  @override
  void initState() {
    super.initState();
    _loadSavedWalletHints();
  }

  Future<void> _loadSavedWalletHints() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _cpfMaskedHint = prefs.getString(Strings.prefDriverCpfMasked);
      _walletMaskedHint = prefs.getString(
        Strings.prefDriverWalletAvailableMasked,
      );
    });
  }

  @override
  void dispose() {
    _cpfCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool _hasRegisteredCpf() {
    final maskedCpf = _cpfMaskedHint?.trim() ?? '';
    if (maskedCpf.isEmpty) return false;
    return maskedCpf != '000.000.000-00';
  }

  Future<void> _showMissingCpfAlert() {
    return showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(
              0xFF18181B,
            ), // Fundo escuro mais neutro
            title: const Text(
              'CPF nao cadastrado',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Para transferir saldo, complemente o seu perfil adicionando o CPF.',
              style: TextStyle(color: Color(0xFFA1A1AA)),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFFC62F78),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletControllerProvider);
    final controller = ref.read(walletControllerProvider.notifier);
    final amount = double.tryParse(state.amountDraft.replaceAll(',', '.')) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: const _TopBar(title: 'Transferir Saldo'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                children: [
                  const Text(
                    'Saldo disponível',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _walletMaskedHint != null &&
                            _walletMaskedHint!.trim().isNotEmpty
                        ? _walletMaskedHint!
                        : _currency(state.availableBalance),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Quanto deseja transferir?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF11070C,
                      ), // Fundo levemente avermelhado
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2A1521),
                        width: 1.5,
                      ), // Borda de acordo com o design
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'R\$',
                          style: TextStyle(
                            color: Color(0xFFC62F78),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: controller.setAmountDraft,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11070C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2A1521),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DESTINATÁRIO (PIX)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC62F78),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2A1521,
                                ), // Fundo da caixa do ícone
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payments_outlined,
                                color: Color(0xFFC62F78),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PIX via CPF',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Chave PIX: CPF do titular',
                                    style: TextStyle(
                                      color: Color(0xFFA1A1AA),
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextField(
                                    controller: _cpfCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: controller.setCpfDraft,
                                    style: const TextStyle(
                                      color: Color(0xFFA1A1AA),
                                      fontSize: 13,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.only(
                                        top: 2,
                                      ),
                                      hintText:
                                          state.cpfDraft.isEmpty
                                              ? 'CPF: ${_cpfMaskedHint ?? '000.000.000-00'}'
                                              : null,
                                      hintStyle: const TextStyle(
                                        color: Color(0xFFA1A1AA),
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _Line(
                    label: 'Subtotal',
                    value: _currency(amount),
                    dark: true,
                  ),
                  const SizedBox(height: 12),
                  const _Line(
                    label: 'Taxa de transferência',
                    value: '- R\$ 0,00',
                    dark: true,
                    accentValue: true,
                  ),
                  const SizedBox(height: 24),
                  _Line(
                    label: 'Total a receber',
                    value: _currency(amount),
                    emphasize: true,
                    dark: true,
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          state.isSubmitting
                              ? null
                              : () async {
                                if (!_hasRegisteredCpf()) {
                                  await _showMissingCpfAlert();
                                  return;
                                }
                                final ok = await controller.submitTransfer();
                                if (!context.mounted || !ok) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const TransferSuccessScreen(),
                                  ),
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62F78),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          state.isSubmitting
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Confirmar Transferência',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'O saldo será creditado instantaneamente em sua conta via PIX (24h).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF52525B), // Cinza mais escuro do mockup
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.dark = false,
    this.accentValue = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool dark;
  final bool accentValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasize ? Colors.white : const Color(0xFFA1A1AA),
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            fontSize: emphasize ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:
                emphasize || accentValue
                    ? const Color(0xFFC62F78)
                    : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: emphasize ? 18 : 14,
          ),
        ),
      ],
    );
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
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
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
        const SizedBox(width: 40), // Para balancear o IconButton na esquerda
      ],
    );
  }
}

String _currency(double value) {
  final text = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $text';
}
