import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:tomate_detection_app/core/constants/disease_classes.dart';
import 'package:tomate_detection_app/core/constants/model_info.dart';
import 'package:tomate_detection_app/core/services/database_service.dart';
import 'package:tomate_detection_app/core/services/local_detector.dart';
import 'package:tomate_detection_app/features/diagnosis/data/datasources/diagnostic_remote_datasource.dart';
import 'package:tomate_detection_app/injection_container.dart' as di;
import 'package:tomate_detection_app/core/services/location_service.dart';
import 'package:tomate_detection_app/models/diagnosis_model.dart';
import 'diagnostic_result_page.dart';

// Aplica la rotacion EXIF y limita a 1280px. Esta misma imagen se muestra,
// se envia al backend y se guarda en historial, asi las cajas siempre coinciden.
Uint8List _normalizePhoto(Uint8List bytes) {
  final d = img.decodeImage(bytes);
  if (d == null) return bytes;
  var o = img.bakeOrientation(d);
  if (o.width > 1280 || o.height > 1280) {
    o = o.width >= o.height ? img.copyResize(o, width: 1280) : img.copyResize(o, height: 1280);
  }
  return Uint8List.fromList(img.encodeJpg(o, quality: 90));
}

// Escaneo en Tiempo Real — Producción listo: viewfinder vivo + overlay YOLO + HUD
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _ready = false;
  bool _denied = false;
  bool _busy = false;
  bool _flashOn = false;
  int _cameraIndex = 0;

  // Detecciones YOLO normalizadas [x,y,w,h] 0..1
  List<Map<String, dynamic>> _dets = [];
  Uint8List? _captured;
  bool _showResult = false;

  // Tiempo real
  bool _streamActive = false;
  bool _inferBusy = false;
  int _latencyMs = 0;
  // Proporcion (ancho/alto) de la imagen sobre la que se dibujan las cajas y si
  // se muestra recortada (vista previa, cover) o completa (foto capturada, contain)
  double _detAspect = 3 / 4;
  bool _detCover = true;

  final _db = DatabaseService();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  static const _classColors = DiseaseClasses.colors;
  static const _labels = DiseaseClasses.labels;

  String _luxText = "Luz Adecuada";
  Color _luxColor = const Color(0xFF4EDEA3);
  IconData _luxIcon = Icons.wb_sunny_rounded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocalDetector.instance.warmUp(); // carga el modelo offline mientras abre la camara
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (s == AppLifecycleState.inactive) {
      _stopStream();
      _controller?.dispose();
    } else if (s == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final perm = await Permission.camera.request();
      if (!perm.isGranted) {
        if (mounted) setState(() => _denied = true);
        return;
      }
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _denied = true);
        return;
      }
      _controller?.dispose();
      _controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        // Android entrega YUV420 en el stream; bgra8888 solo existe en iOS
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
      _startStream();
    } on CameraException catch (e) {
      debugPrint("Cam init: $e");
      if (e.code == 'CameraAccessDenied' || e.code == 'cameraPermission') {
        if (mounted) setState(() => _denied = true);
      }
    } catch (e) {
      debugPrint("Cam err: $e");
      if (mounted) setState(() => _denied = true);
    }
  }

  // Deteccion en vivo en el celular sobre los cuadros de la camara. Mientras un
  // cuadro se analiza los siguientes se descartan (va tan rapido como el celular).
  void _startStream() {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isStreamingImages || _showResult) return;
    _streamActive = true;
    final cam = c.description;
    c.startImageStream((frame) async {
      if (!_streamActive || _inferBusy || LocalDetector.instance.isBusy) return;
      _inferBusy = true;
      try {
        final sw = Stopwatch()..start();
        final List<Map<String, dynamic>> dets;
        if (frame.format.group == ImageFormatGroup.yuv420 && frame.planes.length == 3) {
          dets = await LocalDetector.instance.detectYuv(
            width: frame.width,
            height: frame.height,
            planes: [for (final p in frame.planes) Uint8List.fromList(p.bytes)],
            rowStrides: [for (final p in frame.planes) p.bytesPerRow],
            pixelStrides: [for (final p in frame.planes) p.bytesPerPixel ?? 1],
            rotation: cam.sensorOrientation,
            mirror: cam.lensDirection == CameraLensDirection.front,
          );
        } else {
          final jpg = await _toJpeg(frame);
          if (jpg == null) return;
          dets = await LocalDetector.instance.detect(jpg);
        }
        final ms = sw.elapsedMilliseconds;
        if (!mounted || !_streamActive) return;
        final rotated = cam.sensorOrientation % 180 == 90;
        setState(() {
          _dets = dets;
          _latencyMs = ms;
          _detAspect = rotated ? frame.height / frame.width : frame.width / frame.height;
          _detCover = true;
        });
      } catch (e) {
        debugPrint("RT: $e");
      } finally {
        _inferBusy = false;
      }
    });
  }

  void _stopStream() {
    _streamActive = false;
    try {
      if (_controller?.value.isStreamingImages ?? false) _controller?.stopImageStream();
    } catch (_) {}
  }

  // iOS (bgra8888)
  Future<Uint8List?> _toJpeg(CameraImage im) async {
    try {
      final p = im.planes[0];
      final w = im.width, h = im.height;
      final bpp = p.bytesPerPixel ?? 4;
      ByteBuffer buf = p.bytes.buffer;
      if (p.bytesPerRow != w * bpp) {
        final packed = Uint8List(w * h * bpp);
        for (int y = 0; y < h; y++) {
          final src = p.bytes.buffer.asUint8List(p.bytesPerRow * y, w * bpp);
          packed.setRange(y * w * bpp, (y + 1) * w * bpp, src);
        }
        buf = packed.buffer;
      }
      final src = img.Image.fromBytes(width: w, height: h, bytes: buf, order: img.ChannelOrder.bgra);
      return Uint8List.fromList(img.encodeJpg(img.copyResize(src, width: 640), quality: 80));
    } catch (e) {
      return null;
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_ready || _busy) return;
    _stopStream();
    setState(() => _busy = true);
    final t0 = DateTime.now();
    try {
      final x = await _controller!.takePicture();
      final bytes = await x.readAsBytes();
      await _checkLux(bytes);
      await _analyze(bytes, t0);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
      _startStream();
    }
  }

  Future<void> _fromGallery() async {
    if (_busy) return;
    _stopStream(); // que el analisis en vivo no pise las cajas de la foto elegida
    setState(() { _busy = true; _dets = []; });
    try {
      final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (f == null) { setState(() => _busy = false); _startStream(); return; }
      final bytes = await f.readAsBytes();
      await _checkLux(bytes);
      await _analyze(bytes, DateTime.now());
    } catch (e) {
      setState(() => _busy = false);
    }
  }

  Future<void> _analyze(List<int> rawBytes, DateTime t0) async {
    try {
      final bytes = await compute(_normalizePhoto, Uint8List.fromList(rawBytes));
      final dims = img.decodeJpg(bytes);
      setState(() {
        _captured = bytes;
        _showResult = true;
        _dets = [];
        if (dims != null) _detAspect = dims.width / dims.height;
        _detCover = false;
      });
      LocationService.getCurrentPosition();
      final p = await _saveLocal(bytes);
      final (dets, source, serverId) = await _detect(p, bytes);
      final ms = DateTime.now().difference(t0).inMilliseconds;
      setState(() => _latencyMs = ms > 0 ? ms : 9);
      {
        dets.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
        setState(() => _dets = dets);

        final dbDets = dets.map((m) {
          final r = m['rect'] as List;
          return Detection(
            diseaseName: m['label'] as String,
            confidence: m['confidence'] as double,
            bbox: BBox(xMin: (r[0] as double), yMin: (r[1] as double), xMax: (r[0] as double) + (r[2] as double), yMax: (r[1] as double) + (r[3] as double)),
            classIndex: 0,
          );
        }).toList();
        // Sin detecciones: sin sintomas detectados, sin caja ni confianza (no es "100 % sana")
        final list = dbDets.isEmpty
            ? [Detection(diseaseName: 'sana', confidence: 0.0, bbox: BBox(xMin: 0, yMin: 0, xMax: 0, yMax: 0), classIndex: 4)]
            : dbDets;
        // Un registro por escaneo, con todas las cajas reales para el historial
        final primary = list.firstWhere((d) => d.diseaseName != 'sana', orElse: () => list.first);
        final detJson = jsonEncode(dbDets.map((d) => {
          'label': d.diseaseName,
          'confidence': d.confidence,
          'bbox': [d.bbox.xMin, d.bbox.yMin, d.bbox.xMax, d.bbox.yMax],
          'source': source,
        }).toList());
        await _db.saveDiagnostic(DiagnosisModel(diagnosticId: _uuid.v4(), imagePath: p, disease: primary.diseaseName, confidence: primary.confidence, createdAt: DateTime.now(), detectionsJson: detJson,
            // Analizado en el servidor = ya guardado alla; en el celular = pendiente de subir
            isSynced: source == 'servidor', serverId: serverId).toMap());
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          await Navigator.push(context, MaterialPageRoute(builder: (_) => DiagnosticResultPage(
            imageBytes: bytes,
            detections: list,
            displayNames: _labels,
            colors: _classColors,
            source: source,
          )));
          _reset();
          return;
        }
      }
      setState(() => _busy = false);
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // Offline-first: con conexion usa el servidor (modelo completo, queda guardado
  // con el usuario via /api/v1 + JWT); si no hay red, el servidor no responde o
  // falla, analiza en el celular con TFLite y queda pendiente de sincronizar.
  Future<(List<Map<String, dynamic>>, String, String?)> _detect(String imagePath, Uint8List bytes) async {
    final net = await Connectivity().checkConnectivity();
    final online = net != ConnectivityResult.none; // connectivity_plus 5.x: un solo resultado
    if (online && InferenceSettings.mode == 'auto') {
      try {
        final res = await di.sl<DiagnosticRemoteDataSource>().sendDiagnostic(imagePath, {
          'timestamp_utc': DateTime.now().toUtc().toIso8601String(),
          'analysis_source': 'servidor',
        });
        final items = (res['detections'] as List? ?? []);
        final dets = items.map((d) {
          final b = d['bounding_box'] as Map<String, dynamic>;
          final x = (b['x_min'] as num).toDouble();
          final y = (b['y_min'] as num).toDouble();
          return <String, dynamic>{
            'rect': [x, y, (b['x_max'] as num).toDouble() - x, (b['y_max'] as num).toDouble() - y],
            'label': d['disease_label'] as String,
            'confidence': (d['confidence_score'] as num).toDouble(),
          };
        }).toList();
        return (dets, 'servidor', res['diagnostic_id'] as String?);
      } catch (e) {
        debugPrint('Servidor no disponible, usando modelo local: $e');
      }
    }
    return (await LocalDetector.instance.detect(bytes), 'celular', null);
  }

  Future<String> _saveLocal(List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final p = '${dir.path}/diagnostic_images';
    await Directory(p).create(recursive: true);
    final f = File('$p/${_uuid.v4()}.jpg');
    await f.writeAsBytes(bytes);
    return f.path;
  }

  Future<void> _checkLux(Uint8List bytes) async {
    try {
      final d = img.decodeImage(bytes);
      if (d == null) return;
      double sum = 0; int over = 0;
      final total = d.width ~/ 6 * (d.height ~/ 6);
      for (int y = 0; y < d.height; y += 6) {
        for (int x = 0; x < d.width; x += 6) {
          final px = d.getPixel(x, y);
          final lum = 0.299 * px.r + 0.587 * px.g + 0.114 * px.b;
          sum += lum;
          if (lum > 240) over++;
        }
      }
      final mean = sum / total;
      final overPct = over / total * 100;
      if (mean > 200 || overPct > 15) {
        setState(() { _luxText = "Mucha luz"; _luxColor = const Color(0xFFFDD400); _luxIcon = Icons.wb_sunny_rounded; });
      } else if (mean < 55) {
        setState(() { _luxText = "Poca Luz"; _luxColor = const Color(0xFFFFB95F); _luxIcon = Icons.nightlight_rounded; });
      } else {
        setState(() { _luxText = "Luz Adecuada"; _luxColor = const Color(0xFF4EDEA3); _luxIcon = Icons.wb_sunny_rounded; });
      }
    } catch (_) {}
  }

  void _reset() {
    setState(() { _showResult = false; _dets = []; _captured = null; _busy = false; });
    _startStream();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_ready) return;
    _flashOn = !_flashOn;
    try { await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off); }
    catch (_) { _flashOn = !_flashOn; }
    setState(() {});
  }

  Future<void> _flip() async {
    if (_cameras.length < 2) return;
    _stopStream();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    setState(() => _ready = false);
    await _init();
  }

  @override
  void dispose() {
    _stopStream();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_denied) {
      return Scaffold(
        backgroundColor: const Color(0xFF131313),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.no_photography_rounded, color: Color(0xFF4EDEA3), size: 56),
          const SizedBox(height: 16),
          Text("Permiso de cámara requerido", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("Activa la cámara en Ajustes para escanear hojas en campo", style: GoogleFonts.inter(color: const Color(0xFFBBCABF), fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _init, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4EDEA3), foregroundColor: const Color(0xFF002113)), child: const Text("Reintentar")),
        ]))),
      );
    }
    if (!_ready || _controller == null) {
      return const Scaffold(backgroundColor: Color(0xFF131313), body: Center(child: CircularProgressIndicator(color: Color(0xFF4EDEA3))));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Capa 1 — Video en vivo (sin letterboxing)
        Positioned.fill(child: ClipRect(child: FittedBox(fit: BoxFit.cover, child: SizedBox(
          width: _controller!.value.previewSize!.height,
          height: _controller!.value.previewSize!.width,
          child: CameraPreview(_controller!),
        )))),

        // Imagen capturada + overlay
        if (_showResult && _captured != null)
          Positioned.fill(child: Image.memory(_captured!, fit: BoxFit.contain)),

        // Capa 2 — Overlay YOLO (sobre preview o captura)
        if (_dets.isNotEmpty)
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: YoloOverlayPainter(_dets, aspect: _detAspect, cover: _detCover)))),

        // Guía foliar punteada
        if (!_showResult)
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _LeafGuide()))),

        // Capa 3 — Barra superior (SafeArea)
        SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
            _round(Icons.close_rounded, () => Navigator.pop(context)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _luxColor.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_luxIcon, size: 15, color: Colors.black87),
                const SizedBox(width: 6),
                Text(_luxText, style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
              ]),
            ),
            const Spacer(),
            _round(_flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, _toggleFlash, active: _flashOn),
            const SizedBox(width: 8),
            _round(Icons.settings_rounded, () {}),
          ])),
          // HUD métricas flotante abajo del header
          Align(alignment: Alignment.centerLeft, child: Container(
            margin: const EdgeInsets.only(left: 16, top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF131313).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2E2E2E))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4EDEA3), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(_latencyMs > 0 ? "En vivo • $_latencyMs ms por cuadro" : "En vivo • cargando modelo…", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4EDEA3))),
              ]),
              const SizedBox(height: 4),
              Text("Mildiu • Oídio • Mosca blanca • Polilla", style: GoogleFonts.inter(fontSize: 9, color: Color(0xFFBBCABF))),
            ]),
          )),
          const Spacer(),
        ])),

        // Overlay de procesando
        if (_busy)
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.45), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: Color(0xFF4EDEA3)),
            const SizedBox(height: 12),
            Text("Analizando...", style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          ])))),

        // Capa 4 — Barra inferior
        Positioned(left: 0, right: 0, bottom: 0, child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6), Colors.black])),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
            _roundLarge(Icons.photo_library_rounded, _fromGallery),
            GestureDetector(
              onTap: _busy ? null : (_showResult ? _reset : _capture),
              child: Container(
                width: 74, height: 74,
                decoration: BoxDecoration(color: const Color(0xFF4EDEA3), shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 4), boxShadow: [BoxShadow(color: const Color(0xFF4EDEA3).withValues(alpha: 0.45), blurRadius: 16)]),
                child: Container(margin: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFF4EDEA3), shape: BoxShape.circle, border: Border.all(color: Color(0xFF002113), width: 2)), child: Icon(_showResult ? Icons.refresh_rounded : Icons.camera_alt_rounded, color: const Color(0xFF002113), size: 28)),
              ),
            ),
            _roundLarge(Icons.cameraswitch_rounded, _flip),
          ]),
        )),
      ]),
    );
  }

  Widget _round(IconData icon, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(onTap: onTap, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF1F1F1F).withValues(alpha: 0.85), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.15))), child: Icon(icon, color: active ? const Color(0xFFFFD600) : Colors.white, size: 20)));
  }

  Widget _roundLarge(IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF1F1F1F).withValues(alpha: 0.85), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.15))), child: Icon(icon, color: Colors.white, size: 22)));
  }
}

// Capa 2 — CustomPainter de cajas YOLO
// Las cajas vienen normalizadas 0..1 respecto a la imagen; se proyectan segun
// como se muestra: recortada para llenar la pantalla (cover, vista previa en vivo)
// o completa con bordes (contain, foto capturada).
class YoloOverlayPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final double aspect;
  final bool cover;
  YoloOverlayPainter(this.detections, {required this.aspect, required this.cover});

  @override
  void paint(Canvas canvas, Size size) {
    final screenAspect = size.width / size.height;
    final wider = screenAspect > aspect;
    final dw = (cover == wider) ? size.width : size.height * aspect;
    final dh = (cover == wider) ? size.width / aspect : size.height;
    final ox = (size.width - dw) / 2, oy = (size.height - dh) / 2;

    for (final det in detections) {
      final r = det['rect'] as List;
      final lk = (det['label'] as String).toLowerCase();
      final conf = (det['confidence'] as double?) ?? 0;
      final color = DiseaseClasses.colors[lk] ?? const Color(0xFF4EDEA3);
      final rect = Rect.fromLTWH(
        ox + (r[0] as num).toDouble() * dw,
        oy + (r[1] as num).toDouble() * dh,
        (r[2] as num).toDouble() * dw,
        (r[3] as num).toDouble() * dh,
      );

      canvas.drawRect(rect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 4.5);
      canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5);

      final text = "${DiseaseClasses.labels[lk] ?? lk} ${(conf * 100).toStringAsFixed(0)}%";
      final tp = TextPainter(
        text: TextSpan(text: text, style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black)),
        textDirection: TextDirection.ltr,
      )..layout();
      final top = math.max(0.0, rect.top - 18);
      final br = RRect.fromRectAndRadius(Rect.fromLTWH(rect.left, top, tp.width + 10, 16), const Radius.circular(4));
      canvas.drawRRect(br, Paint()..color = color);
      tp.paint(canvas, Offset(rect.left + 5, top + 3));
    }
  }

  @override
  bool shouldRepaint(covariant YoloOverlayPainter old) =>
      old.detections != detections || old.aspect != aspect || old.cover != cover;
}

// Guía foliar punteada + esquinas
class _LeafGuide extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2 - 30), width: size.width * 0.72, height: size.width * 0.72);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height))..addRRect(rrect)..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.35));
    final dashed = _dash(rrect);
    canvas.drawPath(dashed, Paint()..color = Colors.white.withValues(alpha: 0.85)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    final corner = Paint()..color = const Color(0xFF4EDEA3)..style = PaintingStyle.stroke..strokeWidth = 3;
    const len = 26.0;
    for (final c in [Offset(rect.left, rect.top), Offset(rect.right, rect.top), Offset(rect.right, rect.bottom), Offset(rect.left, rect.bottom)]) {
      final hDir = c.dx == rect.left ? 1 : -1;
      final vDir = c.dy == rect.top ? 1 : -1;
      final p = Path()..moveTo(c.dx + hDir * len, c.dy)..lineTo(c.dx, c.dy)..lineTo(c.dx, c.dy + vDir * len);
      canvas.drawPath(p, corner);
    }
  }

  Path _dash(RRect rrect) {
    final base = Path()..addRRect(rrect);
    final out = Path();
    final metrics = base.computeMetrics().first;
    double d = 0;
    while (d < metrics.length) { out.addPath(metrics.extractPath(d, d + 10), Offset.zero); d += 18; }
    return out;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class Detection {
  final String diseaseName;
  final double confidence;
  final BBox bbox;
  final int classIndex;
  Detection({required this.diseaseName, required this.confidence, required this.bbox, required this.classIndex});
}

class BBox {
  final double xMin, yMin, xMax, yMax;
  BBox({required this.xMin, required this.yMin, required this.xMax, required this.yMax});
}
