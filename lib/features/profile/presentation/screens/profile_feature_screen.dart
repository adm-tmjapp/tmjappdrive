import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmjappdrive/features/dashboard/application/dashboard_providers.dart';
import 'package:tmjappdrive/screens/auth/sign_in_screen.dart';

import '../../application/profile_providers.dart';
import '../../domain/profile_models.dart';
import 'profile_documents_screen.dart';
import 'profile_personal_data_screen.dart';
import 'profile_security_screen.dart';
import 'profile_vehicle_screen.dart';

class ProfileFeatureScreen extends ConsumerStatefulWidget {
  const ProfileFeatureScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<ProfileFeatureScreen> createState() =>
      _ProfileFeatureScreenState();
}

class _ProfileFeatureScreenState extends ConsumerState<ProfileFeatureScreen> {
  static const Color _bg = Color(0xFF000000);
  static const Color _panel = Color(0xFF0B1326);
  static const Color _card = Color(0xFF0F1D3A);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _primary = Color(0xFFD62D86);
  static const Color _danger = Color(0xFFFF4D4F);

  @override
  Widget build(BuildContext context) {
    ref.listen(profileControllerProvider, (previous, next) {
      if (previous?.payload != next.payload && next.payload != null) {
        ref.read(dashboardControllerProvider.notifier).refreshDriverSession();
      }
    });

    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    if (state.isLoading && state.payload == null) {
      return const ColoredBox(
        color: _bg,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final payload = state.payload;
    if (payload == null) {
      return ColoredBox(
        color: _bg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.error ?? 'Falha ao carregar perfil.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.load,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: _bg,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Perfil do Motorista',
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
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF1E293B), height: 1),
              const SizedBox(height: 24),
              _ProfileHeader(profile: payload.profile),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        value:
                            payload.profile.rating?.toStringAsFixed(1) ?? '0.0',
                        label: 'NOTA',
                        highlight: true,
                        icon: Icons.star_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MetricCard(
                        value: '${payload.profile.totalRides}',
                        label: 'CORRIDAS',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MetricCard(
                        value: '${_yearsSince(payload.profile.partnerSince)}',
                        label: 'ANOS',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const _SectionTitle(title: 'VEICULO ATIVO'),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _VehicleCard(
                  vehicle: payload.vehicle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileVehicleScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle(title: 'CONFIGURAÇÕES'),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Dados Pessoais',
                subtitle: payload.profile.cpfMasked,
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder:
                          (_) => ProfilePersonalDataScreen(
                            profile: payload.profile,
                          ),
                    ),
                  );
                  if (updated == true) {
                    await controller.load();
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Documentos',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileDocumentsScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.directions_car_filled_outlined,
                title: 'Veículos',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileVehicleScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Segurança e Termos',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              ProfileSecurityScreen(security: payload.security),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 2,
                ),
                leading:
                    state.isLoggingOut
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(
                          Icons.logout_rounded,
                          color: _danger,
                          size: 24,
                        ),
                title: const Text(
                  'Sair',
                  style: TextStyle(
                    color: _danger,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap:
                    state.isLoggingOut
                        ? null
                        : () async {
                          final success = await controller.logout();
                          if (!context.mounted || !success) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => SignInScreen()),
                            (route) => false,
                          );
                        },
              ),
              const SizedBox(height: 34),
              Center(
                child: Text(
                  'Politica de Privacidade',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Versão ${payload.security.appVersion}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _yearsSince(DateTime date) {
    final now = DateTime.now();
    var years = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      years -= 1;
    }
    return years <= 0 ? 1 : years;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFED5AA9), Color(0xFFD62D86)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Container(
                      color: const Color(0xFF1A1A1D),
                      child: _buildImage(),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 6,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _ProfileFeatureScreenState._primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _ProfileFeatureScreenState._primary.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Motorista parceiro desde ${profile.partnerSince.year}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    final path = profile.profilePhotoUrl;
    if (path == null || path.trim().isEmpty) {
      return _fallback();
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF2C2C2C),
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: Colors.white70, size: 62),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    this.highlight = false,
    this.icon,
  });

  final String value;
  final String label;
  final bool highlight;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final valueColor =
        highlight ? _ProfileFeatureScreenState._primary : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: _ProfileFeatureScreenState._panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: valueColor, size: 15),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onTap});

  final DriverProfileVehicle? vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Center(
        child: SizedBox(
          width: 358,
          child: Container(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _ProfileFeatureScreenState._card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E3A5F), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B1037),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: Color(0xFFD62D86),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle?.displayName ?? 'Veiculo nao informado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vehicle?.displaySubtitle ??
                            'Nenhum veiculo ativo vinculado ao perfil',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: Icon(icon, color: const Color(0xFF94A3B8), size: 24),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle:
              subtitle == null
                  ? null
                  : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
            size: 28,
          ),
          onTap: onTap,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: Color(0xFF1E293B), height: 1),
        ),
      ],
    );
  }
}
