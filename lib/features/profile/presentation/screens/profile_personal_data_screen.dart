import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../application/profile_providers.dart';
import '../../domain/profile_models.dart';
import 'profile_edit_address_screen.dart';

class ProfilePersonalDataScreen extends ConsumerStatefulWidget {
  const ProfilePersonalDataScreen({super.key, required this.profile});

  final DriverProfile profile;

  @override
  ConsumerState<ProfilePersonalDataScreen> createState() =>
      _ProfilePersonalDataScreenState();
}

class _ProfilePersonalDataScreenState
    extends ConsumerState<ProfilePersonalDataScreen> {
  static const Color _bg = Color(0xFF000000);
  static const Color _card = Color(0xFF0D0A14);
  static const Color _border = Color(0xFF3A102A);
  static const Color _primary = Color(0xFFD62D86);
  static const Color _muted = Color(0xFF94A3B8);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cpfController;

  final _phoneMask = MaskTextInputFormatter(mask: '(##) #####-####');
  final _cpfMask = MaskTextInputFormatter(mask: '###.###.###-##');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _cpfController = TextEditingController(
      text: widget.profile.cpfMasked ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dados Pessoais',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const SizedBox(height: 6),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFED5AA9), Color(0xFFD62D86)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: _card,
                        backgroundImage:
                            (widget.profile.profilePhotoUrl != null &&
                                    widget.profile.profilePhotoUrl!
                                        .trim()
                                        .isNotEmpty)
                                ? NetworkImage(widget.profile.profilePhotoUrl!)
                                : null,
                        child:
                            (widget.profile.profilePhotoUrl == null ||
                                    widget.profile.profilePhotoUrl!
                                        .trim()
                                        .isEmpty)
                                ? const Icon(
                                  Icons.person,
                                  color: Colors.white54,
                                  size: 46,
                                )
                                : null,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Alterar foto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _FieldCard(
                label: 'Nome',
                child: TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Nome completo').copyWith(
                    suffixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator:
                      (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Informe o nome.'
                              : null,
                ),
              ),
              const SizedBox(height: 16),
              _FieldCard(
                label: 'E-mail',
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('email@exemplo.com').copyWith(
                    suffixIcon: const Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o e-mail.';
                    }
                    if (!value.contains('@')) {
                      return 'E-mail invalido.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldCard(
                label: 'Telefone',
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_phoneMask],
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    '(00) 00000-0000',
                  ).copyWith(suffixIcon: const Icon(Icons.phone_outlined)),
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.length < 10) return 'Telefone invalido.';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldCard(
                label: 'CPF',
                child: TextFormField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_cpfMask],
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    '000.000.000-00',
                  ).copyWith(suffixIcon: const Icon(Icons.badge_outlined)),
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.length != 11) return 'CPF invalido.';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldCard(
                label: 'Endereço',
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileEditAddressScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Alterar endereço',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.my_location_outlined,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      state.isUpdating
                          ? null
                          : () async {
                            if (!(_formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            final updated = await controller.updateProfile(
                              DriverProfileUpdateInput(
                                name: _nameController.text.trim(),
                                email: _emailController.text.trim(),
                                phone: _phoneController.text.trim(),
                                cpf: _cpfController.text.replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                ),
                              ),
                            );
                            if (!context.mounted || !updated) return;
                            Navigator.of(context).pop(true);
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  child:
                      state.isUpdating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Salvar Alterações',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: _card,
      suffixIconColor: _muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
