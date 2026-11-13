// Benchmark del modelo TFLite en el celular (prueba P1 del articulo).
//
// Pasa por LocalDetector (el mismo pipeline de la app) las imagenes de test y
// mide el tiempo de cada deteccion (sin contar la descarga). Las imagenes se
// leen por HTTP desde la PC (Android 16 no deja leer archivos copiados con adb)
// y los resultados vuelven a la PC en build/integration_response_data.json.
//
// En la carpeta de imagenes: ls *.jpg > index.txt && python -m http.server 8001
// adb reverse tcp:8001 tcp:8001
// flutter drive --profile --driver=test_driver/integration_test.dart --target=integration_test/benchmark_test.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tomate_detection_app/core/constants/model_info.dart';
import 'package:tomate_detection_app/core/services/local_detector.dart';

const _base = 'http://127.0.0.1:8001';

Future<Uint8List> _get(HttpClient http, String path) async {
  final res = await (await http.getUrl(Uri.parse('$_base/$path'))).close();
  final b = BytesBuilder(copy: false);
  await for (final chunk in res) {
    b.add(chunk);
  }
  return b.takeBytes();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('benchmark TFLite', (tester) async {
    await ModelInfo.load();
    final http = HttpClient();
    final files = String.fromCharCodes(await _get(http, 'index.txt'))
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    expect(files, isNotEmpty);

    final det = LocalDetector.instance;
    final sw = Stopwatch()..start();
    await det.warmUp();
    final loadMs = sw.elapsedMilliseconds;

    final rows = <Map<String, dynamic>>[];
    for (final f in files) {
      final bytes = await _get(http, Uri.encodeComponent(f));
      sw.reset();
      final dets = await det.detect(bytes);
      rows.add({'file': f, 'ms': sw.elapsedMilliseconds, 'detections': dets});
    }
    http.close();

    binding.reportData = {'model': LocalDetector.modelAsset, 'load_ms': loadMs, 'images': rows};
    final ms = rows.skip(1).map((r) => r['ms'] as int).toList();
    debugPrint('BENCH n=${ms.length} media=${ms.reduce((a, b) => a + b) / ms.length} ms');
  }, timeout: const Timeout(Duration(minutes: 30)));
}
