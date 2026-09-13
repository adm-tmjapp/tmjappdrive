import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/profile_providers.dart';
import '../../domain/profile_models.dart';
import 'profile_cnh_document_screen.dart';

class ProfileDocumentsScreen extends ConsumerStatefulWidget {
  const ProfileDocumentsScreen({super.key});

  @override
  ConsumerState<ProfileDocumentsScreen> createState() =>
      _ProfileDocumentsScreenState();
}

class _ProfileDocumentsScreenState
    extends ConsumerState<ProfileDocumentsScreen> {
  static const Color _bg = Color(0xFF050B16);
  static const Color _panel = Color(0xFF0A1328);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _primary = Color(0xFFD62D86);
  static const List<_DocumentOption> _options = [
    _DocumentOption(
      label: 'Comprovante de Residência',
      uploadType: 'comprovante_residencia',
    ),
    _DocumentOption(
      label: 'Antecedentes Criminais',
      uploadType: 'antecedentes_criminais',
    ),
  ];

  final ImagePicker _imagePicker = ImagePicker();

  String _selectedLabel = _options.first.label;
  File? _selectedFile;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final payload = state.payload;
    final docs = payload?.documents;

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
                      'Documentos',
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
            const Divider(color: Color(0xFF1E293B), height: 1),
            Expanded(
              child:
                  payload == null
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            state.error ?? 'Falha ao carregar documentos.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                      : ListView(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
                        children: [
                          const Text(
                            'Envio de Documentos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gerencie seus documentos para aprovação do perfil.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 16,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 34),
                          const _SectionTitle('STATUS DOS DOCUMENTOS'),
                          const SizedBox(height: 18),
                          _StatusCard(
                            title: 'CNH',
                            subtitle: _buildCnhStatusText(docs!),
                            meta: _statusMeta(_buildCnhStatus(docs)),
                            icon: Icons.badge_outlined,
                            iconBackground: const Color(0xFF29130C),
                            iconColor: const Color(0xFFFF8A1F),
                            onTap: () async {
                              final updated = await Navigator.of(
                                context,
                              ).push<bool>(
                                MaterialPageRoute(
                                  builder:
                                      (_) => const ProfileCnhDocumentScreen(),
                                ),
                              );
                              if (updated == true && mounted) {
                                await ref
                                    .read(profileControllerProvider.notifier)
                                    .load();
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          _StatusCard(
                            title: 'Comprovante de Residência',
                            subtitle: _displayLabel(docs.residenceProof.status),
                            meta: _statusMeta(docs.residenceProof.status),
                            icon: Icons.place_outlined,
                            iconBackground: const Color(0xFF081B4B),
                            iconColor: const Color(0xFF4A90FF),
                          ),
                          const SizedBox(height: 14),
                          _StatusCard(
                            title: 'Antecedentes Criminais',
                            subtitle: _displayLabel(docs.criminalRecord.status),
                            meta: _statusMeta(docs.criminalRecord.status),
                            icon: Icons.gavel_rounded,
                            iconBackground: const Color(0xFF052219),
                            iconColor: const Color(0xFF22C55E),
                          ),
                          const SizedBox(height: 36),
                          const _SectionTitle('NOVO ENVIO'),
                          const SizedBox(height: 20),
                          const Text(
                            'Selecione o tipo de documento',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _DropdownField(
                            value: _selectedLabel,
                            items: _options.map((e) => e.label).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedLabel = value;
                                _selectedFile = null;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          GestureDetector(
                            onTap: _pickFromFiles,
                            child: CustomPaint(
                              painter: _DashedBorderPainter(
                                color: const Color(0xFF334155),
                                radius: 22,
                                strokeWidth: 1.6,
                                dash: 8,
                                gap: 6,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 26,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: _panel,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 22,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF32102A),
                                            Color(0xFF1C0A1D),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.file_upload_outlined,
                                        color: _primary,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      _selectedFile == null
                                          ? 'Toque para fazer upload'
                                          : _selectedFile!.path
                                              .split(Platform.pathSeparator)
                                              .last,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'PDF, JPG ou PNG (ate 5MB)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.photo_camera_outlined,
                                  label: 'Câmera',
                                  onTap: _pickFromCamera,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.folder_outlined,
                                  label: 'Arquivos',
                                  onTap: _pickFromFiles,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              onPressed:
                                  _submitting || state.isUpdating
                                      ? null
                                      : () => _submit(payload.profile.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 6,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child:
                                  _submitting || state.isUpdating
                                      ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text(
                                        'Enviar para Análise',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Ao clicar em enviar, você confirma que os documentos são veridicos e aceita nossos termos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 10,
                              height: 1.5,
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

  Future<void> _pickFromCamera() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    final file = File(image.path);
    if (!_validateFile(file, maxMb: 5)) return;
    setState(() => _selectedFile = file);
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    if (!_validateFile(file, maxMb: 5)) return;
    setState(() => _selectedFile = file);
  }

  bool _validateFile(File file, {required int maxMb}) {
    final allowed = ['pdf', 'jpg', 'jpeg', 'png'];
    final extension = file.path.split('.').last.toLowerCase();
    if (!allowed.contains(extension)) {
      _showAlert('Formato invalido. Use PDF, JPG ou PNG.');
      return false;
    }
    final bytes = file.lengthSync();
    if (bytes > maxMb * 1024 * 1024) {
      _showAlert('O arquivo deve ter no maximo ${maxMb}MB.');
      return false;
    }
    return true;
  }

  Future<void> _submit(String userId) async {
    if (_selectedFile == null) {
      _showAlert('Selecione um arquivo antes de enviar.');
      return;
    }

    final option = _options.firstWhere(
      (element) => element.label == _selectedLabel,
    );
    setState(() => _submitting = true);
    final success = await ref
        .read(profileControllerProvider.notifier)
        .uploadProfileDocument(
          userId: userId,
          type: option.uploadType,
          filePath: _selectedFile!.path,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      setState(() => _selectedFile = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento enviado para analise.')),
      );
    } else {
      final error = ref.read(profileControllerProvider).error;
      _showAlert(error ?? 'Falha ao enviar documento.');
    }
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

  String _buildCnhStatus(DriverProfileDocuments documents) {
    final statuses =
        [
          documents.cnhFront.status,
          documents.cnhBack.status,
          documents.selfie.status,
        ].map((e) => e.toUpperCase()).toList();

    if (statuses.any((e) => e == 'REJECTED')) return 'REJECTED';
    if (statuses.every((e) => e == 'APPROVED')) return 'APPROVED';
    if (statuses.any(
      (e) => e == 'SENT' || e == 'SUBMITTED' || e == 'UNDER_REVIEW',
    )) {
      return 'SENT';
    }
    if (statuses.any((e) => e == 'PENDING')) return 'PENDING';
    return statuses.any((e) => e.isNotEmpty) ? statuses.first : 'PENDING';
  }

  String _buildCnhStatusText(DriverProfileDocuments documents) {
    return _displayLabel(_buildCnhStatus(documents));
  }

  String _displayLabel(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'Aprovado';
      case 'SENT':
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        return 'Enviado';
      case 'REJECTED':
        return 'Rejeitado';
      default:
        return 'Pendente';
    }
  }

  _StatusMeta _statusMeta(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const _StatusMeta(
          label: 'Aprovado',
          color: Color(0xFF22C55E),
          icon: Icons.verified_rounded,
        );
      case 'SENT':
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        return const _StatusMeta(
          label: 'Enviado',
          color: Color(0xFF3B82F6),
          icon: Icons.cloud_upload_outlined,
        );
      case 'REJECTED':
        return const _StatusMeta(
          label: 'Rejeitado',
          color: Color(0xFFEF4444),
          icon: Icons.cancel_outlined,
        );
      default:
        return const _StatusMeta(
          label: 'Pendente',
          color: Color(0xFFFF8A1F),
          icon: Icons.schedule_rounded,
        );
    }
  }
}

class _DocumentOption {
  const _DocumentOption({required this.label, required this.uploadType});

  final String label;
  final String uploadType;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final _StatusMeta meta;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B1C36), Color(0xFF091327)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF1E3A5F)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(meta.icon, color: meta.color, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: meta.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1D3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2F4E)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF0C1D3E),
          borderRadius: BorderRadius.circular(16),
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items:
              items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFF0C1D3E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1F2F4E)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _ProfileDocumentsScreenState._primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
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
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    this.dash = 8,
    this.gap = 6,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap;
  }
}
