import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_providers.dart';
import '../../domain/profile_models.dart';
import 'profile_add_vehicle_screen.dart';
import 'profile_vehicle_document_screen.dart';

class ProfileVehicleScreen extends ConsumerWidget {
  const ProfileVehicleScreen({super.key});

  static const Color _bg = Color(0xFF000000);
  static const Color _primary = Color(0xFFD62D86);
  static const Color _line = Color(0xFF1E293B);
  static const Color _panel = Color(0xFF0B1326);
  static const Color _card = Color(0xFF0F1D3A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(profileControllerProvider, (previous, next) {
      if (!context.mounted) return;
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
    final payload = state.payload;
    final vehicles = payload?.vehicles ?? const <DriverProfileVehicle>[];

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
                      'Meus Veículos',
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
            const Divider(color: _line, height: 1),
            Expanded(
              child:
                  state.isLoading && payload == null
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: controller.load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          children: [
                            if (vehicles.isEmpty)
                              _EmptyVehiclesCard(
                                onAddTap: () async {
                                  final created = await Navigator.of(
                                    context,
                                  ).push<bool>(
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              const ProfileAddVehicleScreen(),
                                    ),
                                  );
                                  if (created == true) {
                                    await controller.load();
                                  }
                                },
                              )
                            else
                              ...vehicles.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: _VehicleTile(
                                    data: item,
                                    isUpdating: state.isUpdating,
                                    onDocumentsTap: () async {
                                      final uploaded = await Navigator.of(
                                        context,
                                      ).push<bool>(
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  ProfileVehicleDocumentScreen(
                                                    vehicle: item,
                                                  ),
                                        ),
                                      );
                                      if (uploaded == true) {
                                        await controller.load();
                                      }
                                    },
                                    onActionTap:
                                        item.isActive
                                            ? null
                                            : () async {
                                              final success = await controller
                                                  .activateVehicle(item.id);
                                              if (!context.mounted ||
                                                  !success) {
                                                return;
                                              }
                                            },
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            const Divider(color: _line, height: 1),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 62,
                              child: ElevatedButton.icon(
                                onPressed:
                                    state.isUpdating
                                        ? null
                                        : () async {
                                          final created = await Navigator.of(
                                            context,
                                          ).push<bool>(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      const ProfileAddVehicleScreen(),
                                            ),
                                          );
                                          if (created == true) {
                                            await controller.load();
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: _primary,
                                    size: 20,
                                  ),
                                ),
                                label: const Text(
                                  'Adicionar Novo Veiculo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.data,
    required this.isUpdating,
    required this.onDocumentsTap,
    required this.onActionTap,
  });

  final DriverProfileVehicle data;
  final bool isUpdating;
  final VoidCallback onDocumentsTap;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final isActive = data.isActive;
    final hasPendingDocuments =
        (data.documentationStatus ?? '').toUpperCase() == 'PENDING';
    final borderColor =
        isActive ? ProfileVehicleScreen._primary : const Color(0xFF1E3A5F);
    final background = ProfileVehicleScreen._card;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isActive ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusPill(
                      label:
                          isActive
                              ? 'ATIVO'
                              : hasPendingDocuments
                              ? 'DOCUMENTACAO PENDENTE'
                              : 'INATIVO',
                      active: isActive,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      data.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.displaySubtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2F4F),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _vehicleIcon(data.vehicleType),
                  color:
                      isActive
                          ? const Color(0xFFC62F78)
                          : const Color(0xFF7D8CA5),
                  size: 38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2F4F),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    data.photoUrl != null && data.photoUrl!.isNotEmpty
                        ? Image.network(
                          data.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                color: Color(0xFF64748B),
                                size: 42,
                              ),
                        )
                        : const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF64748B),
                          size: 42,
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    if (!isActive && hasPendingDocuments) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: onDocumentsTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF263857),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.upload_file_rounded,
                            color: Color(0xFFD8E2F1),
                          ),
                          label: const Text(
                            'Enviar\nDocumentos',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: isUpdating ? null : onActionTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isActive
                                  ? ProfileVehicleScreen._primary
                                  : Colors.transparent,
                          foregroundColor:
                              isActive
                                  ? Colors.white
                                  : ProfileVehicleScreen._primary,
                          side:
                              isActive
                                  ? BorderSide.none
                                  : const BorderSide(
                                    color: ProfileVehicleScreen._primary,
                                  ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon:
                            isUpdating && !isActive
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ProfileVehicleScreen._primary,
                                  ),
                                )
                                : Icon(
                                  isActive
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                ),
                        label: Text(
                          isActive ? 'Veiculo Atual' : 'Ativar',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _vehicleIcon(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('pickup') || normalized.contains('caminhonete')) {
      return Icons.airport_shuttle_rounded;
    }
    if (normalized.contains('moto')) {
      return Icons.two_wheeler_rounded;
    }
    return Icons.directions_car_filled_rounded;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF5A1135) : const Color(0xFF433210),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!active) ...[
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFFB020),
              size: 16,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFFFF63AF) : const Color(0xFFFFB020),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVehiclesCard extends StatelessWidget {
  const _EmptyVehiclesCard({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProfileVehicleScreen._panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A3558)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nenhum veiculo cadastrado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Adicione seu primeiro veiculo para iniciar o processo de aprovacao.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: onAddTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62F78),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Adicionar Veiculo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
