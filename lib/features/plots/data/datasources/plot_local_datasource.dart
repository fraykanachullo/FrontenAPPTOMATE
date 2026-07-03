import 'package:flutter/foundation.dart';
import 'package:tomate_detection_app/core/services/database_service.dart';
import 'package:tomate_detection_app/features/plots/data/models/plot_model.dart';

/// Fuente de datos local (SQLite)
/// Responsable de obtener datos de la base de datos
class PlotLocalDataSource {
  final DatabaseService _dbService = DatabaseService();

  /// Obtiene todos los diagnósticos
  Future<List<Map<String, dynamic>>> getAllDiagnostics() async {
    try {
      return await _dbService.getAllDiagnostics();
    } catch (e) {
      debugPrint('❌ Error en getAllDiagnostics: $e');
      return [];
    }
  }

  /// Obtiene el total de diagnósticos
  Future<int> getTotalDiagnostics() async {
    try {
      return await _dbService.getTotalDiagnostics();
    } catch (e) {
      debugPrint('❌ Error en getTotalDiagnostics: $e');
      return 0;
    }
  }

  /// Obtiene el conteo de enfermedades
  Future<int> getDiseaseCount() async {
    try {
      return await _dbService.getDiseaseCount();
    } catch (e) {
      debugPrint('❌ Error en getDiseaseCount: $e');
      return 0;
    }
  }

  /// Obtiene el conteo de hojas sanas
  Future<int> getHealthyCount() async {
    try {
      return await _dbService.getHealthyCount();
    } catch (e) {
      debugPrint('❌ Error en getHealthyCount: $e');
      return 0;
    }
  }

  /// Obtiene estadísticas por enfermedad
  Future<Map<String, int>> getDiseaseStats() async {
    try {
      return await _dbService.getDiseaseStats();
    } catch (e) {
      debugPrint('❌ Error en getDiseaseStats: $e');
      return {};
    }
  }

  /// Obtiene diagnósticos con filtros
  Future<List<Map<String, dynamic>>> getDiagnostics({
    String? disease,
    String? search,
  }) async {
    try {
      return await _dbService.getDiagnostics(
        disease: disease,
        search: search,
      );
    } catch (e) {
      debugPrint('❌ Error en getDiagnostics: $e');
      return [];
    }
  }

  /// Obtiene estadísticas de parcelas (simulado)
  Future<List<PlotModel>> getPlotsStats() async {
    try {
      final allDiagnostics = await _dbService.getAllDiagnostics();
      
      // Simular 4 parcelas con datos
      final simulatedPlots = [
        PlotModel(
          id: '1',
          name: 'Parcela Norte',
          sector: 'Sector A',
          totalScans: allDiagnostics.length ~/ 3,
          healthyCount: allDiagnostics.where((d) => d['disease'] == 'sana').length ~/ 3,
          diseaseCount: allDiagnostics.where((d) => d['disease'] != 'sana').length ~/ 3,
          diseases: {
            'mildiu': 3,
            'mosca_blanca': 2,
            'oidio': 1,
          },
        ),
        PlotModel(
          id: '2',
          name: 'Parcela Sur',
          sector: 'Sector B',
          totalScans: allDiagnostics.length ~/ 3,
          healthyCount: allDiagnostics.where((d) => d['disease'] == 'sana').length ~/ 3,
          diseaseCount: allDiagnostics.where((d) => d['disease'] != 'sana').length ~/ 3,
          diseases: {
            'mildiu': 5,
            'polilla': 3,
          },
        ),
        PlotModel(
          id: '3',
          name: 'Parcela Este',
          sector: 'Sector C',
          totalScans: allDiagnostics.length ~/ 3,
          healthyCount: allDiagnostics.where((d) => d['disease'] == 'sana').length ~/ 3,
          diseaseCount: allDiagnostics.where((d) => d['disease'] != 'sana').length ~/ 3,
          diseases: {
            'oidio': 4,
            'mosca_blanca': 2,
          },
        ),
        PlotModel(
          id: '4',
          name: 'Parcela Oeste',
          sector: 'Sector D',
          totalScans: allDiagnostics.length - (allDiagnostics.length ~/ 3 * 3),
          healthyCount: allDiagnostics.where((d) => d['disease'] == 'sana').length - (allDiagnostics.where((d) => d['disease'] == 'sana').length ~/ 3 * 3),
          diseaseCount: allDiagnostics.where((d) => d['disease'] != 'sana').length - (allDiagnostics.where((d) => d['disease'] != 'sana').length ~/ 3 * 3),
          diseases: {
            'polilla': 2,
            'mildiu': 1,
          },
        ),
      ];
      
      return simulatedPlots;
    } catch (e) {
      debugPrint('❌ Error en getPlotsStats: $e');
      return [];
    }
  }
}