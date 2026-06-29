import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/dashboard_api.dart';
import '../../domain/dashboard_models.dart';
import 'dashboard_ride_summary_screen.dart';
import 'package:tmjappdrive/features/dashboard/presentation/widgets/notification_widgets.dart';

class DashboardActiveRideScreen extends StatelessWidget {
  DashboardActiveRideScreen({super.key, required this.ride});

  final RideCardItem ride;
  final DashboardApi _dashboardApi = DashboardApi();

  static const Color _bg = Color(0xFF000000);
  static const Color _panel = Color(0xFF0C0F18);
  static const Color _panelSoft = Color(0xFF202A3D);
  static const Color _stroke = Color(0x22C62F78);
  static const Color _primary = Color(0xFFC62F78);
  static const Color _muted = Color(0xFF94A3B8);

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
    final distanceLabel =
        '${ride.distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
    final etaLabel = ride.etaMin > 0 ? '${ride.etaMin} min' : '--';
    final passengerLabel =
        ride.passengerName.trim().isNotEmpty
            ? ride.passengerName
            : 'Passageiro';
    final passengerMeta =
        ride.passengerRating != null
            ? '${ride.passengerRating!.toStringAsFixed(1)} • Passageiro VIP'
            : (ride.isPassenger ? 'Passageiro VIP' : ride.paymentMethodLabel);

    if (ride.status.toLowerCase() == 'ongoing') {
      return _OngoingRideNavigationScreen(
        ride: ride,
        onFinishRide: _confirmFinishRide,
        onMessage: _openSms,
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Corrida Aceita',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      ),
                  icon: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                TextButton(
                  onPressed:
                      () => _showMessage(context, 'Canal SOS em configuracao.'),
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      color: Color(0xFFFF5E5E),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 194,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _stroke),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuD_W-1ILE9rlNyGPfFtTkRA3iyboihDn48Md5c7RfjDr1K8MYbeEt3Pf_M-UAAnltb7DkxFUtVU2jFKQ0WLWve9eBsXmefHLBq_JJ8jHwMBHAci7J7r8gpdrMc1g-zLcj5evy_uXFrPU4Y32yqfrImmo2WFzuhAR9vvCeEhPmcQxqYH_fSwTGdJGgYHKCwMEeDPPd0pqJ1rYh-U7ZDoHfzPsGLkBiB6qKF3RX1dzeQH7aCYKnfX7cbTUd-Jx3ioAXlxhRNTu9izpIdu',
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Color(0x55000000),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xCC1E2230),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _stroke),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: _primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'INICIO',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '${distanceLabel.toUpperCase()} PARA O EMBARQUE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(
                value: 0.3,
                minHeight: 6,
                backgroundColor: Color(0xFF192235),
                valueColor: AlwaysStoppedAnimation<Color>(_primary),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _stroke),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _primary, width: 2),
                          color: const Color(0xFF1B2030),
                          image: _passengerPhotoDecoration(),
                        ),
                        child:
                            ride.passengerPhotoUrl == null
                                ? const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 34,
                                )
                                : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              passengerLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: _primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  passengerMeta,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: _primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LOCAL DE EMBARQUE',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              origin,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.straight_rounded,
                    label: 'Distância',
                    value: distanceLabel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.schedule_rounded,
                    label: 'Chegada em',
                    value: etaLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickActionChip(label: 'Já cheguei', onTap: () {}),
                _QuickActionChip(label: 'Trânsito intenso', onTap: () {}),
                _QuickActionChip(label: 'Onde você está?', onTap: () {}),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: () => _openAcceptedNavigation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text(
                  'INICIAR NAVEGAÇÃO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BottomActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Mensagem',
                    onTap: () => _openSms(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BottomActionButton(
                    icon: Icons.call_rounded,
                    label: 'Ligar',
                    onTap: () => _callPassenger(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DestinationPanel(destination: destination),
            const SizedBox(height: 14),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _showArrivalBottomSheet(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _panelSoft,
                  side: const BorderSide(color: Color(0xFF334155)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'CHEGUEI',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DecorationImage? _passengerPhotoDecoration() {
    final url = ride.passengerPhotoUrl;
    if (url == null || url.trim().isEmpty) return null;
    return DecorationImage(image: NetworkImage(url), fit: BoxFit.cover);
  }

  Future<void> _callPassenger(BuildContext context) async {
    if (ride.passengerPhone.trim().isEmpty) {
      _showMessage(context, 'Telefone do passageiro indisponivel.');
      return;
    }

    final phoneUri = Uri.parse('tel:${ride.passengerPhone}');
    if (!await launchUrl(phoneUri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      _showMessage(context, 'Nao foi possivel iniciar a ligacao.');
    }
  }

  Future<void> _openSms(BuildContext context) async {
    if (ride.passengerPhone.trim().isEmpty) {
      _showMessage(context, 'Chat indisponivel para esta corrida.');
      return;
    }

    final smsUri = Uri.parse('sms:${ride.passengerPhone}');
    if (!await launchUrl(smsUri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      _showMessage(context, 'Nao foi possivel abrir a mensagem.');
    }
  }

  Future<void> _showArrivalBottomSheet(BuildContext context) async {
    final canProceed = await _markRideArrived(context);
    if (!canProceed || !context.mounted) return;

    final parentContext = context;

    final passengerLabel =
        ride.passengerName.trim().isNotEmpty
            ? ride.passengerName
            : 'Passageiro';
    final ratingLabel =
        ride.passengerRating != null
            ? ride.passengerRating!.toStringAsFixed(1)
            : '--';
    final distanceLabel =
        '${ride.distanceKm.toStringAsFixed(1).replaceAll('.', ',')}km de distancia';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.82,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Voce chegou ao local',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 4,
                            children: const [
                              Text(
                                'Aguardando o passageiro...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '02:45',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0x14FFFFFF),
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, cardConstraints) {
                                final compact = cardConstraints.maxWidth < 320;
                                return compact
                                    ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            _PassengerAvatar(
                                              image:
                                                  _passengerPhotoDecoration(),
                                              showFallback:
                                                  ride.passengerPhotoUrl ==
                                                  null,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: _PassengerInfo(
                                                passengerLabel: passengerLabel,
                                                ratingLabel: ratingLabel,
                                                distanceLabel: distanceLabel,
                                                compact: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: _ChatButton(
                                            onTap: () => _openSms(sheetContext),
                                          ),
                                        ),
                                      ],
                                    )
                                    : Row(
                                      children: [
                                        _PassengerAvatar(
                                          image: _passengerPhotoDecoration(),
                                          showFallback:
                                              ride.passengerPhotoUrl == null,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _PassengerInfo(
                                            passengerLabel: passengerLabel,
                                            ratingLabel: ratingLabel,
                                            distanceLabel: distanceLabel,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _ChatButton(
                                          onTap: () => _openSms(sheetContext),
                                        ),
                                      ],
                                    );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(sheetContext).pop();
                                await _startRide(parentContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'INICIAR CORRIDA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _confirmCancelRide(context);
                            },
                            child: const Text(
                              'Cancelar Viagem',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  Future<void> _openAcceptedNavigation(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => _AcceptedRideNavigationScreen(
              ride: ride,
              onArrived: _showArrivalBottomSheet,
              onMessage: _openSms,
            ),
      ),
    );
  }

  Future<void> _startRide(BuildContext context) async {
    try {
      await _dashboardApi.startRide(ride.id);

      if (!context.mounted) return;

      final ongoingRide = ride.copyWith(
        status: 'ongoing',
        etaMin: ride.etaMin > 0 ? ride.etaMin : 4,
        arrivedAt: ride.arrivedAt ?? DateTime.now(),
        pickedUpAt: DateTime.now(),
      );
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DashboardActiveRideScreen(ride: ongoingRide),
        ),
      );
    } on DashboardApiException catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.message);
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, 'Nao foi possivel iniciar a corrida.');
    }
  }

  Future<bool> _markRideArrived(BuildContext context) async {
    try {
      await _dashboardApi.markRideArrived(ride.id);
      return true;
    } on DashboardApiException catch (error) {
      if (!context.mounted) return false;
      _showMessage(context, error.message);
      return false;
    } catch (_) {
      if (!context.mounted) return false;
      _showMessage(context, 'Nao foi possivel marcar a chegada.');
      return false;
    }
  }

  Future<void> _confirmCancelRide(BuildContext context) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: _panel,
            title: const Text(
              'Cancelar viagem?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'Tem certeza que deseja cancelar esta viagem e voltar para a home?',
              style: TextStyle(color: _muted, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  'Nao',
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Sim, cancelar',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
    );

    if (shouldCancel != true || !context.mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirmFinishRide(BuildContext context) async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: _panel,
            title: const Text(
              'Finalizar corrida?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'Confirme se o passageiro ja chegou ao destino final para encerrar esta corrida.',
              style: TextStyle(color: _muted, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  'Agora nao',
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Finalizar',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
    );

    if (shouldFinish != true || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DashboardRideSummaryScreen(ride: ride),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
}

class _AcceptedRideNavigationScreen extends StatefulWidget {
  const _AcceptedRideNavigationScreen({
    required this.ride,
    required this.onArrived,
    required this.onMessage,
  });

  final RideCardItem ride;
  final Future<void> Function(BuildContext context) onArrived;
  final Future<void> Function(BuildContext context) onMessage;

  @override
  State<_AcceptedRideNavigationScreen> createState() =>
      _AcceptedRideNavigationScreenState();
}

class _AcceptedRideNavigationScreenState
    extends State<_AcceptedRideNavigationScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _driverPosition;

  RideCardItem get ride => widget.ride;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrentPosition());
  }

  Future<void> _loadCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (!mounted) return;
      setState(() {
        _driverPosition = LatLng(position.latitude, position.longitude);
      });
      await _fitRouteBounds();
    } catch (_) {}
  }

  LatLng? get _pickupPoint {
    final lat = ride.pickupLat;
    final lng = ride.pickupLng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  CameraPosition get _initialCameraPosition {
    if (_pickupPoint != null) {
      return CameraPosition(target: _pickupPoint!, zoom: 15.8);
    }
    if (_driverPosition != null) {
      return CameraPosition(target: _driverPosition!, zoom: 15.0);
    }
    return const CameraPosition(
      target: LatLng(-23.55052, -46.633308),
      zoom: 11.5,
    );
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    if (_pickupPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupPoint!,
          infoWindow: InfoWindow(
            title: 'Embarque',
            snippet: ride.pickupAddress,
          ),
        ),
      );
    }
    if (_driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          infoWindow: const InfoWindow(title: 'Sua localização'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> get _polylines {
    if (_driverPosition == null || _pickupPoint == null) {
      return const <Polyline>{};
    }

    return {
      Polyline(
        polylineId: const PolylineId('driver_to_pickup'),
        points: [_driverPosition!, _pickupPoint!],
        width: 6,
        color: DashboardActiveRideScreen._primary,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Future<void> _fitRouteBounds() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;

    if (_driverPosition != null && _pickupPoint != null) {
      final southwest = LatLng(
        _driverPosition!.latitude < _pickupPoint!.latitude
            ? _driverPosition!.latitude
            : _pickupPoint!.latitude,
        _driverPosition!.longitude < _pickupPoint!.longitude
            ? _driverPosition!.longitude
            : _pickupPoint!.longitude,
      );
      final northeast = LatLng(
        _driverPosition!.latitude > _pickupPoint!.latitude
            ? _driverPosition!.latitude
            : _pickupPoint!.latitude,
        _driverPosition!.longitude > _pickupPoint!.longitude
            ? _driverPosition!.longitude
            : _pickupPoint!.longitude,
      );
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: southwest, northeast: northeast),
          88,
        ),
      );
      return;
    }

    if (_pickupPoint != null) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _pickupPoint!, zoom: 15.8),
        ),
      );
    }
  }

  Future<void> _zoomIn() async {
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    final passengerLabel =
        ride.passengerName.trim().isNotEmpty
            ? ride.passengerName
            : 'Passageiro';
    final etaLabel = ride.etaMin > 0 ? '${ride.etaMin} min' : '--';
    final distanceLabel =
        '${ride.distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
    final pickupAddress =
        ride.pickupAddress.trim().isNotEmpty
            ? ride.pickupAddress
            : ride.route.split('->').first.trim();
    final subtitle =
        pickupAddress.isNotEmpty ? pickupAddress : 'Siga para o embarque';
    final ratingLabel =
        ride.passengerRating != null
            ? ride.passengerRating!.toStringAsFixed(1)
            : '--';

    final navButtonsBottomPadding = min(
      100.0,
      MediaQuery.of(context).size.height * 0.12,
    );

    return Scaffold(
      backgroundColor: DashboardActiveRideScreen._bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationEnabled: _driverPosition != null,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
                unawaited(_fitRouteBounds());
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top:
                MediaQuery.of(context).size.height *
                0.35, // Centralizado na lateral direita
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavFloatingButton(icon: Icons.add, onTap: _zoomIn),
                const SizedBox(height: 14),
                _NavFloatingButton(icon: Icons.remove, onTap: _zoomOut),
                const SizedBox(height: 14),
                _NavFloatingButton(
                  icon: Icons.navigation_rounded,
                  highlighted: true,
                  onTap: _fitRouteBounds,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xD9D64545),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Container(
                    height: 116,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xEE1A2236),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: DashboardActiveRideScreen._primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.turn_left_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Siga para o embarque',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: DashboardActiveRideScreen._muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xEE1A2236),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.32),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: DashboardActiveRideScreen._primary,
                                  width: 2,
                                ),
                                color: const Color(0xFF1B2030),
                                image: _passengerPhotoDecoration(),
                              ),
                              child:
                                  ride.passengerPhotoUrl == null
                                      ? const Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    passengerLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$ratingLabel • Passageiro VIP',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color:
                                              DashboardActiveRideScreen._muted,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  etaLabel,
                                  style: const TextStyle(
                                    color: DashboardActiveRideScreen._primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  distanceLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 68,
                                child: ElevatedButton.icon(
                                  onPressed: () => widget.onArrived(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        DashboardActiveRideScreen._primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.check_circle_rounded,
                                    size: 28,
                                  ),
                                  label: const Text(
                                    'CHEGUEI',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 82,
                              height: 68,
                              child: OutlinedButton(
                                onPressed: () => widget.onMessage(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF1E2940),
                                  side: const BorderSide(
                                    color: Color(0xFF334155),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_rounded,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DecorationImage? _passengerPhotoDecoration() {
    final url = ride.passengerPhotoUrl;
    if (url == null || url.trim().isEmpty) return null;
    return DecorationImage(image: NetworkImage(url), fit: BoxFit.cover);
  }
}

class _OngoingRideNavigationScreen extends StatefulWidget {
  const _OngoingRideNavigationScreen({
    required this.ride,
    required this.onFinishRide,
    required this.onMessage,
  });

  final RideCardItem ride;
  final Future<void> Function(BuildContext context) onFinishRide;
  final Future<void> Function(BuildContext context) onMessage;

  @override
  State<_OngoingRideNavigationScreen> createState() =>
      _OngoingRideNavigationScreenState();
}

class _OngoingRideNavigationScreenState
    extends State<_OngoingRideNavigationScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _driverPosition;

  RideCardItem get ride => widget.ride;

  LatLng? get _pickupPoint {
    final lat = ride.pickupLat;
    final lng = ride.pickupLng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? get _dropoffPoint {
    final lat = ride.dropoffLat;
    final lng = ride.dropoffLng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  CameraPosition get _initialCameraPosition {
    if (_dropoffPoint != null) {
      return CameraPosition(target: _dropoffPoint!, zoom: 14.8);
    }
    if (_pickupPoint != null) {
      return CameraPosition(target: _pickupPoint!, zoom: 14.8);
    }
    return const CameraPosition(
      target: LatLng(-23.55052, -46.633308),
      zoom: 11.5,
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_startLiveLocation());
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLiveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (!mounted) return;
      setState(() {
        _driverPosition = LatLng(current.latitude, current.longitude);
      });
      await _fitActiveBounds();

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      ).listen((position) {
        if (!mounted) return;
        setState(() {
          _driverPosition = LatLng(position.latitude, position.longitude);
        });
      });
    } catch (_) {}
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    if (_pickupPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupPoint!,
          infoWindow: InfoWindow(
            title: 'Origem do passageiro',
            snippet: ride.pickupAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ),
      );
    }
    if (_dropoffPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoffPoint!,
          infoWindow: InfoWindow(
            title: 'Destino final',
            snippet: ride.dropoffAddress,
          ),
        ),
      );
    }
    if (_driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_live'),
          position: _driverPosition!,
          infoWindow: const InfoWindow(title: 'Sua localização'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          rotation: 0,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> get _polylines {
    final polylines = <Polyline>{};
    if (_pickupPoint != null && _dropoffPoint != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ride_route'),
          points: [_pickupPoint!, _dropoffPoint!],
          width: 6,
          color: DashboardActiveRideScreen._primary,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    if (_driverPosition != null && _dropoffPoint != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('driver_progress'),
          points: [_driverPosition!, _dropoffPoint!],
          width: 4,
          color: const Color(0xFF38BDF8),
          patterns: [PatternItem.dash(18), PatternItem.gap(10)],
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    return polylines;
  }

  Future<void> _fitActiveBounds() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    final points = <LatLng>[
      if (_pickupPoint != null) _pickupPoint!,
      if (_dropoffPoint != null) _dropoffPoint!,
      if (_driverPosition != null) _driverPosition!,
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 15.5),
        ),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        92,
      ),
    );
  }

  Future<void> _zoomIn() async {
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    final destination =
        ride.dropoffAddress.trim().isNotEmpty
            ? ride.dropoffAddress
            : ride.route.split('->').last.trim();
    final passengerLabel =
        ride.passengerName.trim().isNotEmpty
            ? ride.passengerName
            : 'Passageiro';
    final etaLabel = ride.etaMin > 0 ? '${ride.etaMin} min' : '--';
    final passengerRating =
        ride.passengerRating != null
            ? '${ride.passengerRating!.toStringAsFixed(1)} ★'
            : 'Sem nota';

    return Scaffold(
      backgroundColor: DashboardActiveRideScreen._bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationEnabled: _driverPosition != null,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (controller) {
                  if (!_mapController.isCompleted) {
                    _mapController.complete(controller);
                  }
                  unawaited(_fitActiveBounds());
                },
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Canal SOS em configuracao.'),
                      ),
                    );
                },
                icon: const Icon(Icons.sos_rounded, color: Colors.white),
                label: const Text(
                  'SOS',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5E5E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.18,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1424),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: DashboardActiveRideScreen._primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.turn_left_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vire à esquerda em',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: DashboardActiveRideScreen._muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF172035),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          etaLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top:
                  MediaQuery.of(context).size.height *
                  0.35, // Já estava centralizado
              child: Column(
                children: [
                  _MapControlButton(icon: Icons.add, onTap: _zoomIn),
                  const SizedBox(height: 12),
                  _MapControlButton(icon: Icons.remove, onTap: _zoomOut),
                  const SizedBox(height: 12),
                  _MapControlButton(
                    icon: Icons.navigation_rounded,
                    onTap: _fitActiveBounds,
                    primary: true,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 110,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DashboardActiveRideScreen._primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0C0F18),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x22FFFFFF)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.55,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF475569),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            DashboardActiveRideScreen._primary,
                                        width: 2,
                                      ),
                                      color: const Color(0xFF1B2030),
                                      image: _passengerDecoration(ride),
                                    ),
                                    child:
                                        ride.passengerPhotoUrl == null
                                            ? const Icon(
                                              Icons.person_rounded,
                                              color: Colors.white,
                                              size: 32,
                                            )
                                            : null,
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            DashboardActiveRideScreen._primary,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        passengerRating,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      passengerLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          passengerRating,
                                          style: const TextStyle(
                                            color: Color(0xFFE2E8F0),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          ride.isPassenger
                                              ? 'Passageiro VIP'
                                              : 'Corrida',
                                          style: const TextStyle(
                                            color:
                                                DashboardActiveRideScreen
                                                    ._muted,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        () => widget.onFinishRide(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          DashboardActiveRideScreen._primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(Icons.flag_rounded),
                                    label: const Text(
                                      'FINALIZAR',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 52,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: () => widget.onMessage(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF141A28),
                                    side: const BorderSide(
                                      color: Color(0xFF334155),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  DecorationImage? _passengerDecoration(RideCardItem ride) {
    final url = ride.passengerPhotoUrl;
    if (url == null || url.trim().isEmpty) return null;
    return DecorationImage(image: NetworkImage(url), fit: BoxFit.cover);
  }
}

class _NavFloatingButton extends StatelessWidget {
  const _NavFloatingButton({
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final buttonSize = min(60.0, MediaQuery.of(context).size.width * 0.15);
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              highlighted
                  ? DashboardActiveRideScreen._primary
                  : const Color(0xEE1A2236),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              highlighted ? buttonSize * 0.33 : buttonSize * 0.3,
            ),
          ),
        ),
        child: Icon(icon, size: buttonSize * 0.53),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? DashboardActiveRideScreen._primary : const Color(0xFF7C8AA5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _PassengerAvatar extends StatelessWidget {
  const _PassengerAvatar({required this.image, required this.showFallback});

  final DecorationImage? image;
  final bool showFallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DashboardActiveRideScreen._primary, width: 2),
        color: const Color(0xFF1B2030),
        image: image,
      ),
      child:
          showFallback
              ? const Icon(Icons.person_rounded, color: Colors.white, size: 32)
              : null,
    );
  }
}

class _PassengerInfo extends StatelessWidget {
  const _PassengerInfo({
    required this.passengerLabel,
    required this.ratingLabel,
    required this.distanceLabel,
    this.compact = false,
  });

  final String passengerLabel;
  final String ratingLabel;
  final String distanceLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          passengerLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        if (compact)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              Text(
                ratingLabel,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                '•',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                distanceLabel,
                style: const TextStyle(
                  color: DashboardActiveRideScreen._muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                ratingLabel,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '•',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  distanceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardActiveRideScreen._muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: DashboardActiveRideScreen._primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(
          Icons.chat_rounded,
          color: DashboardActiveRideScreen._primary,
          size: 24,
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final Future<void> Function() onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          primary
              ? DashboardActiveRideScreen._primary
              : const Color(0xF21A2233),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => unawaited(onTap()),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DashboardActiveRideScreen._panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DashboardActiveRideScreen._stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DashboardActiveRideScreen._muted, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: DashboardActiveRideScreen._muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DashboardActiveRideScreen._panelSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: DashboardActiveRideScreen._panelSoft,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF334155)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _DestinationPanel extends StatelessWidget {
  const _DestinationPanel({required this.destination});

  final String destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF202430)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.flag_rounded,
            color: DashboardActiveRideScreen._primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESTINO',
                  style: TextStyle(
                    color: DashboardActiveRideScreen._muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
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
    );
  }
}
