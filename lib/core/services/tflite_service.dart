//import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteService {
  static final TfliteService _instance = TfliteService._internal();
  factory TfliteService() => _instance;
  TfliteService._internal();

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isLoaded = false;
  final int inputSize = 320;

  Future<void> loadModel() async {
    try {
      debugPrint('🔄 Cargando modelo TFLite...');
      
      _interpreter = await Interpreter.fromAsset('assets/models/best_int8.tflite');
      _labels = await _loadLabels();
      
      final inputShape = _interpreter!.getInputTensor(0).shape;
      debugPrint('✅ Modelo TFLite cargado: Input shape = $inputShape');
      debugPrint('✅ Etiquetas cargadas: ${_labels!.length}');
      
      _isLoaded = true;
    } catch (e) {
      debugPrint('❌ Error al cargar modelo TFLite: $e');
      throw Exception('Error al cargar modelo TFLite: $e');
    }
  }

  Future<List<String>> _loadLabels() async {
    try {
      final String data = await rootBundle.loadString('assets/models/labels.txt');
      return data.split('\n').where((line) => line.isNotEmpty).toList();
    } catch (e) {
      return ['mildiu', 'mosca_blanca', 'oidio', 'polilla', 'sana'];
    }
  }

  Future<List<Detection>> predict(img.Image image) async {
    if (!_isLoaded) await loadModel();

    try {
      final input = await _preprocessImage(image);
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('📊 Output shape: $outputShape');

      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0);
      _interpreter!.run(input, output);

      return _postprocessResults(output, outputShape);
    } catch (e) {
      debugPrint('❌ Error en inferencia TFLite: $e');
      return [];
    }
  }

  Future<Float32List> _preprocessImage(img.Image image) async {
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    final input = Float32List(inputSize * inputSize * 3);
    int index = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = pixel.r / 255.0;
        input[index++] = pixel.g / 255.0;
        input[index++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  List<Detection> _postprocessResults(List<dynamic> output, List<int> shape) {
    final detections = <Detection>[];
    
    try {
      final numDetections = shape[1];
      final numFeatures = shape[2];
      //final numClasses = _labels!.length;

      for (int i = 0; i < numDetections; i++) {
        final idx = i * numFeatures;
        final confidence = output[idx + 4];
        
        if (confidence > 0.5) {
          final classIndex = output[idx + 5].toInt();
          if (classIndex < _labels!.length) {
            final x = output[idx];
            final y = output[idx + 1];
            final w = output[idx + 2];
            final h = output[idx + 3];
            
            detections.add(Detection(
              diseaseName: _labels![classIndex],
              confidence: confidence,
              bbox: BBox(
                xMin: (x - w / 2).clamp(0.0, 1.0),
                yMin: (y - h / 2).clamp(0.0, 1.0),
                xMax: (x + w / 2).clamp(0.0, 1.0),
                yMax: (y + h / 2).clamp(0.0, 1.0),
              ),
              classIndex: classIndex,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error en postprocesado: $e');
    }

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return detections;
  }

  bool get isLoaded => _isLoaded;
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