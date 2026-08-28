import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Stitch: bg-gradient-to-b from-[#0F4C3A] to-[#121212], card bg-surface/10 border white/10
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0F4C3A), Color(0xFF121212)],
          ),
        ),
        child: Stack(children: [
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: Offset(0, 8))],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF78DC77).withValues(alpha: 0.18), shape: BoxShape.circle),
                      child: const Icon(Icons.eco_rounded, color: Color(0xFF78DC77), size: 64),
                    ),
                    const SizedBox(height: 20),
                    Text("AgriScan Pro", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF78DC77), letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text("Precision Agriculture", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFBECAB9), letterSpacing: 0.2)),
                    const SizedBox(height: 28),
                    const LoadingDots(),
                  ]),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 24,
            child: Center(child: Text("Versión 1.0.0", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFBECAB9).withValues(alpha: 0.6), letterSpacing: 0.5))),
          ),
        ]),
      ),
    );
  }
}

class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});
  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) {
      return AnimatedBuilder(animation: _c, builder: (_,__) {
        final t = (_c.value + i * 0.2) % 1.0;
        final scale = (1 - (t - 0.5).abs() * 1.2).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12, height: 12,
          decoration: BoxDecoration(color: const Color(0xFF78DC77).withValues(alpha: 0.6 + scale * 0.4), shape: BoxShape.circle),
          transform: Matrix4.identity()..scale(0.7 + scale * 0.3),
        );
      });
    }));
  }
}
