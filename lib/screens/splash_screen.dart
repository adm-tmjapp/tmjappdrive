import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tmjappdrive/repository/auth_repository.dart';
import 'package:tmjappdrive/screens/auth/bloc/login_bloc.dart';
import 'package:tmjappdrive/screens/auth/sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..forward();
    _progress = Tween<double>(
      begin: 0.0,
      end: 0.65,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => BlocProvider(
                create: (_) => LoginBloc(authRepository: AuthRepository()),
                child: const SignInScreen(),
              ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          const Positioned(
            top: -60,
            left: -70,
            child: _GlowOrb(size: 220, color: _accentColor, alpha: 0.10),
          ),
          const Positioned(
            bottom: -70,
            right: -80,
            child: _GlowOrb(size: 240, color: _accentColor, alpha: 0.05),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const Spacer(),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _accentColor.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withValues(alpha: 0.20),
                              blurRadius: 30,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_accentColor, Color(0x66C62F78)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.electric_car_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2.0,
                            color: const Color(0xFFF8FAFC),
                          ),
                          children: const [
                            TextSpan(text: 'TMJ'),
                            TextSpan(
                              text: 'App',
                              style: TextStyle(color: _accentColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'DRIVER EDITION',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 3.2,
                          color: const Color(0x6694A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 92),
                  SizedBox(
                    width: 280,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedBuilder(
                            animation: _progress,
                            builder: (context, _) {
                              return LinearProgressIndicator(
                                value: _progress.value,
                                minHeight: 3,
                                backgroundColor: _accentColor.withValues(
                                  alpha: 0.20,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  _accentColor,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: _progress,
                          builder: (context, _) {
                            final percent = (_progress.value * 100).round();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SYSTEM INITIALIZING',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.6,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  '$percent%',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                    color: _accentColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        'Powered by TMJ Technology',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.6,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _FooterDot(),
                          SizedBox(width: 12),
                          _FooterDot(),
                          SizedBox(width: 12),
                          _FooterDot(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.alpha,
  });

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: alpha),
              blurRadius: 120,
              spreadRadius: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0x66C62F78),
        shape: BoxShape.circle,
      ),
    );
  }
}

const _backgroundColor = Color(0xFF000000);
const _accentColor = Color(0xFFC62F78);
