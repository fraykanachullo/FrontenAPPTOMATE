import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metadatos del modelo del celular (assets/models/metadata.json).
/// Al cambiar de modelo se reemplazan best_float16.tflite y metadata.json.
class ModelInfo {
  static String name = 'tomate-majes';
  static String version = '?';
  static String architecture = 'YOLO';
  static List<String> classes = ['mildiu', 'mosca_blanca', 'oidio', 'polilla', 'sana'];
  static double conf = 0.30;
  static double iou = 0.45;
  static double? accuracyMobile;

  static String get label => '$architecture v$version';

  static Future<void> load() async {
    try {
      final m = jsonDecode(await rootBundle.loadString('assets/models/metadata.json')) as Map<String, dynamic>;
      name = m['name'] ?? name;
      version = m['version'] ?? version;
      architecture = m['architecture'] ?? architecture;
      classes = (m['classes'] as List?)?.cast<String>() ?? classes;
      conf = (m['conf_threshold'] as num?)?.toDouble() ?? conf;
      iou = (m['iou_threshold'] as num?)?.toDouble() ?? iou;
      accuracyMobile = (m['metrics']?['main_class_accuracy_mobile'] as num?)?.toDouble();
    } catch (_) {}
  }
}

/// Donde se analiza: 'auto' = servidor si hay internet, celular si no;
/// 'edge' = siempre en el celular (no se envian fotos al analizar).
class InferenceSettings {
  static const _key = 'inference_mode';
  static String mode = 'auto';

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    mode = p.getString(_key) ?? 'auto';
  }

  static Future<void> save(String m) async {
    mode = m;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, m);
  }
}
