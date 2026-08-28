import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomate_detection_app/core/services/database_service.dart';
import 'package:tomate_detection_app/core/theme/theme_controller.dart';
import 'package:tomate_detection_app/features/diagnosis/presentation/pages/scanner_page.dart' show Detection, BBox;
import 'package:tomate_detection_app/features/diagnosis/presentation/pages/diagnostic_result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _db = DatabaseService();
  String _search = "";
  String _filter = "Todos";
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  final _filters = ["Todos","Oidio","Mildiu","Mosca Blanca","Pendientes","Solo Graves"];
  final _filterMap = {"Todos": null, "Oidio":"oidio", "Mildiu":"mildiu", "Mosca Blanca":"mosca_blanca", "Pendientes":"pendiente", "Solo Graves":"grave"};

  @override
  void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    setState(()=> _loading=true);
    try{
      _all = await _db.getDiagnostics();
      _applyFilters();
    }catch(e){ debugPrint("history $e"); }
    setState(()=> _loading=false);
  }

  void _applyFilters(){
    var list = List<Map<String, dynamic>>.from(_all);
    if(_search.isNotEmpty){
      final q=_search.toLowerCase();
      list = list.where((m)=> (m['disease']??"").toString().toLowerCase().contains(q) || (m['created_at']??"").toString().toLowerCase().contains(q)).toList();
    }
    if(_filter!="Todos"){
      final v=_filterMap[_filter];
      if(v=="oidio"||v=="mildiu"||v=="mosca_blanca"){
        list = list.where((m)=> m['disease']==v).toList();
      } else if(v=="pendiente"){
        list = list.where((m)=> m['is_synced']==0).toList();
      } else if(v=="grave"){
        list = list.where((m)=> (m['confidence']??0) > 0.75).toList();
      }
    }
    if(_selectedDate!=null){
      list = list.where((m){
        try{
          final d=DateTime.parse(m['created_at']);
          return d.year==_selectedDate!.year && d.month==_selectedDate!.month && d.day==_selectedDate!.day;
        }catch(_){ return false; }
      }).toList();
    }
    _filtered=list;
  }

  Future<void> _pickDate() async {
    final c = AppColors.of(context);
    final d=await showDatePicker(context: context, initialDate: _selectedDate??DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now(), builder: (bctx,w)=> Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: c.primary)), child: w!));
    if(d!=null){ setState(()=> _selectedDate=d); _applyFilters(); setState((){}); }
  }

  Future<void> _openDetail(Map<String,dynamic> diag) async {
    final c = AppColors.of(context);
    // Cargar imagen
    Uint8List? bytes;
    final path=diag['image_path'] as String?;
    if(path!=null && await File(path).exists()){
      bytes=await File(path).readAsBytes();
    } else {
      // placeholder 1x1
      bytes=Uint8List(0);
    }
    if(bytes.isEmpty){
      // si no hay imagen, usa placeholder color
      bytes=Uint8List.fromList(List.filled(100, 0));
    }
    final disease=diag['disease']??'sana';
    final conf=(diag['confidence'] as num?)?.toDouble() ?? 0.9;
    final det=Detection(diseaseName: disease, confidence: conf, bbox: BBox(xMin: 0.15, yMin: 0.2, xMax: 0.75, yMax: 0.7), classIndex: 0);
    if(!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_)=> DiagnosticResultPage(imageBytes: bytes!, detections: [det], displayNames: const {'mildiu':'Mildiu','oidio':'Oídio','mosca_blanca':'Mosca Blanca','polilla':'Polilla','sana':'Hoja Sana'}, colors: {'mildiu':c.danger,'oidio':const Color(0xFFF59E0B),'mosca_blanca':const Color(0xFFEAB308),'polilla':const Color(0xFFFF0000),'sana':c.primary})));
  }

  Map<String, List<Map<String,dynamic>>> _groupByDate(){
    final map=<String, List<Map<String,dynamic>>>{};
    for(var d in _filtered){
      try{
        final dt=DateTime.parse(d['created_at']);
        final now=DateTime.now();
        final today=DateTime(now.year, now.month, now.day);
        final dtDay=DateTime(dt.year, dt.month, dt.day);
        String key;
        if(dtDay==today) key="HOY - ${dt.day} DE ${_monthName(dt.month).toUpperCase()}";
        else if(dtDay==today.subtract(const Duration(days:1))) key="AYER";
        else key="${dt.day} DE ${_monthName(dt.month).toUpperCase()}";
        map.putIfAbsent(key, ()=> []).add(d);
      }catch(_){
        map.putIfAbsent("SIN FECHA", ()=> []).add(d);
      }
    }
    return map;
  }
  String _monthName(int m)=> ["","ENERO","FEBRERO","MARZO","ABRIL","MAYO","JUNIO","JULIO","AGOSTO","SEPTIEMBRE","OCTUBRE","NOVIEMBRE","DICIEMBRE"][m];

  @override
  Widget build(BuildContext context){
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.menu_rounded, color: c.primary), onPressed: (){}),
        title: Text("Historial de Escaneos", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary)),
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.sync_rounded, color: c.primary), onPressed: _load)],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: c.border)),
      ),
      body: _loading ? Center(child: CircularProgressIndicator(color: c.primary)) : RefreshIndicator(color: c.primary, onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
        // Search + calendar filter
        Row(children: [
          Expanded(child: Container(
            height: 48,
            decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
            child: TextField(
              onChanged: (v){ _search=v; _applyFilters(); setState((){}); },
              style: GoogleFonts.inter(color: c.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Buscar por plaga, lote o sector...", hintStyle: GoogleFonts.inter(color: c.textDim, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: c.textDim, size: 20),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(width: 48,height: 48, decoration: BoxDecoration(color: _selectedDate!=null? c.primary: c.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _selectedDate!=null? c.primary: c.border)),
              child: Icon(Icons.calendar_month_rounded, color: _selectedDate!=null? c.onPrimary: c.textDim, size: 22)),
          ),
        ]),
        if(_selectedDate!=null) Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [Chip(label: Text("${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}", style: GoogleFonts.inter(fontSize: 11, color: c.onPrimary)), backgroundColor: c.primary, deleteIcon: const Icon(Icons.close_rounded, size: 16), onDeleted: (){ setState(()=> _selectedDate=null); _applyFilters(); setState((){}); }), const SizedBox(width: 8), TextButton(onPressed: (){ setState(()=> _selectedDate=null); _applyFilters(); setState((){}); }, child: Text("Limpiar", style: GoogleFonts.inter(fontSize: 12, color: c.primary)))])),
        const SizedBox(height: 16),
        // Filter chips
        SizedBox(height: 36, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _filters.length, separatorBuilder: (_,__)=> const SizedBox(width: 8), itemBuilder: (_,i){
          final f=_filters[i]; final sel=_filter==f;
          return ChoiceChip(
            label: Text(f, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sel? c.onPrimary: c.text)),
            selected: sel,
            selectedColor: c.primary,
            backgroundColor: c.cardAlt,
            side: BorderSide(color: sel? c.primary: c.border),
            onSelected: (_){ setState(()=> _filter=f); _applyFilters(); setState((){}); },
          );
        })),
        const SizedBox(height: 12),
        Text("Mostrando ${_filtered.length} registros${_selectedDate!=null ? " del ${_selectedDate!.day}/${_selectedDate!.month}" : " de este mes"}", style: GoogleFonts.inter(fontSize: 11, color: c.textDim)),
        const SizedBox(height: 16),
        if(_filtered.isEmpty) _empty(context)
        else ..._groupByDate().entries.map((e)=> Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.key, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c.textDim, letterSpacing: 0.8)),
          Container(height: 1, color: c.border, margin: const EdgeInsets.only(top: 6, bottom: 12)),
          ...e.value.map((diag)=> _card(context, diag)),
          const SizedBox(height: 16),
        ])),
      ])),
    );
  }

  Widget _empty(BuildContext context){
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Column(children: [
        Icon(Icons.search_off_rounded, color: c.textDim, size: 48),
        const SizedBox(height: 12),
        Text("No se encontraron registros", style: GoogleFonts.inter(color: c.textDim)),
        const SizedBox(height: 8),
        Text("Prueba con otro filtro o realiza un escaneo", style: GoogleFonts.inter(fontSize: 12, color: c.textDim.withValues(alpha: 0.7)), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _card(BuildContext context, Map<String,dynamic> diag){
    final c = AppColors.of(context);
    final disease=diag['disease']??'sana';
    final conf=(diag['confidence'] as num?)?.toDouble() ?? 0.0;
    final date=DateTime.tryParse(diag['created_at']??"") ?? DateTime.now();
    final displayName={'mildiu':'Mildiu - Phytophthora','oidio':'Oidio','mosca_blanca':'Mosca Blanca','polilla':'Polilla','sana':'Hoja Sana'}[disease] ?? disease;
    final isSevere=conf>0.75;
    final isModerate=conf>0.55 && conf<=0.75;
    final badgeColor=isSevere? c.danger: isModerate? const Color(0xFFFC7C78): const Color(0xFFFBBF24);
    final badgeBg=isSevere? c.danger.withValues(alpha: 0.15): isModerate? const Color(0xFFFC7C78).withValues(alpha: 0.15): const Color(0xFFFBBF24).withValues(alpha: 0.15);
    final statusLabel=isSevere? "Severo": isModerate? "Moderado": disease=='sana'? "Sano":"Leve";
    final treated = diag['is_synced']==1;
    final imagePath=diag['image_path'] as String?;
    final hasImage=imagePath!=null && File(imagePath).existsSync();

    return GestureDetector(
      onTap: ()=> _openDetail(diag),
      onHorizontalDragEnd: (d){ if(d.primaryVelocity!=null && d.primaryVelocity! < -500) _openDetail(diag); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: hasImage ? Image.file(File(imagePath!), width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___)=> _iconPlaceholder(context, disease)) : _iconPlaceholder(context, disease)),
            if(disease!='sana') Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: c.danger.withValues(alpha: 0.8), width: 2)))),
            if(conf>0) Positioned(bottom: 4, right: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.bg.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6)), child: Text("${(conf*100).toStringAsFixed(1)}%", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: c.primary)))),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(displayName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: c.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Icon(disease=='sana'? Icons.check_circle_rounded: isSevere? Icons.error_rounded: Icons.warning_amber_rounded, color: disease=='sana'? c.primary: badgeColor, size: 18),
            ]),
            const SizedBox(height: 2),
            Text("Sector ${diag['diagnostic_id']?.toString().substring(0,2) ?? "A"} • ${_hhmm(date)}", style: GoogleFonts.inter(fontSize: 11, color: c.textDim)),
            const SizedBox(height: 8),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)), child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor))),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: treated? c.primary.withValues(alpha: 0.15): c.border, borderRadius: BorderRadius.circular(6), border: treated? null: Border.all(color: c.border)), child: Text(treated? "Tratado":"Pendiente", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: treated? c.primary: c.textDim))),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _iconPlaceholder(BuildContext context, String disease){
    final c = AppColors.of(context);
    IconData icon;
    switch(disease){
      case 'mildiu': icon=Icons.warning_rounded; break;
      case 'oidio': icon=Icons.cloud_rounded; break;
      case 'mosca_blanca': icon=Icons.bug_report_rounded; break;
      case 'polilla': icon=Icons.pest_control_rounded; break;
      default: icon=Icons.eco_rounded;
    }
    return Container(width: 80, height: 80, color: c.card, child: Icon(icon, color: c.textDim, size: 28));
  }

  String _hhmm(DateTime d){
    final h=d.hour%12==0?12:d.hour%12;
    final m=d.minute.toString().padLeft(2,'0');
    final ap=d.hour>=12?"PM":"AM";
    return "$h:$m $ap";
  }
}
