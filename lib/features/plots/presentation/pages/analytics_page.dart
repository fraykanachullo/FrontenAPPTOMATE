import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomate_detection_app/core/services/database_service.dart';
import 'package:tomate_detection_app/core/theme/theme_controller.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _db = DatabaseService();
  bool _loading = true;
  int _total = 0, _disease = 0, _healthy = 0;
  Map<String,int> _stats = {};
  String _period = "Este Mes";
  final _periods = ["Semana","Este Mes","Campaña 2026"];

  @override
  void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    setState(()=> _loading=true);
    try{
      _total=await _db.getTotalDiagnostics();
      _disease=await _db.getDiseaseCount();
      _healthy=await _db.getHealthyCount();
      _stats=await _db.getDiseaseStats();
    }catch(_){}
    setState(()=> _loading=false);
  }

  @override
  Widget build(BuildContext context){
    final c = AppColors.of(context);
    if(_loading) return Scaffold(backgroundColor: c.bg, body: Center(child: CircularProgressIndicator(color: c.primary)));
    // Si no hay datos, usar demo del diseño
    final totalDisplay = _total > 0 ? _total : 1028;
    final avgInfection = _total>0 ? (_disease/_total*100) : 24.5;
    // Mapear stats a colores diseño
    final oidio = _stats['oidio'] ?? (_total==0? 430:0);
    final mildiu = _stats['mildiu'] ?? (_total==0? 310:0);
    final mosca = _stats['mosca_blanca'] ?? (_total==0? 185:0);
    final sana = _stats['sana'] ?? (_total==0? 103:0);
    // Dominante
    String dom="Oidio"; Color domColor=const Color(0xFFF59E0B); int domPct=42;
    if(_stats.isNotEmpty){
      final sorted=_stats.entries.where((e)=>e.key!='sana').toList()..sort((a,b)=>b.value.compareTo(a.value));
      if(sorted.isNotEmpty){
        final e=sorted.first;
        dom=e.key=="oidio"?"Oidio": e.key=="mildiu"?"Mildiu": e.key=="mosca_blanca"?"Mosca B.": e.key;
        domPct= (e.value/_total*100).round();
        domColor= e.key=="mildiu"? c.danger: e.key=="mosca_blanca"? const Color(0xFFEAB308): const Color(0xFFF59E0B);
      }
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(child: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(children: [
            _header(c),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 12),
                _filters(c),
                const SizedBox(height: 16),
                _kpis(c, totalDisplay, avgInfection, dom, domColor, domPct),
                const SizedBox(height: 16),
                _doughnut(c, oidio: domPct, mildiu: 30, mosca: 18, sana: 10),
                const SizedBox(height: 16),
                _lineChart(c),
                const SizedBox(height: 16),
                _mapCard(c),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exportar PDF — próximamente"), backgroundColor: c.primary)),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text("Exportar PDF", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: BorderSide(color: const Color(0xFF6FFBBE))),
                )),
              ]),
            ),
          ]),
        ),
      ])),
    );
  }

  Widget _header(AppColors c){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: c.bg, border: Border(bottom: BorderSide(color: c.border))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Icon(Icons.agriculture_rounded, color: c.primary, size: 22), const SizedBox(width: 8), Text("Analítica de Plagas", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary))]),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border)), child: Row(children: [Container(width: 8,height: 8, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)), const SizedBox(width: 6), Text("Edge AI - Offline Active", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: c.textDim))])),
      ]),
    );
  }

  Widget _filters(AppColors c){
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _periods.map((p){
      final sel=_period==p;
      return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
        label: Text(p, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sel? c.onPrimary: c.textDim)),
        selected: sel,
        selectedColor: c.primary,
        backgroundColor: c.card,
        side: BorderSide(color: sel? c.primary: c.border),
        onSelected: (_)=> setState(()=> _period=p),
      ));
    }).toList()));
  }

  Widget _kpis(AppColors c, int total, double avg, String dom, Color domColor, int domPct){
    return Column(children: [
      Row(children: [
        Expanded(child: _kpiCard(c, label: "Total Scans", value: total.toString(), icon: Icons.qr_code_scanner_rounded, iconColor: c.primary)),
        const SizedBox(width: 12),
        Expanded(child: _kpiCard(c, label: "Avg Infection", value: "${avg.toStringAsFixed(1)}%", valueColor: c.danger, icon: Icons.trending_up_rounded, iconColor: c.danger)),
      ]),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border)),
          child: Row(children: [
            Container(width: 4, height: 56, decoration: BoxDecoration(color: domColor, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Dominant Pest", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: c.textDim, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(dom, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: domColor)),
              const SizedBox(height: 6),
              Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: domPct/100, minHeight: 6, backgroundColor: c.bg, valueColor: AlwaysStoppedAnimation(domColor)))), const SizedBox(width: 8), Text("$domPct%", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: domColor))]),
            ])),
          ]),
        ),
      ),
    ]);
  }

  Widget _kpiCard(AppColors c, {required String label, required String value, Color? valueColor, required IconData icon, required Color iconColor}){
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: c.textDim, letterSpacing: 0.8)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: valueColor?? c.text)),
          Icon(icon, color: iconColor, size: 20),
        ]),
      ]),
    );
  }

  Widget _doughnut(AppColors c, {required int oidio, required int mildiu, required int mosca, required int sana}){
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Prevalencia de Enfermedades", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
        const SizedBox(height: 16),
        Center(child: SizedBox(width: 200, height: 200, child: CustomPaint(painter: _DoughnutPainter(c: c, oidio: oidio, mildiu: mildiu, mosca: mosca, sana: sana), size: const Size(200,200)))),
        const SizedBox(height: 16),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.9, children: [
          _legend(c, "Oidio", oidio, const Color(0xFFF59E0B), isSmall: true),
          _legend(c, "Mildiu", mildiu, c.danger, isSmall: true),
          _legend(c, "Mosca B.", mosca, const Color(0xFFEAB308)),
          _legend(c, "Sana", sana, c.primary),
        ]),
      ]),
    );
  }

  Widget _legend(AppColors c, String label, int pct, Color color, {bool isSmall=false}){
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: isSmall? 6: 8),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Container(width: isSmall? 8:10, height: isSmall? 8:10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)])), const SizedBox(width: 6), Text(label, style: GoogleFonts.inter(fontSize: isSmall? 10: 11, fontWeight: FontWeight.w600, color: c.text))]),
        Text("$pct%", style: GoogleFonts.inter(fontSize: isSmall? 11: 12, fontWeight: FontWeight.w700, color: c.text)),
      ]),
    );
  }

  Widget _lineChart(AppColors c){
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Evolución Semanal de Incidencia", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
        const SizedBox(height: 12),
        SizedBox(height: 160, child: CustomPaint(painter: _LineChartPainter(c), size: const Size(double.infinity, 160))),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ["W1","W2","W3","W4","W5","W6","W7"].map((e)=> Text(e, style: GoogleFonts.inter(fontSize: 10, color: c.textDim))).toList()),
      ]),
    );
  }

  Widget _mapCard(AppColors c){
    return Container(
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Stack(children: [
            Image.network("https://lh3.googleusercontent.com/aida-public/AB6AXuBJuz_ahj1Ay79kblATcpfiar_TMixm5QfiG4W9a0HLdyg3Tb0x8fb0snicMgAKQDsjuYz21604U2Wt709vCtz58TacrWN55x_958i2_pNTIOJw5wDN2Kj6R6J6EvHl-bv6j4U264WKlF0jbVMTFPsFDRlA17BzyjsAws3tzmRmj5KFY2ykznFqORMTHo2tvjVFvLRD8cvv1wihNA5-G_UzzgfrfHiQjtNKi8GBgAc4fvh1quTdGb3MjA", width: double.infinity, height: 180, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(height: 180, color: c.bg, child: Icon(Icons.map_rounded, color: c.textDim, size: 40))),
            Positioned(top: 40, left: 60, child: _pulseDot(c.danger)),
            const Positioned(top: 80, left: 140, child: _dot(Color(0xFFF59E0B))),
            Positioned(bottom: 40, right: 60, child: _dot(c.primary)),
            Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: c.bg.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.primary)), child: Row(children: [Icon(Icons.location_on_rounded, color: c.primary, size: 14), const SizedBox(width: 4), Text("Fundo El Pedregal", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c.primary))]))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Fundo El Pedregal", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)), const SizedBox(height: 2), Text("Sector A - Lote 14 • Majes", style: GoogleFonts.inter(fontSize: 12, color: c.textDim))]),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: c.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.danger)), child: Text("Alta Alerta", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c.danger))),
            ]),
            const SizedBox(height: 14),
            Text("Zona Crítica (Oidio) — Requiere intervención inmediata", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 6),
            _mapRow(c, label: "0.5 Hectáreas afectadas", value: "75%", pct: 0.75, color: c.danger),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [Icon(Icons.schedule_rounded, color: c.textDim, size: 16), const SizedBox(width: 6), Text("Último Escaneo", style: GoogleFonts.inter(fontSize: 12, color: c.textDim))]),
              Text("Hace 2 horas • Hoy 10:30", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.text)),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.map_rounded, size: 18), label: Text("Ver Mapa Completo", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A211D), foregroundColor: c.primary, side: BorderSide(color: c.primary), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
          ]),
        ),
      ]),
    );
  }

  Widget _mapRow(AppColors c, {required String label, required String value, required double pct, required Color color}){
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: GoogleFonts.inter(fontSize: 11, color: c.textDim)), Text(value, style: GoogleFonts.inter(fontSize: 11, color: c.text))]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, minHeight: 4, backgroundColor: c.bg, valueColor: AlwaysStoppedAnimation(color))),
    ]);
  }
}

class _dot extends StatelessWidget {
  final Color color;
  const _dot(this.color);
  @override
  Widget build(BuildContext context){
    final c = AppColors.of(context);
    return Container(width: 8,height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 1)));
  }
}

class _pulseDot extends StatelessWidget {
  final Color color;
  const _pulseDot(this.color);
  @override
  Widget build(BuildContext context){
    final c = AppColors.of(context);
    return Container(width: 12,height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 2), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8)]));
  }
}

class _DoughnutPainter extends CustomPainter {
  final int oidio, mildiu, mosca, sana;
  final AppColors c;
  _DoughnutPainter({required this.oidio, required this.mildiu, required this.mosca, required this.sana, required this.c});
  @override
  void paint(Canvas canvas, Size size){
    final center=Offset(size.width/2, size.height/2);
    final radius=size.width*0.36;
    final stroke=18.0;
    final total=oidio+mildiu+mosca+sana;
    if(total==0) return;
    final segments=[
      [oidio, const Color(0xFFF59E0B)],
      [mildiu, c.danger],
      [mosca, const Color(0xFFEAB308)],
      [sana, c.primary],
    ];
    double start=-90;
    final paint=Paint()..style=PaintingStyle.stroke..strokeWidth=stroke..strokeCap=StrokeCap.round;
    for(var s in segments){
      final pct=(s[0] as int)/total;
      final sweep=360*pct;
      paint.color=s[1] as Color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start*3.14159/180, sweep*3.14159/180, false, paint);
      start+=sweep;
    }
    // center text
    final tp=TextPainter(text: TextSpan(children: [TextSpan(text: "100%\n", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)), TextSpan(text: "Scans", style: GoogleFonts.inter(fontSize: 10, color: c.textDim))]), textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(center.dx - tp.width/2, center.dy - tp.height/2));
  }
  @override
  bool shouldRepaint(covariant CustomPainter old)=>false;
}

class _LineChartPainter extends CustomPainter {
  final AppColors c;
  _LineChartPainter(this.c);
  @override
  void paint(Canvas canvas, Size size){
    final grid=Paint()..color=c.border.withValues(alpha: 0.4)..strokeWidth=0.5;
    for(int i=0;i<5;i++){ canvas.drawLine(Offset(0, size.height/4*i), Offset(size.width, size.height/4*i), grid); }
    for(int i=0;i<6;i++){ canvas.drawLine(Offset(size.width/5*i, 0), Offset(size.width/5*i, size.height), grid); }
    final path=Path()..moveTo(0, size.height*0.9);
    final points=[Offset(0, size.height*0.9), Offset(size.width*0.15, size.height*0.75), Offset(size.width*0.30, size.height*0.80), Offset(size.width*0.45, size.height*0.60), Offset(size.width*0.60, size.height*0.40), Offset(size.width*0.80, size.height*0.20), Offset(size.width, size.height*0.10)];
    for(int i=0;i<points.length-1;i++){
      final p0=points[i], p1=points[i+1];
      final cp=Offset((p0.dx+p1.dx)/2, p0.dy);
      path.quadraticBezierTo(cp.dx, cp.dy, p1.dx, p1.dy);
    }
    final fillPath=Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    final fillPaint=Paint()..shader=LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.primary.withValues(alpha: 0.3), Colors.transparent]).createShader(Rect.fromLTWH(0,0,size.width,size.height));
    canvas.drawPath(fillPath, fillPaint);
    final linePaint=Paint()..color=c.primary..style=PaintingStyle.stroke..strokeWidth=2..strokeCap=StrokeCap.round;
    canvas.drawPath(path, linePaint);
    final dotPaint=Paint()..color=c.bg..style=PaintingStyle.fill;
    final dotStroke=Paint()..color=c.primary..style=PaintingStyle.stroke..strokeWidth=1.2;
    for(var p in points){ canvas.drawCircle(p, 4, dotPaint); canvas.drawCircle(p, 4, dotStroke); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old)=>false;
}
