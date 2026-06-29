import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/onboarding_providers.dart';
import '../../domain/onboarding_models.dart';
import '../widgets/onboarding_ui.dart';

class OnboardingPendingReviewScreen extends ConsumerWidget {
  const OnboardingPendingReviewScreen({super.key, required this.session});

  final DriverOnboardingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      driverOnboardingControllerProvider(session).notifier,
    );
    final state = ref.watch(driverOnboardingControllerProvider(session));

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Fundo preto do Figma
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => backToLogin(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        title: Text(
          'Cadastro em Análise',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: onboardingPrimary,
          backgroundColor: const Color(0xFF1F1319),
          onRefresh: controller.load, // Lógica mantida via Pull-to-refresh
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              // Ícone superior
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: onboardingPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.pending_actions_rounded,
                    size: 44,
                    color: onboardingPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Títulos
              Text(
                'Estamos revisando seus\ndocumentos',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Em breve você poderá começar\na dirigir com o TMJApp.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),

              // Card "Prazo estimado"
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1319), // Cor exata do Figma
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: onboardingPrimary,
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Prazo estimado',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Até 24 horas úteis.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: onboardingPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Sessão "ENQUANTO ISSO..."
              Text(
                'ENQUANTO ISSO...',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Lista de Ações
              _ActionTile(
                icon: Icons.security_outlined,
                title: 'Dicas de segurança',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.cleaning_services_outlined,
                title: 'Kit de higiene',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.play_circle_outline,
                title: 'Vídeo de treinamento',
                onTap: () {},
              ),
              const SizedBox(height: 32),

              // Exibição de Erro da lógica original preservada
              if (state.error != null) ...[
                OnboardingInlineFeedback(message: state.error!, isError: true),
                const SizedBox(height: 24),
              ],

              // Botão de Suporte (Substitui os antigos seguindo o design visual)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Adicione aqui a função para abrir o chat/WhatsApp do suporte
                  },
                  icon: const Icon(
                    Icons.support_agent_outlined,
                    color: onboardingPrimary,
                    size: 22,
                  ),
                  label: Text(
                    'Falar com Suporte',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: onboardingPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: onboardingPrimary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET REUTILIZÁVEL PARA OS ITENS DA LISTA
// ==========================================
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF101217),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27272A), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: onboardingPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: onboardingPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
