import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/dashboard_providers.dart';
import '../../domain/dashboard_models.dart';
import 'dashboard_active_ride_screen.dart';
import '../../../profile/presentation/screens/profile_feature_screen.dart';
import '../../../ride_history/presentation/screens/ride_history_screen.dart';
import '../../../wallet_pix/presentation/screens/wallet_earnings_screen.dart';
import '../widgets/dashboard_rides_list.dart';
import '../widgets/dashboard_summary_cards.dart';
import '../widgets/notification_widgets.dart';

class DashboardFeatureScreen extends ConsumerStatefulWidget {
  const DashboardFeatureScreen({super.key});

  @override
  ConsumerState<DashboardFeatureScreen> createState() =>
      _DashboardFeatureScreenState();
}

class _DashboardFeatureScreenState extends ConsumerState<DashboardFeatureScreen>
    with WidgetsBindingObserver {
  bool _isShowingServiceAlert = false;
  bool _isShowingRideRequest = false;
  int _currentTabIndex = 0;
  String? _lastOpenedActiveRideId;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_currentTabIndex == 0) unawaited(_refreshDashboard());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentTabIndex == 0) {
      unawaited(_refreshDashboard());
    }
  }

  Future<void> _refreshDashboard() async {
    await ref.read(dashboardControllerProvider.notifier).load();
  }

  void _showIncomingRideDialog(RideCardItem ride) {
    _isShowingRideRequest = true;
    final controller = ref.read(dashboardControllerProvider.notifier);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        void closeAnd(void Function() action) {
          Navigator.of(dialogContext).pop();
          action();
        }

        return AlertDialog(
          title: const Text('Nova corrida disponível'),
          content: SingleChildScrollView(
            child: _NewRequestCard(
              ride: ride,
              onAccept:
                  () => closeAnd(() {
                    unawaited(controller.acceptRide(ride.id));
                  }),
              onReject: () => closeAnd(() => controller.rejectRide(ride.id)),
              onExpire: () => closeAnd(() => controller.rejectRide(ride.id)),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _isShowingRideRequest = false;
    });
  }

  Future<void> _openActiveRide(RideCardItem ride) async {
    _lastOpenedActiveRideId = ride.id;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DashboardActiveRideScreen(ride: ride)),
    );
    if (!mounted) return;
    await _refreshDashboard();
  }

  void _onTabChanged(int index) {
    setState(() => _currentTabIndex = index);
    if (index == 0) {
      unawaited(_refreshDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dashboardControllerProvider, (previous, next) {
      final incomingRide = next.liveRideRequest;
      final previousRideId = previous?.liveRideRequest?.id;
      if (incomingRide != null &&
          incomingRide.id != previousRideId &&
          !_isShowingRideRequest) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _isShowingRideRequest) return;
          _showIncomingRideDialog(incomingRide);
        });
      }

      final newError = next.error;
      if (newError == null) return;
      if (newError != 'Serviço indisponível') return;
      if (_isShowingServiceAlert) return;
      if (newError == previous?.error) return;

      _isShowingServiceAlert = true;
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Aviso'),
            content: const Text('Serviço indisponível'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ).whenComplete(() {
        _isShowingServiceAlert = false;
      });
    });

    final state = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);
    final rides = state.snapshot?.rides ?? const <RideCardItem>[];
    final featuredRide =
        state.liveRideRequest ?? (rides.isNotEmpty ? rides.first : null);
    final recentRides = rides
        .where((ride) => featuredRide == null || ride.id != featuredRide.id)
        .toList(growable: false);
    final isOnline = state.availability == DriverAvailability.online;
    final hasServiceError = state.error == 'Serviço indisponível';
    final summary = state.snapshot?.summary;
    final showFeedbackCards =
        hasServiceError ||
        state.snapshot == null ||
        (state.snapshot != null && recentRides.isEmpty && featuredRide == null);
    final hasActiveRide =
        featuredRide != null &&
        (featuredRide.status == 'accepted' || featuredRide.status == 'ongoing');

    if (_currentTabIndex == 0 && hasActiveRide) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_lastOpenedActiveRideId == featuredRide.id) return;
        unawaited(_openActiveRide(featuredRide));
      });
    } else if (!hasActiveRide) {
      _lastOpenedActiveRideId = null;
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Fundo totalmente preto
      bottomNavigationBar: _DashboardBottomNav(
        currentIndex: _currentTabIndex,
        onTap: _onTabChanged,
      ),
      body: SafeArea(
        bottom: true,
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            RefreshIndicator(
              onRefresh: _refreshDashboard,
              color: const Color(0xFFC62F78),
              backgroundColor: const Color(0xFF121212),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 120 + bottomInset),
                children: [
                  const SizedBox(height: 20),
                  _HeaderRow(
                    driverName: state.driverName,
                    profileImagePath: state.driverProfileImage,
                  ),
                  const SizedBox(height: 24),
                  _StatusCard(
                    availability: state.availability,
                    onToggle: controller.toggleAvailability,
                  ),
                  const SizedBox(height: 16),
                  _PeriodTabs(
                    selected: state.filters.period,
                    onChanged: controller.setPeriod,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF1E1E1E), height: 1),
                  const SizedBox(height: 16),
                  if (state.lastUpdatedAt != null) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Atualizado às ${TimeOfDay.fromDateTime(state.lastUpdatedAt!).format(context)}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.isLoading && state.snapshot == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(
                          color: Color(0xFFC62F78),
                        ),
                      ),
                    )
                  else ...[
                    if (showFeedbackCards) ...[
                      _EarningsFeedbackCard(
                        amountLabel: summary?.todayEarnings ?? 'R\$ 0,00',
                        hasApiError: hasServiceError,
                      ),
                      const SizedBox(height: 24),
                      _RecentTitle(
                        isOffline: !isOnline,
                        title: 'Corridas Recentes',
                        actionLabel: 'Ver tudo',
                      ),
                      const SizedBox(height: 12),
                      _NoRidesFeedbackCard(
                        hasApiError: hasServiceError,
                        onRetry: hasServiceError ? _refreshDashboard : null,
                      ),
                      const SizedBox(height: 24),
                      if (!isOnline)
                        _GoOnlineButton(onTap: controller.toggleAvailability),
                    ] else if (state.snapshot != null) ...[
                      DashboardSummaryCards(summary: state.snapshot!.summary),
                      const SizedBox(height: 24),
                      if (!isOnline) ...[
                        _OfflinePanel(
                          onGoOnline: controller.toggleAvailability,
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (isOnline && featuredRide != null) ...[
                        if (featuredRide.status == 'accepted' ||
                            featuredRide.status == 'ongoing')
                          _AcceptedRideCard(
                            ride: featuredRide,
                            onOpenRide: () => _openActiveRide(featuredRide),
                          )
                        else
                          _NewRequestCard(
                            ride: featuredRide,
                            onAccept:
                                () => controller.acceptRide(featuredRide.id),
                            onReject:
                                () => controller.rejectRide(featuredRide.id),
                            onExpire:
                                () => controller.rejectRide(featuredRide.id),
                          ),
                        const SizedBox(height: 24),
                      ],
                      _RecentTitle(
                        isOffline: !isOnline,
                        title: 'Ultimas Corridas',
                        actionLabel: 'Ver tudo',
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: isOnline ? 1 : 0.65,
                        child: DashboardRidesList(
                          rides: recentRides,
                          isLoading: state.isLoading,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const WalletEarningsScreen(),
            const RideHistoryScreen(embedded: true),
            ProfileFeatureScreen(onBack: () => _onTabChanged(0)),
          ],
        ),
      ),
    );
  }
}

class _OfflinePanel extends StatelessWidget {
  const _OfflinePanel({required this.onGoOnline});

  final VoidCallback onGoOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modo offline ativo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Voce nao esta recebendo corridas no momento. Ative o modo online para voltar ao fluxo normal.',
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onGoOnline,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62F78),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ATIVAR ONLINE',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.driverName, required this.profileImagePath});

  final String driverName;
  final String? profileImagePath;

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;
    if (profileImagePath != null && profileImagePath!.isNotEmpty) {
      if (profileImagePath!.startsWith('http')) {
        provider = NetworkImage(profileImagePath!);
      } else {
        provider = AssetImage(profileImagePath!);
      }
    }

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFBCE4D3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child:
                provider == null
                    ? const Icon(
                      Icons.person,
                      color: Color(0xFF18412F),
                      size: 36,
                    )
                    : Image(image: provider, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MOTORISTA',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                driverName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    ),
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC62F78),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.availability, required this.onToggle});

  final DriverAvailability availability;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isOnline = availability == DriverAvailability.online;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF140810),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B1528), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATUS ATUAL',
                  style: TextStyle(
                    color: Color(0xFFC62F78),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              height: 32,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color:
                    isOnline
                        ? const Color(0xFF5C0C3A)
                        : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color:
                      isOnline
                          ? const Color(0xFF7F2057)
                          : const Color(0xFF475569),
                  width: 1.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    isOnline ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isOnline
                            ? const Color(0xFFC62F78)
                            : const Color(0xFF94A3B8),
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

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selected, required this.onChanged});

  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildButtons(compact: true),
          );
        }

        final buttons = _buildButtons();
        return Row(
          children: [
            Expanded(child: buttons[0]),
            const SizedBox(width: 8),
            Expanded(child: buttons[1]),
            const SizedBox(width: 8),
            Expanded(child: buttons[2]),
          ],
        );
      },
    );
  }

  List<Widget> _buildButtons({bool compact = false}) {
    return [
      _PeriodButton(
        label: 'SEMANAL',
        selected: selected == DashboardPeriod.weekly,
        compact: compact,
        onTap: () => onChanged(DashboardPeriod.weekly),
      ),
      _PeriodButton(
        label: 'QUINZENAL',
        selected: selected == DashboardPeriod.biweekly,
        compact: compact,
        onTap: () => onChanged(DashboardPeriod.biweekly),
      ),
      _PeriodButton(
        label: 'MENSAL',
        selected: selected == DashboardPeriod.monthly,
        compact: compact,
        onTap: () => onChanged(DashboardPeriod.monthly),
      ),
    ];
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: compact ? 156 : null,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFC62F78) : const Color(0xFF161618),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? const Color(0xFFC62F78) : const Color(0xFF2A2A2A),
          width: 1,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _NewRequestCard extends StatelessWidget {
  const _NewRequestCard({
    required this.ride,
    required this.onAccept,
    required this.onReject,
    required this.onExpire,
  });

  final RideCardItem ride;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onExpire;

  @override
  Widget build(BuildContext context) {
    final origin =
        ride.pickupAddress.isNotEmpty
            ? ride.pickupAddress
            : _origin(ride.route);
    final destination =
        ride.dropoffAddress.isNotEmpty
            ? ride.dropoffAddress
            : _destination(ride.route);
    final distanceLabel = _distance(ride);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.circle, color: Color(0xFFC62F78), size: 10),
            SizedBox(width: 8),
            Text(
              'Nova Solicitação',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66C62F78), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ride.expiresAt != null || ride.startedAt != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _DispatchCountdown(ride: ride, onExpire: onExpire),
                ),
              ],
              Container(
                height: 170,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuA2VnwZ7CovDIzlucpOB8SNcxn8UiG4EceT6qDxYJmAEdTnIAbTMyVDKXzPX2ekXijHuKr8JwtGW7Ouav4MvAtJSs3BSmfrETRV3ckotsQaKEneviEW01_NXuoA4vSipBBdF1XWvj831y9TO7guxiESi1y5HEizs9oRvo4ZOVemWDTfMeoF68uEczdpiP5mfiLNPssLibMHTIi9oTHT5vUerQOzF5kd8IoO6VZdYDQqSpfr5RtR2-exTA1YFykZCvtG56IhyuU7alx9',
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color(0x99000000),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF121212), Color(0x00121212)],
                      stops: [0.0, 0.7],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DISTÂNCIA',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              distanceLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'VALOR ESTIMADO',
                            style: TextStyle(
                              color: Color(0xFFC62F78),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ride.price,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 5),
                            const Icon(
                              Icons.circle,
                              size: 12,
                              color: Color(0xFF60A5FA),
                            ),
                            Container(
                              height: 38,
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: const Color(0xFF334155),
                            ),
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Color(0xFFC62F78),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ORIGEM',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                origin,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'DESTINO',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                destination,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onReject,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF18181B),
                              foregroundColor: const Color(0xFFE2E8F0),
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(
                                color: Color(0xFF334155),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'RECUSAR',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62F78),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'ACEITAR',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _origin(String route) {
    final chunks = route.split('->');
    if (chunks.isEmpty) return route.trim();
    return chunks.first.trim();
  }

  String _destination(String route) {
    final chunks = route.split('->');
    if (chunks.length < 2) return route.trim();
    return chunks.last.trim();
  }

  String _distance(RideCardItem ride) {
    return ride.distanceKm.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _AcceptedRideCard extends StatelessWidget {
  const _AcceptedRideCard({required this.ride, required this.onOpenRide});

  final RideCardItem ride;
  final VoidCallback onOpenRide;

  @override
  Widget build(BuildContext context) {
    final destination =
        ride.dropoffAddress.isNotEmpty
            ? ride.dropoffAddress
            : _destination(ride.route);
    final pickupDistance = '${_distance(ride)} KM PARA O EMBARQUE';
    final passengerLabel =
        ride.isPassenger ? 'Passageiro aguardando' : ride.type;
    final etaLabel = ride.etaMin > 0 ? '${ride.etaMin} MIN' : '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.circle, color: Color(0xFF60A5FA), size: 10),
            SizedBox(width: 8),
            Text(
              'Corrida em Andamento',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x6660A5FA), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuA2VnwZ7CovDIzlucpOB8SNcxn8UiG4EceT6qDxYJmAEdTnIAbTMyVDKXzPX2ekXijHuKr8JwtGW7Ouav4MvAtJSs3BSmfrETRV3ckotsQaKEneviEW01_NXuoA4vSipBBdF1XWvj831y9TO7guxiESi1y5HEizs9oRvo4ZOVemWDTfMeoF68uEczdpiP5mfiLNPssLibMHTIi9oTHT5vUerQOzF5kd8IoO6VZdYDQqSpfr5RtR2-exTA1YFykZCvtG56IhyuU7alx9',
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color(0x99000000),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF121212), Color(0x00121212)],
                      stops: [0.0, 0.7],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PASSAGEIRO',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              passengerLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'TEMPO EST.',
                            style: TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            etaLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Color(0xFFC62F78),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DESTINO',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                destination,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: onOpenRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62F78),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.navigation_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'VOLTAR PARA NAVEGACAO',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'INICIO',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          pickupDistance,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(
                        value: 0.3,
                        minHeight: 4,
                        backgroundColor: Color(0xFF1E293B),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFC62F78),
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
    );
  }

  String _destination(String route) {
    final chunks = route.split('->');
    if (chunks.length < 2) return route.trim();
    return chunks.last.trim();
  }

  String _distance(RideCardItem ride) {
    if (ride.distanceKm <= 0) return '-- KM';
    return '${ride.distanceKm.toStringAsFixed(1).replaceAll('.', ',')} KM';
  }
}

class _DispatchCountdown extends StatefulWidget {
  const _DispatchCountdown({required this.ride, required this.onExpire});

  final RideCardItem ride;
  final VoidCallback onExpire;

  @override
  State<_DispatchCountdown> createState() => _DispatchCountdownState();
}

class _DispatchCountdownState extends State<_DispatchCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _expiredHandled = false;

  @override
  void initState() {
    super.initState();
    _syncRemaining();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncRemaining(),
    );
  }

  @override
  void didUpdateWidget(covariant _DispatchCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ride.id != widget.ride.id ||
        oldWidget.ride.expiresAt != widget.ride.expiresAt ||
        oldWidget.ride.startedAt != widget.ride.startedAt) {
      _expiredHandled = false;
      _syncRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        _remaining.inSeconds <= 5
            ? const Color(0xFFF97316)
            : const Color(0xFFC62F78);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0D15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B1528)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _remaining.isNegative || _remaining == Duration.zero
                  ? 'Janela de aceite encerrada'
                  : 'Tempo para aceitar: ${_formatDuration(_remaining)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _syncRemaining() {
    final expiresAt = widget.ride.expiresAt;
    final startedAt = widget.ride.startedAt;
    final timeoutMs = widget.ride.dispatchTimeoutMs;

    Duration next = Duration.zero;
    if (expiresAt != null) {
      next = expiresAt.difference(DateTime.now());
    } else if (startedAt != null && timeoutMs != null) {
      next = startedAt
          .add(Duration(milliseconds: timeoutMs))
          .difference(DateTime.now());
    }

    if (!mounted) return;
    setState(() {
      _remaining = next.isNegative ? Duration.zero : next;
    });

    if (_remaining == Duration.zero && !_expiredHandled) {
      _expiredHandled = true;
      widget.onExpire();
    }
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _RecentTitle extends StatelessWidget {
  const _RecentTitle({
    required this.isOffline,
    this.title = 'Últimas Corridas',
    this.actionLabel = 'Ver tudo',
  });

  final bool isOffline;
  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isOffline ? 0.8 : 1),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          actionLabel,
          style: const TextStyle(
            color: Color(0xFFC62F78),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EarningsFeedbackCard extends StatelessWidget {
  const _EarningsFeedbackCard({
    required this.amountLabel,
    required this.hasApiError,
  });

  final String amountLabel;
  final bool hasApiError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF101217), // Fundo escuro sutil
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF27272A),
          width: 1,
        ), // Borda de 1px conforme o figma
      ),
      child: Column(
        children: [
          Container(
            width: 64, // Tamanho do ícone reduzido conforme design
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF2A1525), // Fundo rosado escuro
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              size: 32,
              color: Color(0xFFC62F78),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ganhos de Hoje',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amountLabel,
            style: const TextStyle(
              color: Color(0xFFC62F78),
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasApiError
                ? 'Nao foi possivel carregar os dados de corridas agora. Tente novamente.'
                : 'Você ainda não possui dados\nregistrados para este período.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFA1A1AA),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoRidesFeedbackCard extends StatelessWidget {
  const _NoRidesFeedbackCard({required this.hasApiError, this.onRetry});

  final bool hasApiError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF101217),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF27272A),
          width: 1, // Borda exata do figma
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF27272A), // Fundo cinza do ícone
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_taxi_outlined,
              color: Color(0xFFA1A1AA), // Ícone cinza
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma corrida encontrada',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasApiError
                ? 'Serviço indisponível no momento. Verifique sua conexão e tente novamente.'
                : 'Fique online para começar a receber solicitações.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
          ),
          if (hasApiError && onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62F78),
                side: const BorderSide(color: Color(0x66C62F78)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoOnlineButton extends StatelessWidget {
  const _GoOnlineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56, // Altura padrão mais adequada ao mockup
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.sensors,
          color: Colors.white,
          size: 24,
        ), // Ícone de sinal ((•))
        label: const Text(
          'Ficar Online Agora',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62F78),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1013),
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_filled,
            label: 'Início', // Fonte natural do mockup
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Ganhos',
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.local_taxi_outlined,
            label: 'Corridas',
            active: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Conta',
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFC62F78) : const Color(0xFF64748B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
