import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tomate_detection_app/core/services/database_service.dart';
import 'package:tomate_detection_app/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:tomate_detection_app/features/diagnosis/data/datasources/diagnostic_remote_datasource.dart';
import 'package:tomate_detection_app/injection_container.dart' as di;

/// Sincronizacion con el servidor (offline-first).
///
/// 1. Sube los diagnosticos hechos sin internet (is_synced = 0) a
///    POST /api/v1/diagnostic/detect; el servidor los re-analiza con best.pt y
///    los guarda con el usuario.
/// 2. Descarga del servidor los diagnosticos del usuario que no estan en este
///    celular (p.ej. al cambiar de celular o reinstalar), con imagen y cajas.
///
/// Corre al abrir la app con sesion, al volver la conexion y a pedido.
class SyncService {
  static StreamSubscription<ConnectivityResult>? _sub;
  static bool _running = false;

  /// Cambia cada vez que una sincronizacion agrega o modifica registros
  /// (el historial lo escucha para recargarse).
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static void start() {
    _sub ??= Connectivity().onConnectivityChanged.listen((r) {
      if (r != ConnectivityResult.none) syncAll();
    });
    syncAll();
  }

  /// Sube y luego descarga. Devuelve (subidos, descargados) o null si no hubo
  /// conexion con el servidor.
  static Future<(int, int)?> syncAll() async {
    if (_running) return (0, 0);
    _running = true;
    try {
      if (await Connectivity().checkConnectivity() == ConnectivityResult.none) return null;
      final token = await di.sl<AuthLocalDataSource>().getAccessToken();
      if (token == null || token.isEmpty) return null;
      final up = await _uploadPending();
      if (up == null) return null;
      final down = await _downloadHistory();
      if (up + (down ?? 0) > 0) changes.value++;
      return (up, down ?? 0);
    } finally {
      _running = false;
    }
  }

  /// Solo subir (boton "Sincronizar Ahora" de Perfil).
  static Future<int> syncPending() async => (await syncAll())?.$1 ?? 0;

  static Future<int?> _uploadPending() async {
    final db = DatabaseService();
    final remote = di.sl<DiagnosticRemoteDataSource>();
    var uploaded = 0;
    for (final d in await db.getPendingDiagnostics()) {
      final path = d['image_path'] as String?;
      final id = d['diagnostic_id'] as String;
      if (path == null || !File(path).existsSync()) {
        await db.markAsSynced(id); // sin imagen no hay nada que subir
        continue;
      }
      try {
        final res = await remote.sendDiagnostic(path, {
          'timestamp_utc': d['created_at'],
          'latitude': d['latitude'],
          'longitude': d['longitude'],
          'analysis_source': 'celular',
          'local_diagnostic_id': id,
        });
        final serverId = res['diagnostic_id'] as String?;
        if (serverId != null) {
          await db.setServerId(id, serverId);
        } else {
          await db.markAsSynced(id);
        }
        uploaded++;
      } on DioException catch (e) {
        // Sin conexion real o sesion vencida: se reintenta en la proxima ocasion
        debugPrint('[Sync] subida detenida: ${e.response?.statusCode ?? e.type}');
        return uploaded > 0 ? uploaded : null;
      }
    }
    if (uploaded > 0) debugPrint('[Sync] $uploaded diagnostico(s) subidos');
    return uploaded;
  }

  static Future<int?> _downloadHistory() async {
    final db = DatabaseService();
    final remote = di.sl<DiagnosticRemoteDataSource>();
    final known = await db.getServerIds();
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/diagnostic_images');
    await dir.create(recursive: true);
    var downloaded = 0;
    try {
      for (var offset = 0;; offset += 100) {
        final page = await remote.getDiagnostics(limit: 100, offset: offset, mine: true);
        for (final s in page.cast<Map<String, dynamic>>()) {
          final serverId = s['diagnostic_id'] as String;
          if (known.contains(serverId)) continue;
          String? imagePath;
          final url = s['image_url'] as String?;
          if (url != null) {
            imagePath = '${dir.path}/$serverId.jpg';
            try {
              await remote.downloadImage(url, imagePath);
            } catch (_) {
              imagePath = null; // sin imagen igual se guarda el resultado
            }
          }
          final dets = (s['detections'] as List? ?? []).cast<Map<String, dynamic>>()
            ..sort((a, b) => (b['confidence_score'] as num).compareTo(a['confidence_score'] as num));
          final primary = dets.isEmpty ? null : dets.firstWhere((d) => d['disease_label'] != 'sana', orElse: () => dets.first);
          await db.saveDiagnostic({
            'diagnostic_id': serverId,
            'server_id': serverId,
            'image_path': imagePath,
            'disease': primary?['disease_label'] ?? 'sana',
            'confidence': (primary?['confidence_score'] as num?)?.toDouble() ?? 0.0,
            'latitude': s['latitude'],
            'longitude': s['longitude'],
            'created_at': _localIso(s['captured_at'] ?? s['created_at']),
            'is_synced': 1,
            'detections_json': jsonEncode([
              for (final d in dets)
                {
                  'label': d['disease_label'],
                  'confidence': d['confidence_score'],
                  'bbox': [
                    d['bounding_box']['x_min'],
                    d['bounding_box']['y_min'],
                    d['bounding_box']['x_max'],
                    d['bounding_box']['y_max'],
                  ],
                  'source': 'servidor',
                }
            ]),
          });
          downloaded++;
        }
        if (page.length < 100) break;
      }
    } on DioException catch (e) {
      debugPrint('[Sync] descarga detenida: ${e.response?.statusCode ?? e.type}');
      return downloaded > 0 ? downloaded : null;
    }
    if (downloaded > 0) debugPrint('[Sync] $downloaded diagnostico(s) descargados');
    return downloaded;
  }

  // El historial local guarda la hora del celular (sin zona)
  static String _localIso(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    return (d ?? DateTime.now()).toLocal().toIso8601String();
  }
}
