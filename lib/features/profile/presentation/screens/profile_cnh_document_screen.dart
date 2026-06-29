import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/profile_providers.dart';
import '../../domain/profile_models.dart';

class ProfileCnhDocumentScreen extends ConsumerStatefulWidget {
  const ProfileCnhDocumentScreen({super.key});

  @override
  ConsumerState<ProfileCnhDocumentScreen> createState() =>
      _ProfileCnhDocumentScreenState();
}

class _ProfileCnhDocumentScreenState
    extends ConsumerState<ProfileCnhDocumentScreen> {
  static const Color _bg = Color(0xFF000000);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _primary = Color(0xFFD62D86);

  final ImagePicker _picker = ImagePicker();
  File? _front;
  File? _back;
  File? _selfie;
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final docs = state.payload?.documents;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Enviar CNH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(color: Color(0xFF3B0A2B), height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                children: [
                  const Text(
                    'Documentacao CNH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Para sua seguranca e conformidade da TMJ Drive, envie fotos nitidas dos seus documentos originais.',
                    style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  _UploadSection(
                    title: 'Foto da Frente da CNH',
                    subtitle: 'Lado com a sua foto e dados',
                    icon: Icons.info_rounded,
                    file: _front,
                    status: docs?.cnhFront,
                    actionLabel: 'Selecionar Arquivo',
                    onTap:
                        () =>
                            _pickFile((file) => setState(() => _front = file)),
                  ),
                  const SizedBox(height: 18),
                  _UploadSection(
                    title: 'Foto do Verso da CNH',
                    subtitle: 'Lado com o QR Code e observacoes',
                    icon: Icons.info_rounded,
                    file: _back,
                    status: docs?.cnhBack,
                    actionLabel: 'Selecionar Arquivo',
                    onTap:
                        () => _pickFile((file) => setState(() => _back = file)),
                  ),
                  const SizedBox(height: 18),
                  _UploadSection(
                    title: 'Selfie com Documento',
                    subtitle: 'Prova de vida segurando sua CNH',
                    icon: Icons.face_retouching_natural_rounded,
                    file: _selfie,
                    status: docs?.selfie,
                    actionLabel: 'Abrir Camera',
                    selfDescription:
                        'Tire uma foto do seu rosto segurando o documento',
                    onTap: () => _pickSelfie(),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1628),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E3A5F)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF60A5FA),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Seus dados sao criptografados e processados de forma segura seguindo as normas da LGPD.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _sending || state.isUpdating ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child:
                          _sending || state.isUpdating
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                              : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Finalizar Envio'),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward_rounded),
                                ],
                              ),
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

  Future<void> _pickFile(ValueChanged<File> onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    if (!_validateFile(file)) return;
    onPicked(file);
  }

  Future<void> _pickSelfie() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    final file = File(image.path);
    if (!_validateFile(file)) return;
    setState(() => _selfie = file);
  }

  bool _validateFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'pdf'].contains(extension)) {
      _showAlert('Formato invalido. Use JPG, PNG ou PDF.');
      return false;
    }
    if (file.lengthSync() > 10 * 1024 * 1024) {
      _showAlert('Cada arquivo deve ter no maximo 10MB.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_front == null || _back == null || _selfie == null) {
      _showAlert('Envie frente, verso e selfie antes de finalizar.');
      return;
    }

    setState(() => _sending = true);
    final success = await ref
        .read(profileControllerProvider.notifier)
        .uploadCnhDocuments(
          cnhFront: _front!,
          cnhBack: _back!,
          selfie: _selfie!,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    final error = ref.read(profileControllerProvider).error;
    _showAlert(error ?? 'Falha ao enviar CNH.');
  }

  void _showAlert(String message) {
    showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: const Text('Aviso', style: TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
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

class _UploadSection extends StatelessWidget {
  const _UploadSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
    this.file,
    this.status,
    this.selfDescription,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;
  final File? file;
  final DriverProfileDocumentItem? status;
  final String? selfDescription;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(status?.status ?? '');
    final statusColor = _statusColor(status?.status ?? '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x33C62F78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC62F78)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFC62F78),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: const Color(0xFFD62D86), size: 18),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0x33C62F78),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC62F78), width: 1.6),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selfDescription == null
                            ? Icons.add_a_photo_outlined
                            : Icons.add_photo_alternate_outlined,
                        color: const Color(0xFFC62F78),
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        file == null
                            ? (selfDescription ?? 'Toque para enviar')
                            : file!.path.split('/').last,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFC62F78),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0x33C62F78),
                foregroundColor: const Color(0xFFC62F78),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFC62F78)),
                ),
              ),
              icon: Icon(
                selfDescription == null
                    ? Icons.upload_outlined
                    : Icons.photo_camera_outlined,
              ),
              label: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (status != null && statusLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Status: $statusLabel',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'APPROVED':
        return 'Aprovado';
      case 'SENT':
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        return 'Enviado';
      case 'REJECTED':
        return 'Rejeitado';
      case 'PENDING':
        return 'Pendente';
      default:
        return raw.trim().isEmpty ? '' : raw;
    }
  }

  static Color _statusColor(String raw) {
    switch (raw.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF22C55E);
      case 'SENT':
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        return const Color(0xFF3B82F6);
      case 'REJECTED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFFF8A1F);
    }
  }
}
