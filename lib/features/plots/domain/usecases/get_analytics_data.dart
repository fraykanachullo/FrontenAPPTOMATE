import 'package:flutter/foundation.dart';
import 'package:tomate_detection_app/features/plots/domain/entities/plot_entity.dart';
import 'package:tomate_detection_app/features/plots/domain/repositories/i_plot_repository.dart';

/// Caso de uso: Obtener datos de análisis
/// Encapsula la lógica de negocio para obtener estadísticas
class GetAnalyticsDataUseCase {
  final IPlotRepository repository;

  GetAnalyticsDataUseCase(this.repository);

  /// Ejecuta el caso de uso
  Future<AnalyticsData> execute() async {
    try {
      return await repository.getAnalyticsData();
    } catch (e) {
      debugPrint('❌ Error en GetAnalyticsDataUseCase: $e');
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
}

/// Caso de uso: Obtener resumen de parcelas
class GetPlotsSummaryUseCase {
  final IPlotRepository repository;

  GetPlotsSummaryUseCase(this.repository);

  Future<List<PlotSummary>> execute() async {
    try {
      return await repository.getPlotsSummary();
    } catch (e) {
      debugPrint('❌ Error en GetPlotsSummaryUseCase: $e');
      return [];
    }
  }
}

/// Caso de uso: Obtener alertas
class GetAlertsUseCase {
  final IPlotRepository repository;

  GetAlertsUseCase(this.repository);

  Future<List<AlertData>> execute() async {
    try {
      return await repository.getAlerts();
    } catch (e) {
      debugPrint('❌ Error en GetAlertsUseCase: $e');
      return [];
    }
  }
}