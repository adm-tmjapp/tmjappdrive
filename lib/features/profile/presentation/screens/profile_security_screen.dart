import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmjappdrive/class/url_launcher.dart';

import '../../../ride_history/application/ride_history_providers.dart';
import '../../domain/profile_models.dart';

class ProfileSecurityScreen extends ConsumerWidget {
  const ProfileSecurityScreen({super.key, required this.security});

  final DriverProfileSecurity security;

  static const Color _bg = Color(0xFF000000);
  static const Color _panel = Color(0xFF0F1D3A);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _primary = Color(0xFFD62D86);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openSupport() async {
      try {
        final contact =
            await ref.read(rideHistoryRepositoryProvider).getSupportContact();
        final target =
            contact.chatUrl?.trim().isNotEmpty == true
                ? contact.chatUrl!
                : contact.whatsApp?.trim().isNotEmpty == true
                ? 'https://wa.me/${contact.whatsApp!.replaceAll(RegExp(r'\D'), '')}'
                : contact.phone?.trim().isNotEmpty == true
                ? 'tel:${contact.phone}'
                : null;
        if (target == null) {
          throw Exception('Canal de suporte indisponível.');
        }
        await UrlLauncher.url(target);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Segurança e Termos',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          const SizedBox(height: 6),
          const _SectionTitle('DOCUMENTOS E REGRAS'),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.description_rounded,
            title: 'Termos de Uso',
            subtitle: security.termsUrl,
            onTap: () => UrlLauncher.url(security.termsUrl),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.privacy_tip_rounded,
            title: 'Política de Privacidade',
            subtitle: security.privacyPolicyUrl,
            onTap: () => UrlLauncher.url(security.privacyPolicyUrl),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.gavel_rounded,
            title: 'Código de Conduta',
            subtitle: security.termsUrl,
            onTap: () => UrlLauncher.url(security.termsUrl),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('SEGURANÇA'),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Dicas de Segurança',
            subtitle: 'Boas práticas para suas corridas',
            onTap: () => UrlLauncher.url(security.privacyPolicyUrl),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Seguro de Acidentes',
            subtitle: 'Cobertura e orientações',
            onTap: () => UrlLauncher.url(security.termsUrl),
          ),
          const SizedBox(height: 26),
          _SupportCard(onTap: openSupport),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ProfileSecurityScreen._panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E3A5F)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white70),
                const SizedBox(width: 10),
                Text(
                  'Versão ${security.appVersion}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: ProfileSecurityScreen._panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E3A5F)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ProfileSecurityScreen._primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ProfileSecurityScreen._primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B0C2F), Color(0xFF1C0A1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF36162D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.headset_mic_rounded, color: Colors.white),
          ),
          const SizedBox(height: 14),
          const Text(
            'Dúvidas ou Suporte?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nossa equipe está disponível 24/7 para te ajudar com o que precisar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ProfileSecurityScreen._muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfileSecurityScreen._primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Falar com a Equipe'),
            ),
          ),
        ],
      ),
    );
  }
}
