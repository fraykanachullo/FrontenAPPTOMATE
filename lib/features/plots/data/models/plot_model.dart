/// Modelo de datos para el análisis de diagnósticos
/// Convierte datos de SQLite a objetos Dart
class PlotModel {
  final String id;
  final String name;
  final String? sector;
  final double? latitude;
  final double? longitude;
  final int totalScans;
  final int healthyCount;
  final int diseaseCount;
  final Map<String, int> diseases;

  PlotModel({
    required this.id,
    required this.name,
    this.sector,
    this.latitude,
    this.longitude,
    required this.totalScans,
    required this.healthyCount,
    required this.diseaseCount,
    required this.diseases,
  });

  /// Convierte un mapa de SQLite a PlotModel
  factory PlotModel.fromJson(Map<String, dynamic> json) {
    return PlotModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Parcela',
      sector: json['sector'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      totalScans: json['totalScans'] ?? 0,
      healthyCount: json['healthyCount'] ?? 0,
      diseaseCount: json['diseaseCount'] ?? 0,
      diseases: Map<String, int>.from(json['diseases'] ?? {}),
    );
  }

  /// Convierte PlotModel a mapa para SQLite
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sector': sector,
      'latitude': latitude,
      'longitude': longitude,
      'totalScans': totalScans,
      'healthyCount': healthyCount,
      'diseaseCount': diseaseCount,
      'diseases': diseases,
    };
  }

  /// Crea una copia con cambios
  PlotModel copyWith({
    String? id,
    String? name,
    String? sector,
    double? latitude,
    double? longitude,
    int? totalScans,
    int? healthyCount,
    int? diseaseCount,
    Map<String, int>? diseases,
  }) {
    return PlotModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sector: sector ?? this.sector,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalScans: totalScans ?? this.totalScans,
      healthyCount: healthyCount ?? this.healthyCount,
      diseaseCount: diseaseCount ?? this.diseaseCount,
      diseases: diseases ?? this.diseases,
    );
  }
}