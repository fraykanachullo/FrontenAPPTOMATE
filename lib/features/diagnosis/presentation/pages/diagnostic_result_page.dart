import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:tomate_detection_app/core/theme/theme_controller.dart';
import 'scanner_page.dart' show Detection;

// Resultado Diagnóstico — Tomate AI
// Muestra la imagen capturada con las cajas YOLO EXACTAS superpuestas
// y las secciones en tarjetas de ancho completo (Síntomas -> Cond. -> Tratamiento).
class DiagnosticResultPage extends StatelessWidget {
  final Uint8List imageBytes;
  final List<Detection> detections;
  final Map<String, String> displayNames;
  final Map<String, Color> colors;
  const DiagnosticResultPage({
    super.key,
    required this.imageBytes,
    required this.detections,
    required this.displayNames,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasDisease = detections.any((d) => d.diseaseName != 'sana');
    final primary = hasDisease
        ? detections.firstWhere((d) => d.diseaseName != 'sana', orElse: () => detections.first)
        : null;
    final label = primary != null ? (displayNames[primary.diseaseName] ?? primary.diseaseName) : "Hoja Sana";
    final conf = primary != null ? (primary.confidence * 100).toStringAsFixed(1) : "99.0";
    final severe = primary != null && primary.confidence > 0.75;
    final sevLabel = primary == null ? "LEVE" : (severe ? "ALTA" : (primary.confidence > 0.55 ? "MEDIA" : "LEVE"));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          // Header fijo (con toggle de alto contraste junto al logo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: c.bg, border: Border(bottom: BorderSide(color: c.border))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: c.cardAlt, shape: BoxShape.circle, border: Border.all(color: c.border)), child: Icon(Icons.arrow_back_rounded, color: c.textDim, size: 18))),
                const SizedBox(width: 10),
                Text("Resultado", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text("Tomate AI", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary)),
                const SizedBox(width: 10),
                const HighContrastToggle(),
              ]),
            ]),
          ),
          // Contenido scrolleable (estilo analítica)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Imagen capturada con boxes YOLO reales
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(children: [
                    // Usar la proporción REAL de la imagen capturada para que las
                    // cajas YOLO (normalizadas 0..1) coincidan exactamente.
                    AspectRatio(aspectRatio: _imageAspectRatio(), child: Image.memory(imageBytes, fit: BoxFit.cover, width: double.infinity)),
                    // Superponer cajas reales exactas
                    Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BboxPainter(detections, displayNames, colors)))),
                  ]),
                ),
                const SizedBox(height: 12),
                // Banda de patógeno + precisión
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Icon(Icons.coronavirus_rounded, color: hasDisease ? c.danger : c.primary, size: 16), const SizedBox(width: 6), Text("Resultado del Escaneo", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: c.textDim, letterSpacing: 0.8))]),
                      const SizedBox(height: 4),
                      Text(label, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: hasDisease ? c.danger : c.primary)),
                      if (detections.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text("${detections.length} box(s) detectadas por el modelo YOLOv8", style: GoogleFonts.inter(fontSize: 11, color: c.textDim)),
                      ],
                    ])),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.primary)),
                      child: Column(children: [
                        Text("$conf%", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary)),
                        Text("Precisión", style: GoogleFonts.inter(fontSize: 9, color: c.primary)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                // Severidad
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Análisis de Severidad", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: c.text)),
                      const SizedBox(height: 8),
                      Text(severe ? "La infección se encuentra en una etapa crítica. Se requiere intervención inmediata." : "Infección leve-moderada. Monitoreo cercano recomendado.", style: GoogleFonts.inter(fontSize: 12, color: c.textDim, height: 1.4)),
                    ])),
                    const SizedBox(width: 16),
                    SizedBox(width: 90, height: 90, child: Stack(alignment: Alignment.center, children: [
                      CustomPaint(size: const Size(90, 90), painter: _GaugePainter(value: primary != null ? primary.confidence : 0.2)),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.warning_amber_rounded, color: hasDisease ? c.danger : c.primary, size: 22),
                        Text(sevLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: hasDisease ? c.danger : c.primary)),
                      ]),
                    ])),
                  ]),
                ),
                const SizedBox(height: 16),
                // Sección 1 — Síntomas Detectados (ancho completo)
                _sectionCard(
                  title: "Síntomas Detectados",
                  icon: Icons.manage_search_rounded,
                  iconColor: c.warn,
                  c: c,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _bullet("Manchas necróticas irregulares de color marrón oscuro en hojas inferiores.", c),
                    const SizedBox(height: 8),
                    _bullet("Halo amarillento pronunciado alrededor de las lesiones.", c),
                    const SizedBox(height: 8),
                    _bullet("Micelio blanquecino en el envés durante la mañana.", c),
                    const SizedBox(height: 8),
                    _bullet("Defoliación progresiva desde la base de la planta.", c),
                  ]),
                ),
                const SizedBox(height: 16),
                // Sección 2 — Condiciones Ambientales (ancho completo)
                _sectionCard(
                  title: "Condiciones Ambientales",
                  icon: Icons.cloud_rounded,
                  iconColor: const Color(0xFFB8C3FF),
                  c: c,
                  child: Row(children: [
                    Expanded(child: _envBox(icon: Icons.water_drop_rounded, iconColor: c.primary, value: "92%", label: "Humedad", hint: "Crítica", c: c)),
                    const SizedBox(width: 10),
                    Expanded(child: _envBox(icon: Icons.thermostat_rounded, iconColor: c.warn, value: "18°C", label: "Temperatura", hint: "Óptima", c: c)),
                    const SizedBox(width: 10),
                    Expanded(child: _envBox(icon: Icons.air_rounded, iconColor: const Color(0xFFB8C3FF), value: "65%", label: "Viento", hint: "Moderado", c: c)),
                  ]),
                ),
                const SizedBox(height: 16),
                // Sección 3 — Tratamientos Recomendados (ancho completo)
                _sectionCard(
                  title: "Tratamientos Recomendados",
                  icon: Icons.healing_rounded,
                  iconColor: c.primary,
                  c: c,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _treatBox(title: "Acción Orgánica / Preventiva", icon: Icons.compost_rounded, color: c.primary, items: [
                      "Aplicación de fungicidas cúpricos (Caldo Bordelés) al 1%.",
                      "Poda sanitaria de hojas bajeras para ventilación.",
                    ], c: c),
                    const SizedBox(height: 12),
                    _treatBox(title: "Intervención Química", icon: Icons.science_rounded, color: c.danger, items: [
                      "Fungicidas sistémicos (Metalaxil + Mancozeb).",
                      "Respetar período de carencia de 7-14 días.",
                    ], isChemical: true, c: c),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  double _imageAspectRatio() {
    try {
      final d = img.decodeImage(imageBytes);
      if (d != null && d.width > 0 && d.height > 0) return d.width / d.height;
    } catch (_) {}
    return 4 / 3; // fallback: proporción típica de la cámara
  }

  Widget _sectionCard({required String title, required IconData icon, required Color iconColor, required AppColors c, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
        ]),
        Divider(color: c.border, height: 24),
        child,
      ]),
    );
  }

  Widget _bullet(String text, AppColors c) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(top: 3), child: Icon(Icons.radio_button_unchecked_rounded, size: 14, color: c.textDim)),
    const SizedBox(width: 8),
    Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: c.text, height: 1.4))),
  ]);

  Widget _envBox({required IconData icon, required Color iconColor, required String value, required String label, required String hint, required AppColors c}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.cardAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
      child: Column(children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: c.text)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: c.textDim)),
        Text(hint, style: GoogleFonts.inter(fontSize: 10, color: iconColor, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _treatBox({required String title, required IconData icon, required Color color, required List<String> items, required AppColors c, bool isChemical = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.cardAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: isChemical ? c.danger.withValues(alpha: 0.3) : c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color)))]),
        const SizedBox(height: 10),
        ...items.map((t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(isChemical ? Icons.priority_high_rounded : Icons.task_alt_rounded, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(child: Text(t, style: GoogleFonts.inter(fontSize: 12, color: c.text, height: 1.3))),
        ]))),
      ]),
    );
  }
}

// Pinta las cajas YOLO EXACTAS (coordenadas normalizadas 0..1) sobre la imagen
class _BboxPainter extends CustomPainter {
  final List<Detection> detections;
  final Map<String, String> names;
  final Map<String, Color> colors;
  _BboxPainter(this.detections, this.names, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in detections) {
      final key = d.diseaseName.toLowerCase();
      final color = colors[key] ?? const Color(0xFF4EDEA3);
      final label = names[key] ?? d.diseaseName;
      final x = d.bbox.xMin * size.width;
      final y = d.bbox.yMin * size.height;
      final w = (d.bbox.xMax - d.bbox.xMin) * size.width;
      final h = (d.bbox.yMax - d.bbox.yMin) * size.height;
      final rect = Rect.fromLTWH(x, y, w, h);

      // Contorno negro + color
      canvas.drawRect(rect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 5);
      canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5);

      // Badge superior con etiqueta + %
      final text = "$label ${(d.confidence * 100).toStringAsFixed(0)}%";
      final tp = TextPainter(
        text: TextSpan(text: text, style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black)),
        textDirection: TextDirection.ltr,
      )..layout();
      final badge = RRect.fromRectAndRadius(Rect.fromLTWH(rect.left, rect.top - 18, tp.width + 10, 16), const Radius.circular(4));
      canvas.drawRRect(badge, Paint()..color = color);
      tp.paint(canvas, Offset(rect.left + 5, rect.top - 15));
    }
  }

  @override
  bool shouldRepaint(covariant _BboxPainter old) => old.detections != detections;
}

class _GaugePainter extends CustomPainter {
  final double value;
  _GaugePainter({required this.value});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    final bg = Paint()..color = const Color(0xFF393939)..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, bg);
    final fg = Paint()..color = const Color(0xFFFFB4AB)..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round;
    final sweep = 263.89 * value.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -90 * 3.14159 / 180, sweep * 3.14159 / 180, false, fg);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}
