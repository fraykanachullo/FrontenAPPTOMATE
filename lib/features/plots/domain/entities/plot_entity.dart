import 'package:flutter/material.dart';

/// Entidad principal de análisis de datos
/// Contiene toda la información agregada del sistema
class AnalyticsData {
  final int totalDiagnostics;
  final int diseaseCount;
  final int healthyCount;
  final Map<String, int> diseaseStats;
  final List<DiagnosticSummary> recentDiagnostics;
  final List<AlertData> alerts;

  AnalyticsData({
    required this.totalDiagnostics,
    required this.diseaseCount,
    required this.healthyCount,
    required this.diseaseStats,
    required this.recentDiagnostics,
    required this.alerts,
  });

  /// Calcula el porcentaje de salud promedio
  double get healthPercentage {
    if (totalDiagnostics == 0) return 0;
    return (healthyCount / totalDiagnostics) * 100;
  }

  /// Obtiene la enfermedad más frecuente
  String get primaryDisease {
    if (diseaseStats.isEmpty) return 'Ninguna';
    
    final sorted = diseaseStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var entry in sorted) {
      if (entry.key != 'sana') {
        return entry.key;
      }
    }
    return 'Ninguna';
  }

  /// Obtiene el conteo de la enfermedad principal
  int get primaryDiseaseCount {
    final disease = primaryDisease;
    if (disease == 'Ninguna') return 0;
    return diseaseStats[disease] ?? 0;
  }
}

/// Resumen de un diagnóstico individual
class DiagnosticSummary {
  final String id;
  final String disease;
  final double confidence;
  final DateTime date;
  final String? parcel;
  final String? imagePath;

  DiagnosticSummary({
    required this.id,
    required this.disease,
    required this.confidence,
    required this.date,
    this.parcel,
    this.imagePath,
  });

  bool get isHealthy => disease == 'sana';
}

/// Datos de una alerta
class AlertData {
  final String title;
  final String description;
  final String severity; // 'alta', 'media', 'baja'
  final DateTime timestamp;
  final String disease;
  final double incidence;

  AlertData({
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.disease,
    required this.incidence,
  });

  Color get severityColor {
    switch (severity) {
      case 'alta':
        return const Color(0xFFE53935);
      case 'media':
        return const Color(0xFFFFA726);
      case 'baja':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case 'alta':
        return Icons.warning_rounded;
      case 'media':
        return Icons.info_rounded;
      case 'baja':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}

/// Resumen de una parcela
class PlotSummary {
  final String id;
  final String name;
  final String sector;
  final int totalScans;
  final int healthyCount;
  final int diseaseCount;
  final Map<String, int> diseases;
  final double healthPercentage;

  PlotSummary({
    required this.id,
    required this.name,
    required this.sector,
    required this.totalScans,
    required this.healthyCount,
    required this.diseaseCount,
    required this.diseases,
    required this.healthPercentage,
  });

  /// Obtiene la enfermedad más frecuente en esta parcela
  String get primaryDisease {
    if (diseases.isEmpty) return 'Ninguna';
    
    final sorted = diseases.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.first.key;
  }
}