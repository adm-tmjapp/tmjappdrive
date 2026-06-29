import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../ride_history/data/ride_history_api.dart';
import '../../../ride_history/domain/ride_history_models.dart';
import '../../../wallet_pix/presentation/screens/wallet_earnings_screen.dart';
import '../../data/dashboard_api.dart';
import '../../domain/dashboard_models.dart';

// ==========================================
// TEMA E CONSTANTES
// ==========================================
class AppTheme {
  static const Color bgDark = Color(0xFF000000);
  static const Color panelDark = Color(0xFF0A0C10);
  static const Color panelElevated = Color(0xFF0F1115);
  static const Color primary = Color(0xFFC62F78);
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color strokeDark = Color(0xFF232328);

  static const double radius = 16.0;
}

// ==========================================
// TELA PRINCIPAL (ESTADO & AVALIAÇÃO)
// ==========================================
class DashboardRideSummaryScreen extends StatefulWidget {
  const DashboardRideSummaryScreen({super.key, required this.ride});

  final RideCardItem ride;

  @override
  State<DashboardRideSummaryScreen> createState() =>
      _DashboardRideSummaryScreenState();
}

class _DashboardRideSummaryScreenState
    extends State<DashboardRideSummaryScreen> {
  final DashboardApi _dashboardApi = DashboardApi();
  final RideHistoryApi _historyApi = RideHistoryApi();
  final TextEditingController _commentController = TextEditingController();

  RideHistoryDetail? _detail;
  bool _isLoading = true;
  bool _isCompletingRide = false;
  bool _showCompletedState = false;
  int _passengerRating = 4;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    try {
      final detail = await _historyApi.getHistoryDetail(widget.ride.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final passengerName =
        ride.passengerName.trim().isNotEmpty
            ? ride.passengerName
            : 'Passageiro';
    final earningsLabel = _currencyLabel(
      _detail?.netAmount ?? _priceAsDouble(),
    );
    final distanceLabel =
        '${(_detail?.distanceKm ?? ride.distanceKm).toStringAsFixed(1).replaceAll('.', ',')} km';
    final durationLabel = '${_detail?.durationMinutes ?? ride.etaMin} min';

    if (_showCompletedState) {
      return _CompletedRideScreen(
        earningsLabel: earningsLabel,
        onClose: _backToHome,
        onOpenStatement: _openStatement,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: AppTheme.textLight),
                  ),
                  const Expanded(
                    child: Text(
                      'Corrida Finalizada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: _RideRouteMap(ride: ride),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      const Text(
                        'VALOR TOTAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        earningsLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.location_on_outlined,
                              label: 'DISTÂNCIA',
                              value: distanceLabel,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.schedule_rounded,
                              label: 'TEMPO',
                              value: durationLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.panelElevated,
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                          border: Border.all(color: AppTheme.strokeDark),
                        ),
                        child: Column(
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                text: 'Como foi sua experiência com\n',
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: passengerName,
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const TextSpan(text: '?'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final filled = index < _passengerRating;
                                return IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _passengerRating = index + 1;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.star_rounded,
                                    color:
                                        filled
                                            ? AppTheme.primary
                                            : const Color(0xFF2A2A35),
                                    size: 38,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 20),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Comentário opcional',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _commentController,
                              maxLines: 3,
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Conte como foi o comportamento do passageiro...',
                                hintStyle: TextStyle(
                                  color: AppTheme.textMuted.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF141416),
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primary,
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCompletingRide ? null : _finishSummary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                  ),
                  child:
                      _isCompletingRide
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppTheme.textLight,
                            ),
                          )
                          : const Text(
                            'CONCLUIR',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
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

  double _priceAsDouble() {
    final cleaned =
        widget.ride.price
            .replaceAll('R\$', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')
            .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  String _currencyLabel(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _finishSummary() async {
    if (!mounted || _isCompletingRide) return;
    setState(() {
      _isCompletingRide = true;
    });

    try {
      await _dashboardApi.completeRide(widget.ride.id);
      if (!mounted) return;
      setState(() {
        _isCompletingRide = false;
        _showCompletedState = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCompletingRide = false;
      });
      _showMessage('Não foi possível concluir a corrida.');
    }
  }

  void _backToHome() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openStatement() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WalletEarningsScreen()),
      (route) => route.isFirst,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ==========================================
// TELA DE CONCLUÍDA (O LAYOUT DE SUCESSO)
// ==========================================
class _CompletedRideScreen extends StatelessWidget {
  const _CompletedRideScreen({
    required this.earningsLabel,
    required this.onClose,
    required this.onOpenStatement,
  });

  final String earningsLabel;
  final VoidCallback onClose;
  final VoidCallback onOpenStatement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: AppTheme.textLight),
                  ),
                  const Expanded(
                    child: Text(
                      'Conclusão',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Espaçador balanceando o ícone
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  const _CompletedHeader(),
                  const SizedBox(height: 32),
                  _MapSummaryCard(earningsLabel: earningsLabel),
                  const SizedBox(height: 16),
                  const _DailyGoalCard(),
                  const SizedBox(height: 32),
                  _PrimaryActionButton(
                    label: 'VOLTAR AO DASHBOARD',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: onClose,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: onOpenStatement,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textMuted,
                      ),
                      child: const Text(
                        'VER DETALHES DA FATURA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
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
}

// ==========================================
// WIDGETS COMPONENTIZADOS
// ==========================================

class _CompletedHeader extends StatelessWidget {
  const _CompletedHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.15),
              width: 4,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.primary,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Corrida Concluída!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textLight,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Você está online e pronto para novas\nchamadas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _MapSummaryCard extends StatelessWidget {
  const _MapSummaryCard({required this.earningsLabel});

  final String earningsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.panelElevated,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área do Mapa / Placeholder bege
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radius),
            ),
            child: Container(
              height: 160,
              width: double.infinity,
              color: const Color(0xFFEBE3D3), // Fundo bege baseado na imagem
              child: CustomPaint(painter: _MapPlaceholderPainter()),
            ),
          ),
          // Área de Informações de Ganhos
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RESUMO DA CORRIDA',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  earningsLabel,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(
                      Icons.payments_outlined,
                      color: AppTheme.textMuted,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ganhos da última viagem',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.panelDark,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Meta Diária',
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '80%',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Objetivo: R\$ 200,00',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.8,
              minHeight: 8,
              backgroundColor: Color(0xFF2A2A2E),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(
                Icons.stars_rounded, // Similar ao ícone de alvo com estrela
                color: AppTheme.primary,
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'Você atingiu 80% da sua meta diária',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
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
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 20),
                    ],
                  ],
                ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.panelElevated,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.strokeDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RideRouteMap extends StatelessWidget {
  const _RideRouteMap({required this.ride});

  final RideCardItem ride;

  LatLng get _fallback => const LatLng(-23.55052, -46.633308);

  LatLng _center() {
    final pickup = _pickup();
    final dropoff = _dropoff();
    if (pickup != null && dropoff != null) {
      return LatLng(
        (pickup.latitude + dropoff.latitude) / 2,
        (pickup.longitude + dropoff.longitude) / 2,
      );
    }
    return pickup ?? dropoff ?? _fallback;
  }

  LatLng? _pickup() {
    final lat = ride.pickupLat;
    final lng = ride.pickupLng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? _dropoff() {
    final lat = ride.dropoffLat;
    final lng = ride.dropoffLng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _pickup();
    final dropoff = _dropoff();
    final markers = <Marker>{
      if (pickup != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(title: ride.pickupAddress),
        ),
      if (dropoff != null)
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff,
          infoWindow: InfoWindow(title: ride.dropoffAddress),
        ),
    };

    final polylines = <Polyline>{
      if (pickup != null && dropoff != null)
        Polyline(
          polylineId: const PolylineId('route'),
          points: [pickup, dropoff],
          color: AppTheme.primary,
          width: 4,
        ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _center(), zoom: 13.5),
      zoomControlsEnabled: false,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      tiltGesturesEnabled: false,
      markers: markers,
      polylines: polylines,
    );
  }
}

// Pintor simples para reproduzir o fundo abstrato do mapa mostrado no Figma
class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final path = Path();

    // Desenhando linhas diagonais para emular ruas urbanas simplificadas
    for (double i = -size.height; i < size.width; i += 30) {
      path.moveTo(i, 0);
      path.lineTo(i + size.height, size.height);
    }
    for (double i = 0; i < size.width + size.height; i += 40) {
      path.moveTo(i, 0);
      path.lineTo(i - size.height, size.height);
    }

    // Desenha avenidas mais grossas
    final thickPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.8, size.height),
      thickPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, 0),
      Offset(size.width * 0.1, size.height),
      thickPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
