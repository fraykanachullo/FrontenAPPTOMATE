import 'package:flutter/material.dart';
import 'package:tomate_detection_app/core/constants/api_constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool highContrast = false;
  final ipCtrl = TextEditingController(text: ApiConstants.baseUrl);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajustes")),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SwitchListTile(title: const Text("Modo alto contraste (campo)"), subtitle: const Text("Fondo negro, amarillo #FFD600"), value: highContrast, onChanged: (v) => setState(() => highContrast = v)),
        const Divider(),
        TextField(controller: ipCtrl, decoration: const InputDecoration(labelText: "Base URL backend", hintText: "http://10.0.2.2:8000"),),
        const SizedBox(height: 8),
        const Text("Reinicia la app tras cambiar IP", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const Divider(),
        ListTile(title: const Text("Versión"), subtitle: const Text("1.0.0+1 — AgriScan Pro UPEU")),
        ListTile(title: const Text("Acerca"), subtitle: const Text("Tesis UPEU — Detección tomate en Majes")),
      ]),
    );
  }
}
