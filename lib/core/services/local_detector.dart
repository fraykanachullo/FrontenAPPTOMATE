import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tomate_detection_app/core/constants/model_info.dart';

/// Deteccion YOLO (v8/v11) en el celular con TFLite, sin internet.
///
/// Mismo pipeline que el backend (validado contra best.pt en el set de test):
/// letterbox a SxS con relleno gris 114 -> RGB/255 -> salida [1, 4+C, N] con
/// cx,cy,w,h normalizados al lienzo + score por clase -> filtro de confianza ->
/// NMS agnostico -> cajas normalizadas 0..1 respecto a la imagen original.
class LocalDetector {
  LocalDetector._();
  static final LocalDetector instance = LocalDetector._();

  static const modelAsset = 'assets/models/best_float16.tflite';
  // Clases y umbrales vienen de assets/models/metadata.json (ModelInfo)

  Interpreter? _interpreter;
  late int _inputSize;
  late List<int> _outputShape;
  Future<void>? _loading;
  bool _busy = false;

  Future<void> _load() async {
    final it = await Interpreter.fromAsset(modelAsset, options: InterpreterOptions()..threads = 4);
    it.allocateTensors();
    _inputSize = it.getInputTensor(0).shape[1];
    _outputShape = it.getOutputTensor(0).shape;
    _interpreter = it;
    debugPrint('[LocalDetector] modelo $modelAsset entrada $_inputSize salida $_outputShape');
  }

  /// Carga el modelo en segundo plano (llamar al abrir el escaner para que el
  /// primer analisis no espere).
  Future<void> warmUp() => _loading ??= _load();

  /// Devuelve detecciones en el mismo formato que usa el escaner:
  /// {'rect': [x, y, w, h] (0..1), 'label': String, 'confidence': double (0..1)}
  Future<List<Map<String, dynamic>>> detect(Uint8List jpegBytes) => _run((r) => r..jpeg = jpegBytes);

  /// Ocupado analizando (el escaner en vivo salta cuadros mientras tanto).
  bool get isBusy => _busy;

  /// Analiza un cuadro YUV420 de la camara de Android. [rotation] es la
  /// orientacion del sensor (0/90/180/270) y [mirror] invierte en horizontal
  /// (camara frontal). Las cajas quedan normalizadas respecto al cuadro ya
  /// rotado, que es como se ve en la vista previa.
  Future<List<Map<String, dynamic>>> detectYuv({
    required int width,
    required int height,
    required List<Uint8List> planes,
    required List<int> rowStrides,
    required List<int> pixelStrides,
    required int rotation,
    bool mirror = false,
  }) =>
      _run((r) => r
        ..yuv = _Yuv(width, height, planes, rowStrides, pixelStrides, rotation, mirror));

  Future<List<Map<String, dynamic>>> _run(void Function(_Request) fill) async {
    await warmUp();
    // El interprete nativo no admite llamadas simultaneas
    while (_busy) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    _busy = true;
    try {
      final req = _Request(_interpreter!.address, _inputSize, _outputShape,
          ModelInfo.classes, ModelInfo.conf, ModelInfo.iou);
      fill(req);
      return await Isolate.run(() => _runDetection(req));
    } finally {
      _busy = false;
    }
  }
}

class _Yuv {
  final int width, height, rotation;
  final List<Uint8List> planes;
  final List<int> rowStrides, pixelStrides;
  final bool mirror;
  _Yuv(this.width, this.height, this.planes, this.rowStrides, this.pixelStrides, this.rotation, this.mirror);
}

class _Request {
  final int address;
  Uint8List? jpeg; // foto (captura / galeria)
  _Yuv? yuv; // cuadro de la camara en vivo
  final int size;
  final List<int> outputShape;
  // Se pasan explicitamente: los campos estaticos no se comparten entre isolates
  final List<String> labels;
  final double conf, iou;
  _Request(this.address, this.size, this.outputShape, this.labels, this.conf, this.iou);
}

/// YUV420 -> RGB rotado (orientacion de la vista previa) y reducido a [target]
/// px en el lado mayor, muestreando solo los pixeles necesarios.
img.Image _yuvToImage(_Yuv f, int target) {
  final rot = f.rotation % 360;
  final rw = (rot == 90 || rot == 270) ? f.height : f.width;
  final rh = (rot == 90 || rot == 270) ? f.width : f.height;
  final s = math.min(1.0, target / math.max(rw, rh));
  final ow = (rw * s).round(), oh = (rh * s).round();
  final yP = f.planes[0], uP = f.planes[1], vP = f.planes[2];
  final yRow = f.rowStrides[0], uvRow = f.rowStrides[1], uvPix = f.pixelStrides[1];
  final out = img.Image(width: ow, height: oh);
  for (var oy = 0; oy < oh; oy++) {
    for (var ox = 0; ox < ow; ox++) {
      var rx = (ox / s).floor();
      final ry = (oy / s).floor();
      if (f.mirror) rx = rw - 1 - rx;
      int x, y;
      switch (rot) {
        case 90:
          x = ry;
          y = f.height - 1 - rx;
          break;
        case 180:
          x = f.width - 1 - rx;
          y = f.height - 1 - ry;
          break;
        case 270:
          x = f.width - 1 - ry;
          y = rx;
          break;
        default:
          x = rx;
          y = ry;
      }
      final yv = yP[y * yRow + x];
      final uvIndex = uvPix * (x >> 1) + uvRow * (y >> 1);
      final u = uP[uvIndex] - 128, v = vP[uvIndex] - 128;
      out.setPixelRgb(ox, oy, (yv + 1.402 * v).clamp(0, 255).toInt(),
          (yv - 0.344136 * u - 0.714136 * v).clamp(0, 255).toInt(), (yv + 1.772 * u).clamp(0, 255).toInt());
    }
  }
  return out;
}

List<Map<String, dynamic>> _runDetection(_Request r) {
  img.Image photo;
  if (r.yuv != null) {
    photo = _yuvToImage(r.yuv!, r.size);
  } else {
    final src = img.decodeImage(r.jpeg!);
    if (src == null) return [];
    photo = img.bakeOrientation(src);
  }
  final w = photo.width, h = photo.height, s = r.size;

  // Letterbox: escalar manteniendo proporcion y centrar en lienzo gris 114
  final scale = math.min(s / w, s / h);
  final nw = (w * scale).round(), nh = (h * scale).round();
  final padX = (s - nw) ~/ 2, padY = (s - nh) ~/ 2;
  final resized = img.copyResize(photo, width: nw, height: nh, interpolation: img.Interpolation.linear);
  final rgb = resized.getBytes(order: img.ChannelOrder.rgb);

  final input = Float32List(s * s * 3)..fillRange(0, s * s * 3, 114 / 255.0);
  for (var y = 0; y < nh; y++) {
    var src = y * nw * 3;
    var dst = ((y + padY) * s + padX) * 3;
    for (var x = 0; x < nw * 3; x++) {
      input[dst++] = rgb[src++] / 255.0;
    }
  }

  final features = r.outputShape[1], n = r.outputShape[2];
  final output = Float32List(features * n);
  Interpreter.fromAddress(r.address, allocated: true).run(input.buffer, output.buffer);

  // Decodificar [4+C, N]. Segun el exportador, cx,cy,w,h vienen normalizados 0..1
  // (export nativo de Ultralytics) o en pixeles del lienzo (via ONNX -> onnx2tf).
  final numClasses = features - 4;
  var maxCoord = 0.0;
  for (var i = 0; i < 4 * n; i++) {
    if (output[i] > maxCoord) maxCoord = output[i];
  }
  final k = maxCoord > 2.0 ? 1.0 : s.toDouble();
  final cand = <_Det>[];
  for (var i = 0; i < n; i++) {
    var best = 0.0, cls = 0;
    for (var c = 0; c < numClasses; c++) {
      final v = output[(4 + c) * n + i];
      if (v > best) {
        best = v;
        cls = c;
      }
    }
    if (best < r.conf) continue;
    final cx = output[i] * k, cy = output[n + i] * k;
    final bw = output[2 * n + i] * k, bh = output[3 * n + i] * k;
    // Quitar padding y escala -> normalizado respecto a la imagen original
    double nx(double v) => ((v - padX) / scale / w).clamp(0.0, 1.0);
    double ny(double v) => ((v - padY) / scale / h).clamp(0.0, 1.0);
    cand.add(_Det(nx(cx - bw / 2), ny(cy - bh / 2), nx(cx + bw / 2), ny(cy + bh / 2), best, cls));
  }

  // NMS agnostico (una caja por zona aunque compitan clases), igual que el backend
  cand.sort((a, b) => b.score.compareTo(a.score));
  final kept = <_Det>[];
  for (final d in cand) {
    if (kept.every((k) => _iou(d, k) < r.iou)) kept.add(d);
  }

  return kept
      .map((d) => <String, dynamic>{
            'rect': [d.x1, d.y1, d.x2 - d.x1, d.y2 - d.y1],
            'label': d.cls < r.labels.length ? r.labels[d.cls] : 'clase_${d.cls}',
            'confidence': d.score,
          })
      .toList();
}

class _Det {
  final double x1, y1, x2, y2, score;
  final int cls;
  _Det(this.x1, this.y1, this.x2, this.y2, this.score, this.cls);
}

double _iou(_Det a, _Det b) {
  final ix = math.max(0.0, math.min(a.x2, b.x2) - math.max(a.x1, b.x1));
  final iy = math.max(0.0, math.min(a.y2, b.y2) - math.max(a.y1, b.y1));
  final inter = ix * iy;
  final union = (a.x2 - a.x1) * (a.y2 - a.y1) + (b.x2 - b.x1) * (b.y2 - b.y1) - inter;
  return union > 0 ? inter / union : 0;
}
