import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../class/url_launcher.dart';
import '../../application/ride_history_providers.dart';
import '../../domain/ride_history_models.dart';
import 'ride_history_support_forms.dart';

class RideHistoryHelpScreen extends ConsumerStatefulWidget {
  const RideHistoryHelpScreen({super.key, required this.rideId});

  final String rideId;

  static const Color _bg = Color(0xFF000000);
  static const Color _card = Color(
    0xFF070E1A,
  ); // Ajustado para tom mais fiel ao print
  static const Color _stroke = Color(
    0xFF1D3557,
  ); // Mantido o stroke original azul escuro
  static const Color _primary = Color(0xFFC62F78);

  @override
  ConsumerState<RideHistoryHelpScreen> createState() =>
      _RideHistoryHelpScreenState();
}

class _RideHistoryHelpScreenState extends ConsumerState<RideHistoryHelpScreen> {
  bool _isOpeningContact = false;

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(rideSupportOptionsProvider(widget.rideId));

    return Scaffold(
      backgroundColor: RideHistoryHelpScreen._bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            32,
          ), // Espaçamento inferior 32px (Figma)
          children: [
            _Header(rideId: widget.rideId),
            const SizedBox(height: 24),
            const Text(
              'Em que podemos ajudar?',
              style: TextStyle(
                color: Color.fromRGBO(255, 255, 255, 1),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione o problema relacionado à sua última corrida.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16, // Ajustado para melhor proporção
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            optionsAsync.when(
              loading:
                  () => const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (error, _) => _InlineMessage(
                    message: error.toString(),
                    accent: Colors.redAccent,
                  ),
              data: (options) {
                if (options.isEmpty) {
                  return const _InlineMessage(
                    message:
                        'Nenhuma opção de suporte disponível para esta corrida.',
                  );
                }
                return Column(
                  children:
                      options
                          .where((option) => option.enabled)
                          .map(
                            (option) => _HelpOption(
                              icon: _iconFor(option.code),
                              title: option.label,
                              onTap: () => _openIssueForm(option),
                            ),
                          )
                          .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0410), // Fundo avermelhado bem escuro
                borderRadius: BorderRadius.circular(16), // Border 16px (Figma)
                border: Border.all(color: const Color(0xFF3B0B23)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ainda precisa de ajuda?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nossa equipe de suporte está disponível 24h para ajudar você com qualquer imprevisto.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52, // Altura um pouco mais enxuta
                    child: ElevatedButton.icon(
                      onPressed: _isOpeningContact ? null : _openSupportContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RideHistoryHelpScreen._primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon:
                          _isOpeningContact
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(
                                Icons.support_agent_rounded,
                                size: 20,
                              ),
                      label: const Text(
                        'Falar com Suporte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Center(
              child: Text(
                'DICAS DE SEGURANÇA',
                style: TextStyle(
                  color: Color(0xFF475569), // Mais sutil
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 32,
              runSpacing: 20,
              children: [
                _SafetyTip(icon: Icons.shield_outlined, label: 'Seguro APP'),
                _SafetyTip(
                  icon: Icons.phone_in_talk_outlined,
                  label: 'Emergência',
                ),
                _SafetyTip(icon: Icons.gps_fixed, label: 'Compartilhar'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSupportContact() async {
    setState(() => _isOpeningContact = true);
    try {
      final repository = ref.read(rideHistoryRepositoryProvider);
      final contact = await repository.getSupportContact();
      final target =
          (contact.chatUrl != null && contact.chatUrl!.trim().isNotEmpty)
              ? contact.chatUrl!
              : (contact.whatsApp != null &&
                  contact.whatsApp!.trim().isNotEmpty)
              ? 'https://wa.me/${contact.whatsApp!.replaceAll(RegExp(r'\D'), '')}'
              : (contact.phone != null && contact.phone!.trim().isNotEmpty)
              ? 'tel:${contact.phone}'
              : null;

      if (target == null) {
        throw 'Canal de suporte indisponível.';
      }

      await UrlLauncher.url(target);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isOpeningContact = false);
    }
  }

  Future<void> _openIssueForm(RideSupportOption option) async {
    Widget screen;
    switch (option.code) {
      case RideSupportIssueCode.forgottenObject:
        screen = RideHistoryForgottenObjectScreen(rideId: widget.rideId);
        break;
      case RideSupportIssueCode.paymentIssue:
        screen = RideHistoryValueIssueScreen(
          rideId: widget.rideId,
          title: option.label,
        );
        break;
      case RideSupportIssueCode.securityIncident:
        screen = RideHistoryOtherIssueScreen(
          rideId: widget.rideId,
          issueCode: option.code,
          title: option.label,
          defaultSubject: option.label,
        );
        break;
      case RideSupportIssueCode.passengerAbsent:
        screen = RideHistoryPassengerAbsentScreen(rideId: widget.rideId);
        break;
      case RideSupportIssueCode.other:
        screen = RideHistoryOtherIssueScreen(
          rideId: widget.rideId,
          issueCode: option.code,
          title: option.label,
        );
        break;
    }

    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  IconData _iconFor(RideSupportIssueCode code) {
    switch (code) {
      case RideSupportIssueCode.forgottenObject:
        return Icons.inventory_2_outlined;
      case RideSupportIssueCode.paymentIssue:
        return Icons.payments_outlined;
      case RideSupportIssueCode.securityIncident:
        return Icons.health_and_safety_outlined; // Melhor adequação visual
      case RideSupportIssueCode.passengerAbsent:
        return Icons.person_off_outlined;
      case RideSupportIssueCode.other:
        return Icons.more_horiz;
    }
  }

  void _showMessage(String message) {
    showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF14040D),
            title: const Text('Aviso', style: TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Color(0xFFD1D5DB)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajuda',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Viagem #$rideId',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HelpOption extends StatelessWidget {
  const _HelpOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16), // Border 16px (Figma)
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16), // Padding 16px (Figma)
            decoration: BoxDecoration(
              color: RideHistoryHelpScreen._card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RideHistoryHelpScreen._stroke),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, // Diminuído para melhorar a proporção interna
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A0B24), // Fundo rosado escuro
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: RideHistoryHelpScreen._primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF64748B),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.message,
    this.accent = const Color(0xFF94A3B8),
  });

  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, style: TextStyle(color: accent, fontSize: 14)),
    );
  }
}

class _SafetyTip extends StatelessWidget {
  const _SafetyTip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56, // Ajuste sutil de proporção
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFF141E30), // Mais sutil para focar no ícone
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: RideHistoryHelpScreen._primary, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
