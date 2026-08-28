import 'package:flutter/material.dart';

class QualityWarningBanner extends StatelessWidget {
  final String message;
  final bool isOverexposed;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  const QualityWarningBanner({super.key, required this.message, required this.isOverexposed, required this.onRetry, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final color = isOverexposed ? Colors.amber : Colors.orange;
    final icon = isOverexposed ? Icons.wb_sunny : Icons.brightness_3;
    return Container(
      color: color.withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Icon(icon, color: Colors.black87),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600))),
        TextButton(onPressed: onRetry, child: const Text("Reintentar", style: TextStyle(color: Colors.black87))),
        TextButton(onPressed: onContinue, child: const Text("Continuar", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}
