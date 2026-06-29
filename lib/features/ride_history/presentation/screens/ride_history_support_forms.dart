import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/ride_history_providers.dart';
import '../../domain/ride_history_models.dart';
import '../../domain/ride_history_repository.dart';

// ==========================================
// TEMA E CONSTANTES
// ==========================================

class AppTheme {
  // Cores Gerais
  static const Color bgDark = Color(0xFF000000);
  static const Color bgBurgundy = Color(0xFF130E13);
  static const Color primary = Color(0xFFC62F78);
  static const Color success = Color(0xFFDE377D);
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFF94A3B8);

  // Tema Padrão Escuro
  static const Color panelDark = Color(0xFF0B0B0D);
  static const Color strokeDark = Color(0xFF232328);

  // Tema Azul (Problema com Valor)
  static const Color panelBlue = Color(0xFF040D1A);
  static const Color strokeBlue = Color(0xFF12233A);

  // Tema Bordô (Objeto Esquecido)
  static const Color panelBurgundy = Color(0xFF2A0B18);
  static const Color strokeBurgundy = Color(0xFF6A183D);

  static const double radius = 16.0;
}

// ==========================================
// TELAS DE SUPORTE
// ==========================================

class RideHistoryOtherIssueScreen extends ConsumerStatefulWidget {
  const RideHistoryOtherIssueScreen({
    super.key,
    required this.rideId,
    required this.issueCode,
    required this.title,
    this.defaultSubject,
  });

  final String rideId;
  final RideSupportIssueCode issueCode;
  final String title;
  final String? defaultSubject;

  @override
  ConsumerState<RideHistoryOtherIssueScreen> createState() =>
      _RideHistoryOtherIssueScreenState();
}

class _RideHistoryOtherIssueScreenState
    extends ConsumerState<RideHistoryOtherIssueScreen> {
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  File? _attachment;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _subjectCtrl.text = widget.defaultSubject ?? '';
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SupportScaffold(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RideSummaryCard(
            title: 'Corrida #${widget.rideId}',
            subtitle: 'Resumo da viagem selecionada',
            icon: Icons.directions_car_filled_rounded,
            iconColor: Colors.white,
            iconBg: const Color(0xFFFF6A00),
          ),
          const SizedBox(height: 28),
          const _FormLabel('Assunto'),
          const SizedBox(height: 10),
          _TextFieldCard(
            controller: _subjectCtrl,
            hint: 'Sobre o que você quer falar?',
            maxLines: 1,
          ),
          const SizedBox(height: 24),
          const _FormLabel('Descrição detalhada'),
          const SizedBox(height: 10),
          _TextFieldCard(
            controller: _descriptionCtrl,
            hint: 'Conte-nos mais sobre o seu problema...',
            maxLines: 6,
          ),
          const SizedBox(height: 22),
          _AttachmentPanel(
            title: 'Anexar foto',
            description: 'Opcional: Envie uma imagem para ajudar na resolução.',
            buttonLabel:
                _attachment == null ? 'Adicionar Imagem' : 'Trocar Imagem',
            icon: Icons.add_a_photo_outlined,
            attachmentName: _attachment?.path.split('/').last,
            onTap: _pickAttachment,
          ),
          const SizedBox(height: 48),
          _PrimaryActionButton(
            label: 'Enviar Mensagem',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Nossa equipe responderá em até 24 horas úteis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _attachment = File(picked.path));
  }

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();

    if (subject.isEmpty) {
      _showMessage('Preencha o assunto do chamado.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(rideHistoryRepositoryProvider);
      final attachments = await _uploadAttachments(repository);
      final result = await repository.createSupportTicket(
        rideId: widget.rideId,
        issueCode: widget.issueCode,
        subject: subject,
        description: description.isEmpty ? null : description,
        attachments: attachments,
      );

      if (!mounted) return;
      await _showMessage(
        result.message ?? 'Solicitação registrada com sucesso.',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<List<String>> _uploadAttachments(
    RideHistoryRepository repository,
  ) async {
    if (_attachment == null) return const <String>[];
    final uploaded = await repository.uploadAttachment(_attachment!);
    return [uploaded.fileId];
  }

  Future<void> _showMessage(String message) {
    return showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF14040D),
            title: const Text(
              'Aviso',
              style: TextStyle(color: AppTheme.textLight),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Color(0xFFD1D5DB)),
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

class RideHistoryValueIssueScreen extends ConsumerStatefulWidget {
  const RideHistoryValueIssueScreen({
    super.key,
    required this.rideId,
    required this.title,
  });

  final String rideId;
  final String title;

  @override
  ConsumerState<RideHistoryValueIssueScreen> createState() =>
      _RideHistoryValueIssueScreenState();
}

class _RideHistoryValueIssueScreenState
    extends ConsumerState<RideHistoryValueIssueScreen> {
  final _expectedCtrl = TextEditingController();
  final _receivedCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  File? _attachment;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _expectedCtrl.dispose();
    _receivedCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SupportScaffold(
      title: widget.title,
      useBlueCards: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RideSummaryCard(
            title: 'Corrida #${widget.rideId}',
            subtitle: '24 de Mai • 14:30 • Centro para Aeroporto',
            icon: Icons.directions_car_filled_rounded,
            iconColor: const Color(0xFFFF6A00),
            iconBg: const Color(0xFF2A1612),
            useBlueStyle: true,
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: _LabeledInput(
                  label: 'Valor esperado',
                  hint: 'R\$ 0,00',
                  controller: _expectedCtrl,
                  useBlueStyle: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _LabeledInput(
                  label: 'Valor recebido',
                  hint: 'R\$ 0,00',
                  controller: _receivedCtrl,
                  useBlueStyle: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _FormLabel('Descrição do problema'),
          const SizedBox(height: 12),
          _TextFieldCard(
            controller: _descriptionCtrl,
            hint: 'Explique o que aconteceu com o valor da sua corrida...',
            maxLines: 6,
            useBlueStyle: true,
          ),
          const SizedBox(height: 24),
          const _FormLabel('Anexar comprovante (opcional)'),
          const SizedBox(height: 12),
          _UploadDropzone(
            useBlueStyle: true,
            attachmentName: _attachment?.path.split('/').last,
            onTap: _pickAttachment,
          ),
          const SizedBox(height: 48),
          _PrimaryActionButton(
            label: 'Enviar Relato',
            trailingIcon: Icons.send_outlined,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Nossa equipe de suporte analisará seu pedido em até\n24 horas úteis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _attachment = File(picked.path));
  }

  Future<void> _submit() async {
    final expected = _parseMoney(_expectedCtrl.text);
    final received = _parseMoney(_receivedCtrl.text);
    final description = _descriptionCtrl.text.trim();

    if (expected == null || received == null) {
      _showMessage('Informe valores válidos em esperado e recebido.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(rideHistoryRepositoryProvider);
      final attachments = await _uploadAttachments(repository);
      await repository.createPaymentIssue(
        rideId: widget.rideId,
        expectedAmount: expected,
        receivedAmount: received,
        description: description.isEmpty ? null : description,
        attachments: attachments,
      );
      if (!mounted) return;
      await _showMessage('Relato enviado com sucesso.');
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  double? _parseMoney(String raw) {
    final normalized =
        raw
            .replaceAll('R\$', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')
            .trim();
    return double.tryParse(normalized);
  }

  Future<List<String>> _uploadAttachments(
    RideHistoryRepository repository,
  ) async {
    if (_attachment == null) return const <String>[];
    final uploaded = await repository.uploadAttachment(_attachment!);
    return [uploaded.fileId];
  }

  Future<void> _showMessage(String message) {
    return showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF14040D),
            title: const Text(
              'Aviso',
              style: TextStyle(color: AppTheme.textLight),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Color(0xFFD1D5DB)),
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

class RideHistoryPassengerAbsentScreen extends ConsumerStatefulWidget {
  const RideHistoryPassengerAbsentScreen({super.key, required this.rideId});

  final String rideId;

  @override
  ConsumerState<RideHistoryPassengerAbsentScreen> createState() =>
      _RideHistoryPassengerAbsentScreenState();
}

class _RideHistoryPassengerAbsentScreenState
    extends ConsumerState<RideHistoryPassengerAbsentScreen> {
  bool waitedFiveMinutes = false;
  bool calledPassenger = false;
  bool messagedPassenger = false;
  bool atBoardingPoint = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return _SupportScaffold(
      title: 'Passageiro Ausente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const _SectionLabel('CONTEXTO DA VIAGEM', color: AppTheme.primary),
          const SizedBox(height: 12),
          Text(
            'ID #${widget.rideId}',
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Confirme os detalhes da ausência do passageiro\npara processar o cancelamento sem taxa de\npenalidade.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 34),
          const _FormLabel('Confirmação de tempo'),
          const SizedBox(height: 12),
          _CheckboxTileCard(
            value: waitedFiveMinutes,
            onChanged: (value) => setState(() => waitedFiveMinutes = value),
            label: 'Aguardei mais de 5 minutos no local',
          ),
          const SizedBox(height: 22),
          const _FormLabel('Ações realizadas'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.panelDark,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.strokeDark),
            ),
            child: Column(
              children: [
                _ActionRow(
                  value: calledPassenger,
                  onChanged: (value) => setState(() => calledPassenger = value),
                  icon: Icons.call_outlined,
                  label: 'Tentei ligar para o passageiro',
                ),
                const Divider(height: 1, color: AppTheme.strokeDark),
                _ActionRow(
                  value: messagedPassenger,
                  onChanged:
                      (value) => setState(() => messagedPassenger = value),
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Enviei mensagem no chat',
                ),
                const Divider(height: 1, color: AppTheme.strokeDark),
                _ActionRow(
                  value: atBoardingPoint,
                  onChanged: (value) => setState(() => atBoardingPoint = value),
                  icon: Icons.location_on_outlined,
                  label: 'Estou exatamente no ponto de embarque',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3C3C3C),
                  Color(0xFF101010),
                  Color(0xFF0B1020),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    child: CustomPaint(painter: _GpsMapPainter()),
                  ),
                ),
                const Positioned(
                  left: 18,
                  bottom: 18,
                  child: Row(
                    children: [
                      Icon(Icons.gps_fixed, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Sua localização atual confirmada',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _PrimaryActionButton(
            label: 'Solicitar Cancelamento Sem Taxa',
            trailingIcon: Icons.output_rounded,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Ao solicitar o cancelamento, nossa equipe analisará os\ndados de GPS e logs de comunicação.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(rideHistoryRepositoryProvider);
      final ride = await ref.read(
        rideHistoryDetailProvider(widget.rideId).future,
      );
      await repository.createPassengerAbsent(
        rideId: widget.rideId,
        waitedMoreThan5Minutes: waitedFiveMinutes,
        calledPassenger: calledPassenger,
        messagedPassenger: messagedPassenger,
        atBoardingPoint: atBoardingPoint,
        driverLat: ride.originLat ?? 0,
        driverLng: ride.originLng ?? 0,
      );
      if (!mounted) return;
      await _showMessage('Solicitação registrada com sucesso.');
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showMessage(String message) {
    return showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF14040D),
            title: const Text(
              'Aviso',
              style: TextStyle(color: AppTheme.textLight),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Color(0xFFD1D5DB)),
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

class RideHistoryForgottenObjectScreen extends ConsumerStatefulWidget {
  const RideHistoryForgottenObjectScreen({super.key, required this.rideId});

  final String rideId;

  @override
  ConsumerState<RideHistoryForgottenObjectScreen> createState() =>
      _RideHistoryForgottenObjectScreenState();
}

class _RideHistoryForgottenObjectScreenState
    extends ConsumerState<RideHistoryForgottenObjectScreen> {
  final _descriptionCtrl = TextEditingController();
  File? _attachment;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SupportScaffold(
      title: 'Objeto Esquecido',
      burgundyTheme: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('DETALHES DA VIAGEM'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.panelBurgundy,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 2),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white10,
                      backgroundImage: AssetImage('assets/user.png'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mariana Silva',
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.success,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'CORRIDA FINALIZADA',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        '15 de Outubro, 14:30',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _SectionLabel('O QUE FOI ESQUECIDO?'),
          const SizedBox(height: 12),
          _TextFieldCard(
            controller: _descriptionCtrl,
            hint:
                'Ex: Carteira de couro preta, chaves com chaveiro azul, smartphone Samsung...',
            maxLines: 4,
            burgundyTheme: true,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tente ser o mais detalhista possível para facilitar a identificação.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 28),
          const _SectionLabel('FOTO DO OBJETO (OPCIONAL)'),
          const SizedBox(height: 12),
          _BurgundyUploadCard(
            attachmentName: _attachment?.path.split('/').last,
            onTap: _pickAttachment,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B1525),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nossa equipe de suporte analisará as informações e entrará em contato via chat ou telefone em até 24 horas para coordenar a devolução.',
                    style: TextStyle(
                      color: Color(0xFFE7DCE1),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _PrimaryActionButton(
            label: 'Enviar Relato',
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _attachment = File(picked.path));
  }

  Future<void> _submit() async {
    final description = _descriptionCtrl.text.trim();
    if (description.isEmpty) {
      _showMessage('Descreva o objeto esquecido para abrir o chamado.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(rideHistoryRepositoryProvider);
      final attachments = await _uploadAttachments(repository);
      await repository.createForgottenObject(
        rideId: widget.rideId,
        description: description,
        attachments: attachments,
      );
      if (!mounted) return;
      await _showMessage('Relato enviado com sucesso.');
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<List<String>> _uploadAttachments(
    RideHistoryRepository repository,
  ) async {
    if (_attachment == null) return const <String>[];
    final uploaded = await repository.uploadAttachment(_attachment!);
    return [uploaded.fileId];
  }

  Future<void> _showMessage(String message) {
    return showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF14040D),
            title: const Text(
              'Aviso',
              style: TextStyle(color: AppTheme.textLight),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Color(0xFFD1D5DB)),
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

// ==========================================
// WIDGETS COMPARTILHADOS GERAIS
// ==========================================

class _SupportScaffold extends StatelessWidget {
  const _SupportScaffold({
    required this.title,
    required this.child,
    this.useBlueCards = false,
    this.burgundyTheme = false,
  });

  final String title;
  final Widget child;
  final bool useBlueCards;
  final bool burgundyTheme;

  @override
  Widget build(BuildContext context) {
    final background = burgundyTheme ? AppTheme.bgBurgundy : AppTheme.bgDark;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _TopHeader(title: title, accent: burgundyTheme),
            const SizedBox(height: 18),
            Divider(
              color:
                  burgundyTheme
                      ? const Color(0xFF4A1630)
                      : useBlueCards
                      ? AppTheme.strokeBlue
                      : AppTheme.strokeDark,
              height: 1,
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title, this.accent = false});

  final String title;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back,
            color: accent ? AppTheme.primary : AppTheme.textLight,
            size: 24,
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48), // Spacer to balance the back button
      ],
    );
  }
}

class _RideSummaryCard extends StatelessWidget {
  const _RideSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.useBlueStyle = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool useBlueStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: useBlueStyle ? AppTheme.panelBlue : AppTheme.panelDark,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: useBlueStyle ? AppTheme.strokeBlue : AppTheme.strokeDark,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
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
                    color: AppTheme.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 16,
                    height: 1.4,
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

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textLight,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color ?? const Color(0xFFB9A8B3),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _TextFieldCard extends StatelessWidget {
  const _TextFieldCard({
    required this.controller,
    required this.hint,
    required this.maxLines,
    this.useBlueStyle = false,
    this.burgundyTheme = false,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool useBlueStyle;
  final bool burgundyTheme;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        burgundyTheme
            ? AppTheme.strokeBurgundy
            : useBlueStyle
            ? AppTheme.strokeBlue
            : AppTheme.strokeDark;
    final fillColor =
        burgundyTheme
            ? AppTheme.panelBurgundy
            : useBlueStyle
            ? AppTheme.panelBlue
            : AppTheme.panelDark;

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textLight, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.all(16),
          hintStyle: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 15,
            height: 1.4,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.useBlueStyle = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool useBlueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: useBlueStyle ? AppTheme.panelBlue : AppTheme.panelDark,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: useBlueStyle ? AppTheme.strokeBlue : AppTheme.strokeDark,
            ),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 16,
              ),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachmentPanel extends StatelessWidget {
  const _AttachmentPanel({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.onTap,
    this.attachmentName,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onTap;
  final String? attachmentName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF6A00), size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (attachmentName != null) ...[
            const SizedBox(height: 10),
            Text(
              attachmentName!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C),
                foregroundColor: AppTheme.textLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadDropzone extends StatelessWidget {
  const _UploadDropzone({
    this.useBlueStyle = false,
    required this.onTap,
    this.attachmentName,
  });

  final bool useBlueStyle;
  final VoidCallback onTap;
  final String? attachmentName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        width: double.infinity,
        height: 140, // Altura reduzida mais proporcional
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
            color: useBlueStyle ? AppTheme.strokeBlue : const Color(0xFF2C2C2C),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              color: AppTheme.textMuted,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              attachmentName ?? 'Clique para enviar ou arraste',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              'PNG, JPG ou PDF (Máx. 5MB)',
              style: TextStyle(color: Color(0xFF475569), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxTileCard extends StatelessWidget {
  const _CheckboxTileCard({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.panelDark,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.strokeDark),
        ),
        child: Row(
          children: [
            _CheckboxBox(value: value),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _CheckboxBox(value: value),
            const SizedBox(width: 16),
            Icon(icon, color: AppTheme.textMuted, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxBox extends StatelessWidget {
  const _CheckboxBox({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: value ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value ? AppTheme.primary : const Color(0xFF3A3A3A),
        ),
      ),
      child:
          value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          elevation: 0,
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailingIcon, size: 20),
                    ],
                  ],
                ),
      ),
    );
  }
}

class _BurgundyUploadCard extends StatelessWidget {
  const _BurgundyUploadCard({required this.onTap, this.attachmentName});

  final VoidCallback onTap;
  final String? attachmentName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF2A0B18).withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.strokeBurgundy, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: AppTheme.primary,
              size: 36,
            ),
            const SizedBox(height: 16),
            Text(
              attachmentName ?? 'Tirar ou anexar foto',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              attachmentName != null ? 'Trocar imagem' : 'PNG, JPG até 10MB',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road =
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      final x = size.width * (0.08 + i * 0.15);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + (i.isEven ? 14 : -10), size.height),
        road,
      );
    }
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.16 + i * 0.18);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (i.isEven ? 10 : -10)),
        road,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
