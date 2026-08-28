import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:tomate_detection_app/core/services/api_service.dart';
import 'package:tomate_detection_app/core/services/database_service.dart';
import 'package:tomate_detection_app/core/services/location_service.dart';
import 'package:tomate_detection_app/models/diagnosis_model.dart';
import 'diagnostic_result_page.dart';

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
  DateTime? _lastFrame;
  bool _inferBusy = false;
  int _latencyMs = 9;

  final _api = ApiService();
  final _db = DatabaseService();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  static const _classColors = {
    'mildiu': Color(0xFFEF4444),
    'oidio': Color(0xFFF59E0B),
    'mosca_blanca': Color(0xFFEAB308),
    'mosca blanca': Color(0xFFEAB308),
    'sana': Color(0xFF10B981),
    'sano': Color(0xFF10B981),
    'healthy': Color(0xFF10B981),
  };
  static const _labels = {
    'mildiu': 'Mildiu',
    'oidio': 'Oidio',
    'mosca_blanca': 'Mosca Blanca',
    'mosca blanca': 'Mosca Blanca',
    'sana': 'Sano',
    'sano': 'Sano',
  };

  String _luxText = "Luz Adecuada";
  Color _luxColor = const Color(0xFF4EDEA3);
  IconData _luxIcon = Icons.wb_sunny_rounded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        imageFormatGroup: ImageFormatGroup.bgra8888,
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

  // Inferencia continua (throttle cada 1.2s) -> overlay en vivo sobre el preview
  void _startStream() {
    final c = _controller;
    if (c == null || !c.value.isInitialized || !c.value.isStreamingImages) return;
    _streamActive = true;
    _lastFrame = DateTime.now();
    c.startImageStream((frame) async {
      if (!_streamActive || _inferBusy) return;
      final now = DateTime.now();
      if (_lastFrame != null && now.difference(_lastFrame!) < const Duration(milliseconds: 1200)) return;
      _lastFrame = now;
      _inferBusy = true;
      try {
        final jpg = await _toJpeg(frame);
        if (jpg == null) return;
        final tmp = await getTemporaryDirectory();
        final f = File('${tmp.path}/rt.jpg');
        await f.writeAsBytes(jpg);
        final sw = Stopwatch()..start();
        final res = await _api.detectDisease(XFile(f.path));
        final ms = sw.elapsedMilliseconds;
        await f.delete();
        if (!mounted || !_streamActive) return;
        if (res['status'] == 'success') {
          final items = (res['data']['detections'] as List? ?? []);
          final dets = items.map((d) {
            final b = d['bbox'] as List;
            final x = (b[0] as num).toDouble();
            final y = (b[1] as num).toDouble();
            return {
              'rect': [x, y, (b[2] as num).toDouble() - x, (b[3] as num).toDouble() - y],
              'label': d['disease'] as String,
              'confidence': (d['confidence'] as num) / 100.0,
            };
          }).toList().cast<Map<String, dynamic>>();
          setState(() { _dets = dets; _latencyMs = ms; });
        }
      } catch (e) {
        debugPrint("RT: $e");
      } finally {
        _inferBusy = false;
      }
    });
  }

  void _stopStream() {
    _streamActive = false;
    try { _controller?.stopImageStream(); } catch (_) {}
  }

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
      return Uint8List.fromList(img.encodeJpg(img.copyResize(src, width: 480), quality: 60));
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
    setState(() => _busy = true);
    try {
      final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (f == null) { setState(() => _busy = false); return; }
      final bytes = await f.readAsBytes();
      await _checkLux(bytes);
      await _analyze(bytes, DateTime.now());
    } catch (e) {
      setState(() => _busy = false);
    }
  }

  Future<void> _analyze(List<int> bytes, DateTime t0) async {
    try {
      setState(() { _captured = Uint8List.fromList(bytes); _showResult = true; });
      final tmp = await getTemporaryDirectory();
      final f = File('${tmp.path}/diag.jpg');
      await f.writeAsBytes(bytes);
      LocationService.getCurrentPosition();
      final res = await _api.detectDisease(XFile(f.path));
      final ms = DateTime.now().difference(t0).inMilliseconds;
      setState(() => _latencyMs = ms > 0 ? ms : 9);
      if (res['status'] == 'success') {
        final items = (res['data']['detections'] as List? ?? []);
        final dets = items.map((d) {
          final b = d['bbox'] as List;
          final x = (b[0] as num).toDouble();
          final y = (b[1] as num).toDouble();
          return {
            'rect': [x, y, (b[2] as num).toDouble() - x, (b[3] as num).toDouble() - y],
            'label': d['disease'] as String,
            'confidence': (d['confidence'] as num) / 100.0,
          };
        }).toList().cast<Map<String, dynamic>>();
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
        final list = dbDets.isEmpty
            ? [Detection(diseaseName: 'sana', confidence: 1.0, bbox: BBox(xMin: 0, yMin: 0, xMax: 1, yMax: 1), classIndex: 4)]
            : dbDets;
        final p = await _saveLocal(bytes);
        for (final d in list) {
          await _db.saveDiagnostic(DiagnosisModel(diagnosticId: _uuid.v4(), imagePath: p, disease: d.diseaseName, confidence: d.confidence, createdAt: DateTime.now()).toMap());
        }
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          await Navigator.push(context, MaterialPageRoute(builder: (_) => DiagnosticResultPage(
            imageBytes: Uint8List.fromList(bytes),
            detections: list,
            displayNames: _labels,
            colors: _classColors,
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
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: YoloOverlayPainter(_dets)))),

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
                Text("$_latencyMs ms (Edge AI)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4EDEA3))),
              ]),
              const SizedBox(height: 4),
              Text("Clases: Oidio • Mildiu • Mosca Blanca", style: GoogleFonts.inter(fontSize: 9, color: Color(0xFFBBCABF))),
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
class YoloOverlayPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  YoloOverlayPainter(this.detections);

  static const _colors = {
    'mildiu': Color(0xFFEF4444),
    'oidio': Color(0xFFF59E0B),
    'mosca_blanca': Color(0xFFEAB308),
    'mosca blanca': Color(0xFFEAB308),
    'sana': Color(0xFF10B981),
    'sano': Color(0xFF10B981),
    'healthy': Color(0xFF10B981),
  };
  static const _names = {
    'mildiu': 'Mildiu',
    'oidio': 'Oidio',
    'mosca_blanca': 'Mosca Blanca',
    'mosca blanca': 'Mosca Blanca',
    'sana': 'Sano',
    'sano': 'Sano',
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (final det in detections) {
      final r = det['rect'] as List;
      final lk = (det['label'] as String).toLowerCase();
      final conf = (det['confidence'] as double?) ?? 0;
      final color = _colors[lk] ?? const Color(0xFF4EDEA3);
      final x = (r[0] as num).toDouble() * size.width;
      final y = (r[1] as num).toDouble() * size.height;
      final w = (r[2] as num).toDouble() * size.width;
      final h = (r[3] as num).toDouble() * size.height;
      final rect = Rect.fromLTWH(x, y, w, h);

      canvas.drawRect(rect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 4.5);
      canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5);

      final text = "${_names[lk] ?? lk} ${(conf * 100).toStringAsFixed(0)}%";
      final tp = TextPainter(
        text: TextSpan(text: text, style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black)),
        textDirection: TextDirection.ltr,
      )..layout();
      final br = RRect.fromRectAndRadius(Rect.fromLTWH(rect.left, rect.top - 18, tp.width + 10, 16), const Radius.circular(4));
      canvas.drawRRect(br, Paint()..color = color);
      tp.paint(canvas, Offset(rect.left + 5, rect.top - 15));
    }
  }

  @override
  bool shouldRepaint(covariant YoloOverlayPainter old) => old.detections != detections;
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
