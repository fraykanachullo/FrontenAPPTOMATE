import 'package:flutter/material.dart';

// B.11 stub — reemplazar con flutter_map + clustering + offline tiles
class DiagnosticMapPage extends StatelessWidget {
  const DiagnosticMapPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa")),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.map, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        const Text("Mapa interactivo — pendiente flutter_map"),
        const SizedBox(height: 8),
        Text("Centro: Fundo El Pedregal (-16.3547, -72.2203)", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ])),
    );
  }
}
