import 'package:tomate_detection_app/core/constants/model_info.dart';
import 'package:tomate_detection_app/core/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tomate_detection_app/features/authentication/bloc/auth_bloc.dart';
import 'package:tomate_detection_app/features/authentication/bloc/auth_event.dart';
import 'package:tomate_detection_app/features/authentication/data/models/user_model.dart';
import 'package:tomate_detection_app/core/services/database_service.dart';
import 'package:tomate_detection_app/core/theme/theme_controller.dart';

class ProfilePage extends StatefulWidget {
  final UserModel? user;
  const ProfilePage({super.key, this.user});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _wifiSync = true;
  bool _highContrast = false;
  String _inferenceMode = InferenceSettings.mode; // auto | edge
  int _pending = 0;
  final _db = DatabaseService();

  @override
  void initState(){ super.initState(); _loadPending(); }

  Future<void> _loadPending() async {
    try{
      final list=await _db.getPendingDiagnostics();
      setState(()=> _pending=list.length);
    }catch(_){}
  }

  Future<void> _setMode(String? m) async {
    if (m == null) return;
    await InferenceSettings.save(m);
    setState(() => _inferenceMode = m);
  }

  Future<void> _syncNow() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sincronizando...")));
    final n = await SyncService.syncPending();
    await _loadPending();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(n > 0 ? "$n registro(s) subidos al servidor" : "No se pudo conectar con el servidor")));
  }

  @override
  Widget build(BuildContext context){
    final c = AppColors.of(context);
    final user=widget.user;
    final name=user?.name ?? "Fray Benjamin Kana Chullo";
    final email=user?.email ?? "fray.kana@upeu.edu.pe";
    final role=user?.role ?? "Ingeniero Agrónomo / Técnico";

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Título
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Perfil y Configuración", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
            IconButton(onPressed: (){}, icon: Icon(Icons.info_outline_rounded, color: c.textDim, size: 20), style: IconButton.styleFrom(backgroundColor: c.cardAlt)),
          ]),
          const SizedBox(height: 16),
          // User Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
            child: Row(children: [
              Stack(children: [
                Container(width: 64,height: 64, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.primary, width: 2), image: const DecorationImage(image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuDh5wAgyiOZzLXxYJ1zZCCW_6G_uDNXv1U9rxfwQigdYjgBQ6mEoUe5hr_4WFI5LVrpjO-Mh67_7oa5ynaNIYXYU6p5kFcO5mNPsF5dahJKk-fV4OuiqkFKZoqRT8DMUTg3mR5iSbQeWNO7u8uuXJJEu7D3VyPM-rE0XgSK5s6pPcv8FSJ_CS_E10yhc-5KDc7MDq6kaOGvGmH5GmePYmIjUAkwkH7yJhJfCdKP0KdbxE3-w3fQSmO4Nw"), fit: BoxFit.cover))),
                Positioned(bottom: 0,right: 0, child: Container(width: 14,height: 14, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle, border: Border.all(color: c.card, width: 2)))),
              ]),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: c.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(role, style: GoogleFonts.inter(fontSize: 11, color: c.primary)),
                const SizedBox(height: 2),
                Row(children: [Icon(Icons.location_on_rounded, color: c.textDim, size: 14), const SizedBox(width: 4), Expanded(child: Text(email.contains("@")? "Fundo El Pedregal - Majes" : email, style: GoogleFonts.inter(fontSize: 11, color: c.textDim), maxLines: 1, overflow: TextOverflow.ellipsis))]),
              ])),
              IconButton(onPressed: (){}, icon: Icon(Icons.edit_rounded, color: c.textDim, size: 18), style: IconButton.styleFrom(backgroundColor: c.cardAlt)),
            ]),
          ),
          const SizedBox(height: 20),
          // AI Inference
          Text("Motor de Inferencia de IA".toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c.textDim, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
            child: Column(children: [
              _radioTile(title: "Automático (recomendado)", subtitle: "Servidor con internet • Celular sin internet", value: "auto", group: _inferenceMode, onChanged: _setMode, icon: Icons.cloud_sync_rounded, subtitleColor: c.primary),
              Divider(height: 1, color: c.border),
              _radioTile(title: "Solo en el celular", subtitle: "Sin enviar fotos al analizar • Se sincronizan después", value: "edge", group: _inferenceMode, onChanged: _setMode, icon: Icons.offline_bolt_rounded, subtitleColor: c.textDim),
              Divider(height: 1, color: c.border),
              Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Icon(Icons.model_training_rounded, color: c.textDim, size: 20), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Versión del Modelo", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.text)), Text("${ModelInfo.label} • ${ModelInfo.name}${ModelInfo.accuracyMobile == null ? '' : ' • acierto ${(ModelInfo.accuracyMobile! * 100).toStringAsFixed(0)}%'}", style: GoogleFonts.inter(fontSize: 11, color: c.textDim))])]),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          // Sync
          Text("Sincronización y Almacenamiento".toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c.textDim, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
            child: Column(children: [
              Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                // Expanded: en pantallas angostas el texto baja de linea en vez de desbordar
                Expanded(child: Row(children: [Icon(Icons.wifi_rounded, color: c.textDim, size: 20), const SizedBox(width: 10), Expanded(child: Text("Sincronizar automáticamente en Wi-Fi", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.text)))])),
                Switch(value: _wifiSync, onChanged: (v)=> setState(()=> _wifiSync=v), activeColor: c.primary),
              ])),
              Divider(height: 1, color: c.border),
              Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Row(children: [Icon(Icons.cloud_upload_rounded, color: c.textDim, size: 20), const SizedBox(width: 10), Expanded(child: Text("$_pending registros pendientes", style: GoogleFonts.inter(fontSize: 12, color: c.text)))])),
                Icon(_pending==0? Icons.check_circle_rounded: Icons.pending_rounded, color: _pending==0? c.primary: const Color(0xFFF59E0B), size: 20),
              ])),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.cardAlt, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))), child: Row(children: [
                Expanded(child: ElevatedButton(onPressed: _pending==0? null: _syncNow, child: Text("Sincronizar Ahora", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)), style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary, padding: const EdgeInsets.symmetric(vertical: 12)))),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          // Field Preferences
          Text("Preferencias de Campo".toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c.textDim, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
            child: Column(children: [
              Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Icon(Icons.contrast_rounded, color: c.textDim, size: 20), const SizedBox(width: 10), Text("Modo Alto Contraste (Exteriores)", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.text))]),
                Switch(value: _highContrast, onChanged: (v)=> setState(()=> _highContrast=v), activeColor: c.primary),
              ])),
              Divider(height: 1, color: c.border),
              ListTile(
                leading: Icon(Icons.language_rounded, color: c.textDim),
                title: Text("Idioma", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.text)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text("Español", style: GoogleFonts.inter(fontSize: 12, color: c.textDim)), Icon(Icons.expand_more_rounded, color: c.textDim)]),
                onTap: (){},
              ),
            ]),
          ),
          const SizedBox(height: 24),
          // Logout
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: ()=> _confirmLogout(context),
            icon: Icon(Icons.logout_rounded, color: c.danger),
            label: Text("Cerrar Sesión", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c.danger)),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFF93000A)), backgroundColor: const Color(0xFF93000A).withValues(alpha: 0.15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
          const SizedBox(height: 24),
          Center(child: Text("Tomate AI v1.0.4 - UPeU Research Project", style: GoogleFonts.inter(fontSize: 11, color: c.textDim))),
        ]),
      )),
    );
  }

  Widget _radioTile({required String title, required String subtitle, required String value, required String group, required Function(String?) onChanged, required IconData icon, required Color subtitleColor}){
    final c = AppColors.of(context);
    final selected=value==group;
    return InkWell(
      onTap: ()=> onChanged(value),
      child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 20,height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected? c.primary: c.border, width: 2)), child: selected? Center(child: Container(width: 10,height: 10, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle))): null),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Row(children: [Icon(icon, color: subtitleColor, size: 14), const SizedBox(width: 4), Expanded(child: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: c.textDim)))]),
        ])),
      ])),
    );
  }

  void _confirmLogout(BuildContext context){
    final c = AppColors.of(context);
    showDialog(context: context, builder: (_)=> AlertDialog(
      backgroundColor: c.card,
      title: Text("Cerrar Sesión", style: GoogleFonts.inter(color: c.text)),
      content: Text("¿Seguro que quieres salir?", style: GoogleFonts.inter(color: c.textDim)),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(context), child: Text("Cancelar", style: GoogleFonts.inter(color: c.textDim))),
        ElevatedButton(onPressed: (){
          context.read<AuthBloc>().add(LogoutRequested());
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/login');
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF93000A)), child: Text("Salir", style: GoogleFonts.inter(color: Colors.white))),
      ],
    ));
  }
}
