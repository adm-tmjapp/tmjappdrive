import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_controller.dart';
import '../../application/profile_providers.dart';
import '../../domain/profile_models.dart';

class ProfileVehicleDocumentScreen extends ConsumerStatefulWidget {
  const ProfileVehicleDocumentScreen({super.key, required this.vehicle});

  final DriverProfileVehicle vehicle;

  @override
  ConsumerState<ProfileVehicleDocumentScreen> createState() =>
      _ProfileVehicleDocumentScreenState();
}

class _ProfileVehicleDocumentScreenState
    extends ConsumerState<ProfileVehicleDocumentScreen> {
  static const Color _bg = Color(0xFF000000);
  static const Color _primary = Color(0xFFD62D86);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _panel = Color(0xFF0F1D3A);
  static const Color _card = Color(0xFF17020B);
  static const Color _border = Color(0xFF7A214F);

  File? _selectedFile;
  String? _selectedFileName;
  List<DriverVehicleDocumentItem> _documents = const [];
  bool _loadingDocuments = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final docs = await ref
          .read(profileControllerProvider.notifier)
          .getVehicleDocuments(widget.vehicle.id);
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _loadingDocuments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDocuments = false);
    }
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
    final currentDocument =
        _documents.where((doc) => doc.type == 'CRLV').isNotEmpty
            ? _documents.firstWhere((doc) => doc.type == 'CRLV')
            : (_documents.isNotEmpty ? _documents.first : null);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                      'Documento do Veiculo',
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
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF1E293B), height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                children: [
                  const Text(
                    'Envie o seu CRLV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Certifique-se de que todas as informacoes estejam legiveis no documento original.',
                    style: TextStyle(color: _muted, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 26),
                  _DocumentPickerCard(
                    fileName: _selectedFileName,
                    onTap: _pickFile,
                  ),
                  if (_loadingDocuments) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(minHeight: 2),
                  ] else if (currentDocument != null) ...[
                    const SizedBox(height: 16),
                    _DocumentStatusCard(document: currentDocument),
                  ] else ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhum documento enviado ainda.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
            const SizedBox(height: 30),
            const Text(
              'REQUISITOS PARA APROVACAO',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
                  const SizedBox(height: 18),
                  const _RequirementTile(
                    label: 'Documento original e atualizado',
                    checked: true,
                  ),
                  const SizedBox(height: 12),
                  const _RequirementTile(
                    label: 'Foto nitida e sem reflexos de luz',
                  ),
                  const SizedBox(height: 12),
                  const _RequirementTile(
                    label: 'Todos os quatro cantos visiveis',
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed:
                          state.isUpdating ? null : () => _submit(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          state.isUpdating
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Enviar Documento',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Ao enviar, voce concorda com os Termos de Uso do TMJ Drive.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;

    final size = picked.size;
    if (size > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo deve ter no maximo 10MB.')),
      );
      return;
    }

    setState(() {
      _selectedFile = File(picked.path!);
      _selectedFileName = picked.name;
    });
  }

  Future<void> _submit(ProfileController controller) async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um arquivo antes de enviar.')),
      );
      return;
    }

    final success = await controller.uploadVehicleDocument(
      vehicleId: widget.vehicle.id,
      type: 'CRLV',
      filePath: _selectedFile!.path,
    );

    if (!mounted || !success) return;
    await _loadDocuments();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}

class _DocumentStatusCard extends StatelessWidget {
  const _DocumentStatusCard({required this.document});

  final DriverVehicleDocumentItem document;

  @override
  Widget build(BuildContext context) {
    final normalized = document.status.toUpperCase();
    final color = switch (normalized) {
      'APPROVED' => const Color(0xFF34D399),
      'REJECTED' => const Color(0xFFFF6B6B),
      'UNDER_REVIEW' => const Color(0xFFFBBF24),
      _ => const Color(0xFF60A5FA),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ProfileVehicleDocumentScreenState._panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF22314A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(normalized),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (document.fileName != null &&
              document.fileName!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              document.fileName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (document.uploadedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Enviado em ${_formatDate(document.uploadedAt!)}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (document.reviewedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Revisado em ${_formatDate(document.reviewedAt!)}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (document.reason != null &&
              document.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              document.reason!,
              style: const TextStyle(
                color: Color(0xFFFFB4B4),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(String value) {
    switch (value) {
      case 'APPROVED':
        return 'Aprovado';
      case 'REJECTED':
        return 'Reprovado';
      case 'UNDER_REVIEW':
        return 'Em analise';
      default:
        return 'Pendente';
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _DocumentPickerCard extends StatelessWidget {
  const _DocumentPickerCard({required this.fileName, required this.onTap});

  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: _ProfileVehicleDocumentScreenState._border,
        strokeWidth: 1.5,
        dash: 8,
        gap: 6,
        radius: 18,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: _ProfileVehicleDocumentScreenState._card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFF4A0E2E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.file_upload_outlined,
                color: _ProfileVehicleDocumentScreenState._primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              fileName == null
                  ? 'Toque para selecionar o arquivo'
                  : 'Arquivo selecionado',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Formatos aceitos: JPG, PNG ou PDF (max. 10MB)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ProfileVehicleDocumentScreenState._muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ProfileVehicleDocumentScreenState._primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Escolher Arquivo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({required this.label, this.checked = false});

  final String label;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _ProfileVehicleDocumentScreenState._panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222B3A)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color:
                  checked
                      ? _ProfileVehicleDocumentScreenState._primary
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    checked
                        ? _ProfileVehicleDocumentScreenState._primary
                        : const Color(0xFF3B4454),
              ),
            ),
            child:
                checked
                    ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 24,
                    )
                    : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dash != oldDelegate.dash ||
        gap != oldDelegate.gap ||
        radius != oldDelegate.radius;
  }
}
