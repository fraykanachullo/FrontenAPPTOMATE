import 'package:flutter/material.dart';

// Nombres y colores de las 5 clases del modelo (best.pt).
// Fuente unica para Resultado e Historial, asi ambos muestran lo mismo.
class DiseaseClasses {
  static const labels = {
    'mildiu': 'Mildiu',
    'mosca_blanca': 'Mosca Blanca',
    'oidio': 'Oídio',
    'polilla': 'Polilla',
    'sana': 'Hoja Sana',
  };

  static const colors = {
    'mildiu': Color(0xFFEF4444),
    'mosca_blanca': Color(0xFFEAB308),
    'oidio': Color(0xFFF59E0B),
    'polilla': Color(0xFFFF6B35),
    'sana': Color(0xFF10B981),
  };
}
