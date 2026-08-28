import 'package:flutter/material.dart';

class ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  const ConnectivityBanner({super.key, required this.isOnline, this.isSyncing = false, this.pendingCount = 0});

  @override
  Widget build(BuildContext context) {
    if (isOnline && !isSyncing) return const SizedBox.shrink();
    Color bg = isSyncing ? Colors.amber : (isOnline ? Colors.green : Colors.red);
    String text = isSyncing ? "Sincronizando..." : (isOnline ? "Online" : "Offline — $pendingCount en cola");
    IconData icon = isSyncing ? Icons.sync : (isOnline ? Icons.wifi : Icons.wifi_off);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }
}
