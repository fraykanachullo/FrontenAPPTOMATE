import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tomate_detection_app/core/constants/app_constants.dart';

class DiagnosticDetailPage extends StatelessWidget {
  final Map<String, dynamic> diagnostic;
  const DiagnosticDetailPage({super.key, required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    final dets = (diagnostic["detections"] as List? ?? []);
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle diagnóstico")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (diagnostic["image_url"] != null)
            ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: diagnostic["image_url"], placeholder: (_,__) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())), errorWidget: (_,__,___) => Container(height: 200, color: Colors.grey[300], child: const Icon(Icons.broken_image)), fit: BoxFit.contain)),
          const SizedBox(height: 16),
          Text("Resumen: ${diagnostic["summary"]}", style: TextStyle(color: AppColors.primaryEmerald)),
          const SizedBox(height: 12),
          ...dets.map((d) => Card(child: ListTile(title: Text(d["disease_label"] ?? ""), subtitle: Text("Conf: ${(d["confidence_score"] ?? 0).toString()} • ${d["severity_level"] ?? ""}"), trailing: Text(d["disease_name_spanish"] ?? "")))),
          if (dets.isEmpty) const Card(child: ListTile(title: Text("Sin detecciones — Planta aparentemente sana"), tileColor: Color(0xFFE8F5E9))),
        ]),
      ),
    );
  }
}
