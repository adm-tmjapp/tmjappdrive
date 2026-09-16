import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  static const Color _background = Color(0xFF000000);
  static const Color _muted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Termos de uso',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Termos de uso do TMJ Drive',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Última atualização: setembro de 2026',
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 24),
          ..._termsSections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section.$2,
                    style: const TextStyle(height: 1.55, color: _muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _termsSections = [
  (
    '1. Uso do serviço',
    'O TMJ Drive conecta motoristas parceiros a solicitações de transporte. Ao usar o aplicativo, você concorda em fornecer informações verdadeiras, manter seus documentos atualizados e proteger sua conta.',
  ),
  (
    '2. Conta e segurança',
    'Você é responsável pelas atividades realizadas na sua conta e deve comunicar qualquer uso não autorizado. O acesso pode ser suspenso em caso de fraude, abuso ou violação destes termos.',
  ),
  (
    '3. Corridas e pagamentos',
    'Valores, repasses, taxas e condições das corridas são apresentados no aplicativo. Ajustes e cancelamentos podem ser aplicados conforme as condições informadas antes da aceitação da corrida.',
  ),
  (
    '4. Conduta do motorista',
    'Você deve cumprir a legislação de trânsito, manter veículo e documentação regulares e tratar passageiros com respeito. Não é permitido usar o serviço para fins ilegais, causar risco a terceiros ou comprometer a plataforma.',
  ),
  (
    '5. Disponibilidade',
    'O serviço pode sofrer interrupções por manutenção, conectividade, segurança ou eventos fora do controle razoável da plataforma.',
  ),
  (
    '6. Contato',
    'Dúvidas sobre estes termos podem ser encaminhadas pelo canal de suporte disponível no Perfil.',
  ),
];
