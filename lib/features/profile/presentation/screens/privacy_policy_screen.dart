import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Política de Privacidade',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Política de Privacidade do TMJ Drive',
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
          ..._sections.map(
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
                    style: const TextStyle(color: _muted, height: 1.55),
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

const _sections = [
  (
    '1. Dados coletados',
    'Coletamos dados necessários para criar sua conta, validar sua identidade, analisar documentos, oferecer suporte e operar as corridas, como nome, contato, documentos, localização e informações do veículo.',
  ),
  (
    '2. Uso das informações',
    'Usamos as informações para autenticação, segurança, prevenção de fraude, processamento das corridas, comunicação e cumprimento de obrigações legais.',
  ),
  (
    '3. Compartilhamento',
    'Os dados podem ser compartilhados com prestadores envolvidos na operação da plataforma, autoridades quando exigido por lei e fornecedores de infraestrutura necessários ao funcionamento do aplicativo.',
  ),
  (
    '4. Segurança e retenção',
    'Aplicamos medidas técnicas e administrativas para proteger os dados. As informações são mantidas pelo período necessário à prestação do serviço e ao cumprimento das obrigações legais.',
  ),
  (
    '5. Seus direitos',
    'Você pode solicitar informações, correção ou esclarecimentos sobre o tratamento dos seus dados pelos canais de suporte disponíveis no aplicativo.',
  ),
  (
    '6. Contato',
    'Para dúvidas sobre privacidade, utilize o canal de suporte do TMJ Drive.',
  ),
];
