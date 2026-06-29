import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/profile_controller.dart';
import '../../application/profile_providers.dart';
import '../../domain/profile_models.dart';

const Color _field = Color(0xFF071633);
const Color _fieldStroke = Color(0xFF1E3A5F);
const Color _muted = Color(0xFF94A3B8);
const Color _primary = Color(0xFFC62F78);

class ProfileAddVehicleScreen extends ConsumerStatefulWidget {
  const ProfileAddVehicleScreen({super.key});

  @override
  ConsumerState<ProfileAddVehicleScreen> createState() =>
      _ProfileAddVehicleScreenState();
}

class _ProfileAddVehicleScreenState
    extends ConsumerState<ProfileAddVehicleScreen> {
  static const Color _bg = Color(0xFF000000);
  static const List<_VehicleCategoryOption> _categories = [
    _VehicleCategoryOption(label: 'TMJ Comfort', value: 'car'),
    _VehicleCategoryOption(label: 'TMJ Moto', value: 'motorcycle'),
    _VehicleCategoryOption(label: 'TMJ Utilitario', value: 'utility'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedCategoryValue = _categories.first.value;
  File? _vehiclePhoto;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileControllerProvider, (previous, next) {
      if (!mounted) return;
      if (previous?.error != next.error && next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
    });

    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Adicionar Veiculo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1E293B), height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF050915),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _fieldStroke),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(title: 'FOTO DO VEICULO'),
                          const SizedBox(height: 14),
                          _PhotoPickerCard(
                            file: _vehiclePhoto,
                            onTap: _pickVehiclePhoto,
                          ),
                          const SizedBox(height: 26),
                          const _SectionHeader(title: 'INFORMACOES GERAIS'),
                          const SizedBox(height: 22),
                          _LabeledField(
                            label: 'Marca',
                            child: _TextFieldBox(
                              controller: _brandController,
                              hintText: 'Ex: Toyota',
                              validator: _requiredValidator,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _LabeledField(
                            label: 'Modelo',
                            child: _TextFieldBox(
                              controller: _modelController,
                              hintText: 'Ex: Corolla',
                              validator: _requiredValidator,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _LabeledField(
                                  label: 'Ano',
                                  child: _TextFieldBox(
                                    controller: _yearController,
                                    hintText: '2024',
                                    keyboardType: TextInputType.number,
                                    validator: _yearValidator,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _LabeledField(
                                  label: 'Placa',
                                  child: _TextFieldBox(
                                    controller: _plateController,
                                    hintText: 'ABC-1234',
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    validator: _plateValidator,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _LabeledField(
                            label: 'Cor',
                            child: _TextFieldBox(
                              controller: _colorController,
                              hintText: 'Ex: Branco',
                              validator: _requiredValidator,
                              suffixIcon: Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(right: 14),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _LabeledField(
                            label: 'Categoria',
                            child: _CategoryField(
                              value: _selectedCategoryValue,
                              options: _categories,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedCategoryValue = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 26),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF270311),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF5A0D32),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.info_rounded,
                                    color: _primary,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Certifique-se de que os dados conferem com o CRLV do veiculo para evitar problemas na aprovacao.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Color(0xFF1E293B), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed:
                      state.isUpdating ? null : () => _submit(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon:
                      state.isUpdating
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.save_outlined),
                  label: Text(
                    state.isUpdating ? 'Salvando...' : 'Salvar Veiculo',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVehiclePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _vehiclePhoto = File(picked.path));
  }

  Future<void> _submit(ProfileController controller) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await controller.createVehicle(
      DriverProfileCreateVehicleInput(
        manufacturer: _brandController.text.trim(),
        modelName: _modelController.text.trim(),
        year: _yearController.text.trim(),
        vehiclePlate: _plateController.text.trim().toUpperCase(),
        color: _colorController.text.trim(),
        vehicleType: _selectedCategoryValue,
        photoPath: _vehiclePhoto?.path,
      ),
    );

    if (!mounted || !success) return;
    Navigator.of(context).pop(true);
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }

  String? _yearValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    if (value!.trim().length != 4) return 'Ano invalido';
    return null;
  }

  String? _plateValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    final normalized = value!.trim().toUpperCase();
    final oldPattern = RegExp(r'^[A-Z]{3}-?\d{4}$');
    final mercosulPattern = RegExp(r'^[A-Z]{3}\d[A-Z]\d{2}$');
    if (!oldPattern.hasMatch(normalized) &&
        !mercosulPattern.hasMatch(normalized.replaceAll('-', ''))) {
      return 'Placa invalida';
    }
    return null;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _PhotoPickerCard extends StatelessWidget {
  const _PhotoPickerCard({required this.file, required this.onTap});

  final File? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1224),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF334766),
            width: 1.6,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child:
            file == null
                ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: Color(0xFFC62F78),
                      size: 42,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Tirar ou enviar foto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'JPG, PNG ate 5MB',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(file!, fit: BoxFit.cover),
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

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
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _TextFieldBox extends StatelessWidget {
  const _TextFieldBox({
    required this.controller,
    required this.hintText,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: _muted, fontSize: 16),
        filled: true,
        fillColor: const Color(0xFF0C1427),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _fieldStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF233651)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<_VehicleCategoryOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _fieldStroke),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: _field,
        iconEnabledColor: _muted,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        items:
            options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.value,
                    child: Text(option.label),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _VehicleCategoryOption {
  const _VehicleCategoryOption({required this.label, required this.value});

  final String label;
  final String value;
}
