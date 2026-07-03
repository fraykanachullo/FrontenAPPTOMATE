import 'package:flutter/foundation.dart';
import 'package:tomate_detection_app/features/plots/domain/entities/plot_entity.dart';
import 'package:tomate_detection_app/features/plots/domain/repositories/i_plot_repository.dart';
import 'package:tomate_detection_app/features/plots/data/datasources/plot_local_datasource.dart';

/// Implementación del repositorio de análisis
/// Conecta la fuente de datos con la lógica de negocio
class PlotRepository implements IPlotRepository {
  final PlotLocalDataSource _dataSource = PlotLocalDataSource();

  @override
  Future<AnalyticsData> getAnalyticsData() async {
    try {
      // Obtener datos en paralelo
      final results = await Future.wait([
        _dataSource.getTotalDiagnostics(),
        _dataSource.getDiseaseCount(),
        _dataSource.getHealthyCount(),
        _dataSource.getDiseaseStats(),
        _dataSource.getAllDiagnostics(),
      ]);

      final totalDiagnostics = results[0] as int;
      final diseaseCount = results[1] as int;
      final healthyCount = results[2] as int;
      final diseaseStats = results[3] as Map<String, int>;
      final allDiagnostics = results[4] as List<Map<String, dynamic>>;

      // Convertir a resumen de diagnósticos
      final recentDiagnostics = allDiagnostics.take(7).map((diag) {
        return DiagnosticSummary(
          id: diag['diagnostic_id'] ?? '',
          disease: diag['disease'] ?? 'Desconocido',
          confidence: (diag['confidence'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.parse(diag['created_at'] ?? DateTime.now().toIso8601String()),
          parcel: diag['parcel'] ?? 'Parcela General',
          imagePath: diag['image_path'],
        );
      }).toList();

      // Generar alertas basadas en los datos
      final alerts = _generateAlerts(diseaseStats, totalDiagnostics);

      return AnalyticsData(
        totalDiagnostics: totalDiagnostics,
        diseaseCount: diseaseCount,
        healthyCount: healthyCount,
        diseaseStats: diseaseStats,
        recentDiagnostics: recentDiagnostics,
        alerts: alerts,
      );
    } catch (e) {
      debugPrint('❌ Error en getAnalyticsData: $e');
      return AnalyticsData(
        totalDiagnostics: 0,
        diseaseCount: 0,
        healthyCount: 0,
        diseaseStats: {},
        recentDiagnostics: [],
        alerts: [],
      );
    }
  }

  @override
  Future<List<PlotSummary>> getPlotsSummary() async {
    try {
      final plots = await _dataSource.getPlotsStats();
      return plots.map((plot) {
        return PlotSummary(
          id: plot.id,
          name: plot.name,
          sector: plot.sector ?? 'Sin sector',
          totalScans: plot.totalScans,
          healthyCount: plot.healthyCount,
          diseaseCount: plot.diseaseCount,
          diseases: plot.diseases,
          healthPercentage: plot.totalScans > 0
              ? (plot.healthyCount / plot.totalScans * 100)
              : 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error en getPlotsSummary: $e');
      return [];
    }
  }

  @override
  Future<List<AlertData>> getAlerts() async {
    try {
      final totalDiagnostics = await _dataSource.getTotalDiagnostics();
      final diseaseStats = await _dataSource.getDiseaseStats();
      return _generateAlerts(diseaseStats, totalDiagnostics);
    } catch (e) {
      debugPrint('❌ Error en getAlerts: $e');
      return [];
    }
  }

  /// Genera alertas automáticas basadas en los datos
  List<AlertData> _generateAlerts(Map<String, int> diseaseStats, int totalDiagnostics) {
    final alerts = <AlertData>[];
    final threshold = totalDiagnostics > 10 ? 5 : 3;

    // Alerta: Alta incidencia de Mildiu
    if ((diseaseStats['mildiu'] ?? 0) > threshold) {
      alerts.add(AlertData(
        title: '⚠️ Alerta: Alta Incidencia de Mildiu',
        description: 'Se ha detectado un aumento significativo de Mildiu Velloso. Se recomienda aplicar fungicida preventivo.',
        severity: 'alta',
        timestamp: DateTime.now(),
        disease: 'Mildiu Velloso',
        incidence: (diseaseStats['mildiu']! / totalDiagnostics * 100),
      ));
    }

    // Alerta: Mosca Blanca
    if ((diseaseStats['mosca_blanca'] ?? 0) > threshold - 1) {
      alerts.add(AlertData(
        title: '⚠️ Mosca Blanca Detectada',
        description: 'Se han detectado colonias de Mosca Blanca. Implementar control biológico con parasitoides.',
        severity: 'media',
        timestamp: DateTime.now(),
        disease: 'Mosca Blanca',
        incidence: (diseaseStats['mosca_blanca']! / totalDiagnostics * 100),
      ));
    }

    // Alerta: Oidio
    if ((diseaseStats['oidio'] ?? 0) > threshold - 1) {
      alerts.add(AlertData(
        title: '⚠️ Oidio Detectado',
        description: 'Se ha detectado Cenicilla en el cultivo. Aplicar fungicida específico para oidio.',
        severity: 'media',
        timestamp: DateTime.now(),
        disease: 'Oidio',
        incidence: (diseaseStats['oidio']! / totalDiagnostics * 100),
      ));
    }

    // Alerta: Polilla
    if ((diseaseStats['polilla'] ?? 0) > threshold - 1) {
      alerts.add(AlertData(
        title: '⚠️ Polilla del Tomate',
        description: 'Se ha detectado Tuta absoluta. Implementar trampas con feromonas y control biológico.',
        severity: 'media',
        timestamp: DateTime.now(),
        disease: 'Polilla del Tomate',
        incidence: (diseaseStats['polilla']! / totalDiagnostics * 100),
      ));
    }

    // Mensaje positivo si no hay alertas
    if (alerts.isEmpty && totalDiagnostics > 5) {
      alerts.add(AlertData(
        title: '✅ Buen Estado del Cultivo',
        description: 'El cultivo presenta un excelente estado de salud. Continúa con las buenas prácticas agrícolas.',
        severity: 'baja',
        timestamp: DateTime.now(),
        disease: 'Salud General',
        incidence: 0,
      ));
    }

    return alerts;
  }
}