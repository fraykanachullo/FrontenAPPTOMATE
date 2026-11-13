class DiagnosisModel {
  final String diagnosticId;
  final String? imagePath;
  final String disease;
  final double confidence;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final bool isSynced;
  final String? userNotes;
  // JSON: [{label, confidence, bbox:[xMin,yMin,xMax,yMax]}] normalizado 0..1
  final String? detectionsJson;
  // Id en el servidor (null si aun no se subio)
  final String? serverId;

  DiagnosisModel({
    required this.diagnosticId,
    this.imagePath,
    required this.disease,
    required this.confidence,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.isSynced = false,
    this.userNotes,
    this.detectionsJson,
    this.serverId,
  });

  Map<String, dynamic> toMap() {
    return {
      'diagnostic_id': diagnosticId,
      'image_path': imagePath,
      'disease': disease,
      'confidence': confidence,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'user_notes': userNotes,
      'detections_json': detectionsJson,
      'server_id': serverId,
    };
  }

  factory DiagnosisModel.fromMap(Map<String, dynamic> map) {
    return DiagnosisModel(
      diagnosticId: map['diagnostic_id'],
      imagePath: map['image_path'],
      disease: map['disease'],
      confidence: map['confidence'].toDouble(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      isSynced: map['is_synced'] == 1,
      userNotes: map['user_notes'],
      detectionsJson: map['detections_json'],
      serverId: map['server_id'],
    );
  }
}