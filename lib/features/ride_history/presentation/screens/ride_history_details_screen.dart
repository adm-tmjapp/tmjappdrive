import 'package:flutter/material.dart';

import '../../domain/ride_history_models.dart';
import 'ride_history_help_screen.dart';

class RideHistoryDetailsScreen extends StatelessWidget {
  const RideHistoryDetailsScreen({super.key, required this.ride});

  final RideHistoryItem ride;

  static const Color _bg = Color(0xFF000000);
  static const Color _panel = Color(0xFF0B0B0D);
  static const Color _stroke = Color(0xFF232328);
  static const Color _primary = Color(0xFFC62F78);

  @override
  Widget build(BuildContext context) {
    final durationMinutes = ride.duration.inMinutes;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            LayoutBuilder(
              builder: (context, _) {
                return Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28, // Reduzido ligeiramente para harmonizar
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment(-0.2, 0.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Detalhes',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '#${ride.id}',
                                style: const TextStyle(
                                  color: _primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _MapPanel(ride: ride),
            const SizedBox(height: 24),
            const Text(
              'Resumo da Viagem',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _DetailSection(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 320;
                  return compact
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TimeIconCard(),
                          const SizedBox(height: 16),
                          _TripMetaBlock(
                            dayLabel: _dayLabel(ride.startedAt),
                            startTime: _timeLabel(ride.startedAt),
                            endTime: _timeLabel(ride.endedAt),
                            durationMinutes: durationMinutes,
                            distanceKm: ride.distanceKm,
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          _TimeIconCard(),
                          const SizedBox(width: 16), // Espaçamento ajustado
                          Expanded(
                            child: _TripMetaBlock(
                              dayLabel: _dayLabel(ride.startedAt),
                              startTime: _timeLabel(ride.startedAt),
                              endTime: _timeLabel(ride.endedAt),
                              durationMinutes: durationMinutes,
                              distanceKm: ride.distanceKm,
                            ),
                          ),
                        ],
                      );
                },
              ),
            ),
            const SizedBox(height: 14),
            _DetailSection(
              child: Column(
                children: [
                  _AddressRow(
                    iconBg: const Color(0xFF2A0B24),
                    iconColor: _primary,
                    label: 'ORIGEM',
                    value: ride.origin,
                    showConnector: true,
                  ),
                  const SizedBox(
                    height: 4,
                  ), // Reduzido pois o connector ocupa espaço
                  _AddressRow(
                    iconBg: const Color(0xFF222222),
                    iconColor: const Color(0xFF94A3B8), // Corrigido para cinza
                    label: 'DESTINO',
                    value: ride.destination,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DetailSection(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GANHOS DA VIAGEM',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14, // Reduzido para proporção de overline
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AmountLine(
                    label: 'Valor Bruto',
                    value: _currency(ride.grossAmount),
                    valueColor: Colors.white,
                  ),
                  const SizedBox(height: 14),
                  _AmountLine(
                    label: 'Taxa App TMJ',
                    value: '- ${_currency(ride.appFee)}',
                    valueColor: const Color(0xFFFF5E5E),
                  ),
                  const Divider(height: 32, color: Color(0xFF232328)),
                  _AmountLine(
                    label: 'Ganhos Líquidos',
                    value: _currency(ride.netAmount),
                    valueColor: _primary,
                    emphasize: true,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416), // Ajustado para contraste
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ride.paymentMethod.toUpperCase().contains('DINHEIRO')
                              ? Icons.attach_money_rounded
                              : Icons.credit_card_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ride.paymentMethod,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
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
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RideHistoryHelpScreen(rideId: ride.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A), // Mais escuro
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.help_outline_rounded, size: 22),
                label: const Text(
                  'Preciso de Ajuda com esta corrida',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'TMJ Drive - Driver App v4.2.0',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final target = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (target == today) return 'Hoje';
    if (target == yesterday) return 'Ontem';
    return '${_two(date.day)}/${_two(date.month)}/${date.year}';
  }

  static String _timeLabel(DateTime date) {
    return '${_two(date.hour)}:${_two(date.minute)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _currency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.ride});

  final RideHistoryItem ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200, // Altura reduzida para melhor proporção
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFF1F5F9), Color(0xFFD7DEE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(painter: _MapPainter()),
            ),
          ),
          Positioned(
            left: 14,
            top: 16,
            child: _MapPin(
              label: 'A',
              color: RideHistoryDetailsScreen._primary,
            ),
          ),
          Positioned(
            right: 18,
            bottom: 22,
            child: _MapPin(
              label: 'B',
              color: Colors.white,
              textColor: RideHistoryDetailsScreen._primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road =
        Paint()
          ..color = const Color(0xFF94A3B8)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;
    final minorRoad =
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final mainPath =
        Path()
          ..moveTo(0, size.height * 0.2)
          ..quadraticBezierTo(
            size.width * 0.25,
            size.height * 0.1,
            size.width * 0.42,
            size.height * 0.3,
          )
          ..quadraticBezierTo(
            size.width * 0.55,
            size.height * 0.45,
            size.width * 0.78,
            size.height * 0.36,
          )
          ..quadraticBezierTo(
            size.width * 0.9,
            size.height * 0.32,
            size.width,
            size.height * 0.14,
          );
    canvas.drawPath(mainPath, road);

    final secondaryPath =
        Path()
          ..moveTo(size.width * 0.18, 0)
          ..quadraticBezierTo(
            size.width * 0.22,
            size.height * 0.24,
            size.width * 0.2,
            size.height * 0.54,
          )
          ..quadraticBezierTo(
            size.width * 0.18,
            size.height * 0.78,
            size.width * 0.28,
            size.height,
          );
    canvas.drawPath(secondaryPath, road);

    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.14 + i * 0.14);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (i.isEven ? 16 : -12)),
        minorRoad,
      );
    }

    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.12 + i * 0.18);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + (i.isEven ? 18 : -12), size.height),
        minorRoad,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16), // Padding baseado no figma
      decoration: BoxDecoration(
        color: RideHistoryDetailsScreen._panel,
        borderRadius: BorderRadius.circular(16), // Radius fixo em 16
        border: Border.all(color: RideHistoryDetailsScreen._stroke),
      ),
      child: child,
    );
  }
}

class _TimeIconCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54, // Proporção mais quadrada e realística
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF2A0B24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.access_time_filled_rounded,
        color: RideHistoryDetailsScreen._primary,
        size: 26,
      ),
    );
  }
}

class _TripMetaBlock extends StatelessWidget {
  const _TripMetaBlock({
    required this.dayLabel,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.distanceKm,
  });

  final String dayLabel;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$dayLabel, $startTime - $endTime',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$durationMinutes min • ${distanceKm.toStringAsFixed(1)} km',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.showConnector = false,
  });

  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              // Custom Circle Icon
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (showConnector)
                Container(
                  width: 1.5,
                  height: 48, // Ajustado para não estourar o layout
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: const Color(0xFF232328),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12, // Menor e mais sutil
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.value,
    required this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 280;
        return compact
            ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: emphasize ? 18 : 15,
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: emphasize ? 24 : 15,
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            )
            : Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:
                          emphasize
                              ? 18
                              : 15, // Destaque extra no título líquido
                      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize:
                        emphasize ? 24 : 15, // Destaque extra no valor líquido
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            );
      },
    );
  }
}
