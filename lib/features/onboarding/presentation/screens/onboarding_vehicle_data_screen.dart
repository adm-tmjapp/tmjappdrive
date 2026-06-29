import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/onboarding_providers.dart';
import '../../domain/onboarding_models.dart';
import '../widgets/onboarding_ui.dart';
import 'onboarding_vehicle_photos_screen.dart';

class OnboardingVehicleDataScreen extends ConsumerStatefulWidget {
  const OnboardingVehicleDataScreen({super.key, required this.session});

  final DriverOnboardingSession session;

  @override
  ConsumerState<OnboardingVehicleDataScreen> createState() =>
      _OnboardingVehicleDataScreenState();
}

class _OnboardingVehicleDataScreenState
    extends ConsumerState<OnboardingVehicleDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandModelController =
      TextEditingController(); // Alterado para combinar marca/modelo em um só input como no figma
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();

  // O Figma não mostra os campos de Renavam, Uso e Tipo de veículo,
  // mas para não quebrar a sua lógica (pois eles são enviados na API),
  // irei definir os controllers e usá-los nos bastidores.
  final _renavamController = TextEditingController();
  String _vehicleType = 'Carro';
  String _usage = 'Passageiros';

  @override
  void dispose() {
    _brandModelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _renavamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverOnboardingControllerProvider(widget.session));
    final controller = ref.read(
      driverOnboardingControllerProvider(widget.session).notifier,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Fundo preto do Figma
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        title: Text(
          'Dados do Veículo',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // ===== BARRA DE PROGRESSO E ETAPA =====
                    Text(
                      'Passo 6 de 7',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFA1A1AA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: onboardingPrimary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: onboardingPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ===== TÍTULOS =====
                    Text(
                      'Sobre o seu veículo',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Preencha as informações abaixo para\ncontinuar o seu onboarding.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ===== FORMULÁRIO =====
                    _buildInputBlock(
                      label: 'Marca / Modelo',
                      hint: 'Ex: Volkswagen Gol',
                      controller: _brandModelController,
                      validator: _required,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputBlock(
                            label: 'Placa',
                            hint: 'ABC-1234',
                            controller: _plateController,
                            validator: _required,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputBlock(
                            label: 'Cor',
                            hint: 'Ex: Prata',
                            controller: _colorController,
                            validator: _required,
                          ),
                        ),
                      ],
                    ),
                    _buildInputBlock(
                      label: 'Ano',
                      hint: 'Ex: 2023',
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      validator: _required,
                    ),

                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      OnboardingInlineFeedback(
                        message: state.error!,
                        isError: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ===== BOTÃO INFERIOR =====
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      state.isSubmitting
                          ? null
                          : () async {
                            if (!_formKey.currentState!.validate()) return;

                            // Lógica de separação do campo "Marca / Modelo" para a API
                            final brandModel =
                                _brandModelController.text.trim();
                            final parts = brandModel.split(' ');
                            final brand = parts.isNotEmpty ? parts.first : '';
                            final model =
                                parts.length > 1
                                    ? parts.sublist(1).join(' ')
                                    : '';

                            final ok = await controller.registerVehicle(
                              DriverOnboardingVehicleInput(
                                brand: brand,
                                model: model,
                                year: _yearController.text.trim(),
                                color: _colorController.text.trim(),
                                plate:
                                    _plateController.text.trim().toUpperCase(),
                                vehicleType:
                                    _vehicleType, // Usando a variavel de estado
                                usage: _usage, // Usando a variavel de estado
                                renavam:
                                    _renavamController.text.trim().isEmpty
                                        ? null
                                        : _renavamController.text.trim(),
                              ),
                            );
                            if (!context.mounted) return;
                            if (ok) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder:
                                      (_) => OnboardingVehiclePhotosScreen(
                                        session: widget.session,
                                      ),
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onboardingPrimary,
                    disabledBackgroundColor: onboardingPrimary.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0, // Flat design como no mockup
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Próximo Passo',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget construtor de inputs para manter o padrão visual do Figma
  Widget _buildInputBlock({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
              filled: true,
              fillColor: const Color(
                0xFF0A0207,
              ), // Fundo extremamente escuro e avermelhado
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF2A1521), // Borda fina sutilmente rosada
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: onboardingPrimary,
                  width: 1.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              errorStyle: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }
}
