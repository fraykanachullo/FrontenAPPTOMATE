import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomate_detection_app/features/plots/domain/entities/plot_entity.dart';
import 'package:tomate_detection_app/core/constants/app_constants.dart';

class AnalyticsCharts extends StatelessWidget {
  final List<DiagnosticSummary> diagnostics;
  final Map<String, Color> classColors;
  final Map<String, String> classNames;

  const AnalyticsCharts({
    super.key,
    required this.diagnostics,
    required this.classColors,
    required this.classNames,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppColors.primaryEmerald,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Tendencia de Salud',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          diagnostics.isEmpty ? _buildEmptyChart() : _buildTemporalChart(),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Datos insuficientes para gráfico',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemporalChart() {
    final items = diagnostics.take(7).toList();
    return SizedBox(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final diag = items[index];
          final isHealthy = diag.isHealthy;
          final height = isHealthy ? 90.0 : 45.0;
          final color = isHealthy ? Colors.green.shade500 : Colors.red.shade400;
          final displayName = classNames[diag.disease] ?? diag.disease;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isHealthy)
                Text(
                  '⚠️',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: color,
                  ),
                ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 28,
                height: height.clamp(10.0, 150.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.4), color],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayName.length > 6 ? displayName.substring(0, 6) : displayName,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}