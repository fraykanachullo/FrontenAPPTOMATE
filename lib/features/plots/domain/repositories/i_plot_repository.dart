import 'package:tomate_detection_app/features/plots/domain/entities/plot_entity.dart';

/// Interfaz del repositorio de análisis
/// Define el contrato que debe implementar cualquier fuente de datos
abstract class IPlotRepository {
  /// Obtiene todos los datos de análisis agregados
  Future<AnalyticsData> getAnalyticsData();

  /// Obtiene el resumen de todas las parcelas
  Future<List<PlotSummary>> getPlotsSummary();

  /// Obtiene las alertas activas
  Future<List<AlertData>> getAlerts();
}