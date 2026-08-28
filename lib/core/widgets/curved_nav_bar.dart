import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tomate_detection_app/core/theme/theme_controller.dart';

// Barra inferior estilo "montaña" a pantalla completa (edge-to-edge):
// - Bordes rectos (sin radios en las esquinas).
// - La "montaña" sube más arriba y cubre la cámara por completo.
// - Se extiende hasta el fondo de la pantalla; la gesture bar del sistema usa
//   el color de la barra (sin franja blanca).
// Mantiene rutas/índices e iconos de cada opción.
class CurvedNavBar extends StatelessWidget {
  final int selectedIndex; // 0:Home, 1:Analítica, 2:Historial, 3:Perfil (FAB es cámara)
  final Function(int) onTap;
  final VoidCallback onCameraTap;
  const CurvedNavBar({super.key, required this.selectedIndex, required this.onTap, required this.onCameraTap});

  static const _barHeight = 65.0;
  static const _fabSize = 74.0;   // círculo de la cámara
  static const _iconSize = 36.0;  // icono cámara
  static const _mountainRise = 50.0; // la montaña sube más, cubre la cámara

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // La barra de navegación del sistema (gesture bar) toma el color de la barra
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: c.card,
      systemNavigationBarDividerColor: c.card,
      systemNavigationBarIconBrightness: c.highContrast ? Brightness.dark : Brightness.light,
    ));
    return SizedBox(
      height: _barHeight + 14, // margen inferior para la gesture bar
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sombra difusa suave bajo la silueta (tras la barra)
          Positioned(
            left: 0, right: 0, top: -_mountainRise + _barHeight, bottom: 0,
            child: CustomPaint(painter: _NavShadowPainter(mountainRise: _mountainRise)),
          ),
          // Barra + montaña (bordes rectos, contorno que pasa tras la cámara)
          Positioned(
            left: 0, right: 0, top: 0, bottom: 0,
            child: CustomPaint(
              painter: _NavBarPainter(
                color: c.card,
                borderColor: c.border,
                fabSize: _fabSize,
                mountainRise: _mountainRise,
              ),
            ),
          ),
          // Elementos de navegación sobre la barra (fuera de la zona de la montaña)
          Positioned(
            left: 0, right: 0, top: 0, bottom: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _item(c: c, icon: Icons.home_rounded, label: "Inicio", index: 0),
              _item(c: c, icon: Icons.bar_chart_rounded, label: "Analítica", index: 1),
              const SizedBox(width: _fabSize + 10), // hueco para la montaña/cámara
              _item(c: c, icon: Icons.history_rounded, label: "Historial", index: 2),
              _item(c: c, icon: Icons.person_rounded, label: "Perfil", index: 3),
            ]),
          ),
          // Cámara sentada sobre la cima de la montaña (la montaña la cubre)
          Positioned(
            top: -_mountainRise + 35,
            left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onCameraTap,
                child: Container(
                  width: _fabSize,
                  height: _fabSize,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.card, width: 4),
                    boxShadow: [
                      BoxShadow(color: c.primary.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: c.onPrimary, size: _iconSize),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item({required AppColors c, required IconData icon, required String label, required int index}) {
    final active = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? c.primary : c.textDim, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? c.primary : c.textDim)),
        ]),
      ),
    );
  }
}

// Dibuja la silueta recta de la barra con una "montaña" (curva convexa) en el
// centro que sube y pasa por detrás de la cámara, cubriéndola.
class _NavBarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double fabSize;
  final double mountainRise;
  _NavBarPainter({required this.color, required this.borderColor, required this.fabSize, required this.mountainRise});

  Path _barPath(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final notchR = fabSize * 0.66; // radio de la montaña (sube más, cubre la cámara)
    final rise = mountainRise;

    final path = Path()..moveTo(0, h);
    path.lineTo(0, 0);           // borde izquierdo recto (sin radio)
    path.lineTo(cx - notchR, 0); // top izquierdo recto hasta la montaña
    path.quadraticBezierTo(cx, -rise, cx + notchR, 0); // montaña convexa
    path.lineTo(w, 0);           // top derecho recto
    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _barPath(size);
    canvas.drawPath(path, Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 1.3);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _NavBarPainter old) =>
      old.color != color || old.borderColor != borderColor || old.fabSize != fabSize || old.mountainRise != mountainRise;
}

// Sombra difusa suave tras la silueta, mantiene el efecto de elevación.
class _NavShadowPainter extends CustomPainter {
  final double mountainRise;
  _NavShadowPainter({required this.mountainRise});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final notchR = 74.0 * 0.66;
    final path = Path()..moveTo(0, h);
    path.lineTo(0, 8);
    path.lineTo(cx - notchR, 8);
    path.quadraticBezierTo(cx, -mountainRise + 12, cx + notchR, 8);
    path.lineTo(w, 8);
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  @override
  bool shouldRepaint(covariant _NavShadowPainter old) => old.mountainRise != mountainRise;
}
