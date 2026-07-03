import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tomate_detection_app/core/services/api_service.dart';
import 'package:tomate_detection_app/core/services/database_service.dart';
import 'package:tomate_detection_app/models/diagnosis_model.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _controller;
  List<Detection> _detections = [];
  bool _isProcessing = false;
  bool _isCameraReady = false;
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();
  String _statusMessage = '';
  Uint8List? _capturedImage;
  bool _showImage = false;

  // Mapeo de clases (según tu entrenamiento)
  final Map<String, String> _classDisplayNames = {
    'mildiu': 'Mildiu Velloso',
    'mosca_blanca': 'Mosca Blanca',
    'oidio': 'Cenicilla/Oidio',
    'polilla': 'Polilla del Tomate',
    'sana': 'Hoja Sana',
  };

  final Map<String, Color> _classColors = {
    'mildiu': Colors.orange,
    'mosca_blanca': Colors.pink,
    'oidio': Colors.yellow,
    'polilla': Colors.red,
    'sana': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('❌ Error cámara: $e');
    }
  }

  Future<String?> _saveImageLocally(List<int> imageBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/diagnostic_images/';
      await Directory(path).create(recursive: true);
      
      final fileName = '${_uuid.v4()}.jpg';
      final filePath = '$path$fileName';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      
      return filePath;
    } catch (e) {
      debugPrint('❌ Error guardando imagen: $e');
      return null;
    }
  }

  Future<void> _saveDiagnostic(List<Detection> detections, List<int> imageBytes) async {
    try {
      final imagePath = await _saveImageLocally(imageBytes);
      
      for (var detection in detections) {
        final diagnosis = DiagnosisModel(
          diagnosticId: _uuid.v4(),
          imagePath: imagePath,
          disease: detection.diseaseName,
          confidence: detection.confidence,
          createdAt: DateTime.now(),
          isSynced: false,
        );
        
        await _dbService.saveDiagnostic(diagnosis.toMap());
        debugPrint('✅ Diagnóstico guardado: ${diagnosis.disease}');
      }
    } catch (e) {
      debugPrint('❌ Error guardando diagnóstico: $e');
    }
  }

  Future<void> _captureAndDetect() async {
    if (_controller == null || !_isCameraReady) return;
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturando imagen...';
    });

    try {
      final image = await _controller!.takePicture();
      final imageBytes = await image.readAsBytes();
      await _processImageBytes(imageBytes);
    } catch (e) {
      debugPrint('❌ Error en captura/detección: $e');
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error al capturar';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Seleccionando imagen...';
    });

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile == null) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
        return;
      }
      
      setState(() {
        _statusMessage = 'Procesando imagen...';
      });
      
      final imageBytes = await pickedFile.readAsBytes();
      final img.Image? imgImage = img.decodeImage(imageBytes);
      
      if (imgImage == null) {
        throw Exception('No se pudo decodificar la imagen');
      }
      
      final jpegBytes = img.encodeJpg(imgImage, quality: 90);
      await _processImageBytes(jpegBytes);
      
    } catch (e) {
      debugPrint('❌ Error galería: $e');
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error al seleccionar imagen';
      });
    }
  }

  Future<void> _processImageBytes(List<int> imageBytes) async {
    try {
      setState(() {
        _capturedImage = Uint8List.fromList(imageBytes);
        _showImage = true;
        _statusMessage = 'Enviando al servidor...';
      });
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_image.jpg');
      await tempFile.writeAsBytes(imageBytes);
      
      final XFile imageFile = XFile(tempFile.path);
      
      final result = await _apiService.detectDisease(imageFile);
      
      debugPrint('📦 Respuesta del backend: $result');
      
      if (result['status'] == 'success') {
        final detectionsData = result['data']['detections'] as List;
        
        debugPrint('📊 Número de detecciones: ${detectionsData.length}');
        
        // ✅ GUARDAR TODOS LOS DIAGNÓSTICOS (ENFERMEDADES + SANAS)
        if (detectionsData.isNotEmpty) {
          final detections = detectionsData.map((d) {
            final bbox = d['bbox'];
            return Detection(
              diseaseName: d['disease'],
              confidence: (d['confidence'] as num) / 100,
              bbox: BBox(
                xMin: bbox[0].toDouble(),
                yMin: bbox[1].toDouble(),
                xMax: bbox[2].toDouble(),
                yMax: bbox[3].toDouble(),
              ),
              classIndex: 0,
            );
          }).toList();
          
          // ✅ Guardar TODAS las detecciones (incluyendo sanas)
          await _saveDiagnostic(detections, imageBytes);
          debugPrint('✅ Diagnóstico guardado: ${detections.length} detecciones');
        } else {
          // ✅ Si no hay detecciones, guardar como "sana"
          final sanaDetection = Detection(
            diseaseName: 'sana',
            confidence: 1.0,
            bbox: BBox(xMin: 0, yMin: 0, xMax: 1, yMax: 1),
            classIndex: 4,
          );
          await _saveDiagnostic([sanaDetection], imageBytes);
          debugPrint('✅ Diagnóstico guardado: sana');
        }
        
        // ✅ SEPARAR ENFERMEDADES Y SANAS PARA EL MENSAJE
        final diseases = detectionsData.where((d) => d['disease'] != 'sana').toList();
        final healthy = detectionsData.where((d) => d['disease'] == 'sana').toList();
        
        debugPrint('🦠 Enfermedades: ${diseases.length}');
        debugPrint('🌿 Sanas: ${healthy.length}');
        
        // ✅ CREAR LISTA DE DETECCIONES (TODAS PARA MOSTRAR BBOX)
        final detections = detectionsData.map((d) {
          final bbox = d['bbox'];
          return Detection(
            diseaseName: d['disease'],
            confidence: (d['confidence'] as num) / 100,
            bbox: BBox(
              xMin: bbox[0].toDouble(),
              yMin: bbox[1].toDouble(),
              xMax: bbox[2].toDouble(),
              yMax: bbox[3].toDouble(),
            ),
            classIndex: 0,
          );
        }).toList();
        
        // ✅ CONSTRUIR MENSAJE PARA EL USUARIO
        String message;
        Color snackBarColor;
        String statusMsg;
        
        if (diseases.isEmpty) {
          message = '✅ ¡Excelente! No se detectaron enfermedades. La planta está sana.';
          snackBarColor = Colors.green;
          statusMsg = '✅ Planta sana';
        } else if (healthy.isNotEmpty) {
          final diseaseNames = diseases.map((d) => _classDisplayNames[d['disease']] ?? d['disease']).toList();
          final diseaseCount = diseases.length;
          final diseaseList = diseaseNames.join(', ');
          message = '⚠️ Se detectaron $diseaseCount enfermedad(es): $diseaseList.';
          snackBarColor = Colors.orange;
          statusMsg = '⚠️ $diseaseCount enfermedad(es) detectada(s)';
        } else {
          final diseaseNames = diseases.map((d) => _classDisplayNames[d['disease']] ?? d['disease']).toList();
          final diseaseCount = diseases.length;
          final diseaseList = diseaseNames.join(', ');
          message = '⚠️ Se detectaron $diseaseCount enfermedad(es): $diseaseList.';
          snackBarColor = Colors.red;
          statusMsg = '⚠️ $diseaseCount enfermedad(es) detectada(s)';
        }
        
        setState(() {
          _detections = detections;
          _isProcessing = false;
          _statusMessage = statusMsg;
        });
        
        // ✅ SNACKBAR CON BOTÓN "VER HISTORIAL"
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: snackBarColor,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Ver Historial',
                textColor: Colors.white,
                onPressed: () {
                  // ✅ Navegar a la pestaña de historial
                  // Usamos un IndexedStack o BottomNavigationBar
                  // En este caso, asumimos que el índice 1 es History
                  final navigatorContext = context;
                  // Buscar el widget que contiene el BottomNavigationBar
                  // y cambiar el índice a 1
                },
              ),
            ),
          );
        }
        
      } else {
        throw Exception(result['message'] ?? 'Error desconocido');
      }
      
      await tempFile.delete();
      
    } catch (e) {
      debugPrint('❌ Error procesando imagen: $e');
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error al procesar';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetCamera() {
    setState(() {
      _showImage = false;
      _detections = [];
      _capturedImage = null;
      _statusMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diagnóstico')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico en Campo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navegar a historial (índice 1)
            },
          ),
          if (_showImage)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _resetCamera,
              tooltip: 'Volver a cámara',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_showImage && _capturedImage != null)
                  Image.memory(
                    _capturedImage!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  )
                else
                  CameraPreview(_controller!),
                
                if (_detections.isNotEmpty && _showImage)
                  CustomPaint(
                    painter: DetectionPainter(
                      detections: _detections,
                      imageSize: MediaQuery.of(context).size,
                      classColors: _classColors,
                      classNames: _classDisplayNames,
                    ),
                    size: MediaQuery.of(context).size,
                  ),
                
                if (_isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_detections.isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _detections.length,
                itemBuilder: (context, index) {
                  final detection = _detections[index];
                  final displayName = _classDisplayNames[detection.diseaseName] ?? detection.diseaseName;
                  final color = _classColors[detection.diseaseName] ?? Colors.grey;
                  return Card(
                    color: color.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(detection.confidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: detection.confidence > 0.5 ? color : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureAndDetect,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capturar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class Detection {
  final String diseaseName;
  final double confidence;
  final BBox bbox;
  final int classIndex;
  Detection({
    required this.diseaseName,
    required this.confidence,
    required this.bbox,
    required this.classIndex,
  });
}

class BBox {
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;
  BBox({
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
  });
}

class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;
  final Map<String, Color> classColors;
  final Map<String, String> classNames;

  DetectionPainter({
    required this.detections,
    required this.imageSize,
    required this.classColors,
    required this.classNames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      background: Paint()..color = Colors.red,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final detection in detections) {
      final color = classColors[detection.diseaseName] ?? Colors.blue;
      final displayName = classNames[detection.diseaseName] ?? detection.diseaseName;
      
      paint.color = color;

      final rect = Rect.fromLTRB(
        detection.bbox.xMin * size.width,
        detection.bbox.yMin * size.height,
        detection.bbox.xMax * size.width,
        detection.bbox.yMax * size.height,
      );

      canvas.drawRect(rect, paint);

      final label = '$displayName ${(detection.confidence * 100).toStringAsFixed(1)}%';
      textPainter.text = TextSpan(text: label, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 25));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}