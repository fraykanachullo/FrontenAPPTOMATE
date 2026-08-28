import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomate_detection_app/core/theme/theme_controller.dart';

// Hybrid: base último diseño #131313 + Estado General 92% + Tendencias en Perú
class HomePage extends StatelessWidget {
  final Function(int)? onNavigate;
  const HomePage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _topBar(c)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 12),
                _greeting(c),
                const SizedBox(height: 16),
                _agroClimatic(c),
                const SizedBox(height: 12),
                _estadoGeneral(c),
                const SizedBox(height: 12),
                _preventiveAlert(c),
                const SizedBox(height: 16),
                _bentoGrid(context, c),
                const SizedBox(height: 20),
                _recentScan(context, c),
                const SizedBox(height: 20),
                _quickCatalog(context, c),
                const SizedBox(height: 20),
                _weeklyStats(c),
                const SizedBox(height: 20),
                _tendenciasPeru(context, c),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _topBar(AppColors c) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: c.bg, border: Border(bottom: BorderSide(color: c.border, width: 1))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.location_on_rounded, color: c.primary, size: 18),
          const SizedBox(width: 6),
          Text("El Pedregal, Majes", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
        ]),
        Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.border), image: const DecorationImage(image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuCDTZOdC0vV4AP5FLuBOANfdIohdl84Vv4JdD_edKSmh91nQySbMd-Q7DXSgCrnZeZcIF2pSx8EWkCSfIFG8wADpnUjtBXNItdgeh8vvq0qJxs_t1pvwfOX5yR38ASPgkCisBu8K0tMzHrGvPpDoHlLG-6nYLP_xf5ngvO1hBQ-cj2w-4CEC1fo0ctYf01T0hWG9CdWCMn5B85T_P0NSY_RUeaeCK05riiDnXrjtSA1igpFPwvNfkDX"), fit: BoxFit.cover))),
          const SizedBox(width: 10),
          const HighContrastToggle(),
        ]),
      ]),
    );
  }

  Widget _greeting(AppColors c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("¡Hola, Productor!", style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: c.text, height: 1.2)),
      const SizedBox(height: 4),
      Text("Revisión de salud del campo para hoy.", style: GoogleFonts.inter(fontSize: 14, color: c.textDim)),
    ]);
  }

  Widget _agroClimatic(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          const Icon(Icons.thermostat_rounded, color: Color(0xFFFFB95F), size: 28),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("19°C", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: c.text)),
            Text("UV: High | Humidity: 35%", style: GoogleFonts.inter(fontSize: 12, color: c.textDim)),
          ]),
        ]),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFBBCABF), size: 20),
      ]),
    );
  }

  // REEMPLAZA el viejo banner "Tus identificaciones..." → Estado General 92%
  Widget _estadoGeneral(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("ESTADO GENERAL", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c.textDim, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text("Óptimo", style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: c.primary, height: 1)),
          ]),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.primary, width: 6)),
            child: Center(child: Text("92%", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: c.text))),
          ),
        ]),
        const SizedBox(height: 16),
        Container(height: 1, color: c.border),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _npkBar(c: c, label: "Nitrógeno", percent: 0.85, color: c.primary)),
          const SizedBox(width: 12),
          Expanded(child: _npkBar(c: c, label: "Fósforo", percent: 0.60, color: const Color(0xFFFFB95F))),
          const SizedBox(width: 12),
          Expanded(child: _npkBar(c: c, label: "Potasio", percent: 0.90, color: c.primary)),
        ]),
      ]),
    );
  }

  Widget _npkBar({required AppColors c, required String label, required double percent, required Color color}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: c.textDim)),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: c.border, valueColor: AlwaysStoppedAnimation(color))),
    ]);
  }

  Widget _preventiveAlert(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF2A1700), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEE9800).withValues(alpha: 0.3))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_rounded, color: Color(0xFFEE9800), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Preventive Alert", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFFFDDB8))),
          const SizedBox(height: 2),
          Text("High Risk for Oidium (Oidium neolycopersici)", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFFDDB8).withValues(alpha: 0.9))),
        ])),
      ]),
    );
  }

  Widget _bentoGrid(BuildContext context, AppColors c) {
    final cards = <Widget>[
      _bentoCard(c: c, icon: Icons.eco_rounded, label: "Escanear Hoja", subtitle: "Detección YOLO", color: c.primary, onTap: () => onNavigate?.call(1)),
      _bentoCard(c: c, icon: Icons.warning_rounded, label: "Alertas", subtitle: "2 sin revisar", color: const Color(0xFFFFB4AB), badge: true, onTap: () => onNavigate?.call(1)),
      _bentoCard(c: c, icon: Icons.cloud_rounded, label: "Clima", subtitle: "24°C • Lluvia 10%", color: const Color(0xFFFFB95F), onTap: () {}),
    ];
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  Widget _bentoCard({required AppColors c, required IconData icon, required String label, required String subtitle, required Color color, bool badge = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
            if (badge) Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFB4AB), shape: BoxShape.circle)),
          ]),
          const Spacer(),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: c.textDim), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _recentScan(BuildContext context, AppColors c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Recent Scan", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: c.text)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
        child: Column(children: [
          Stack(children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network("https://lh3.googleusercontent.com/aida-public/AB6AXuBz-YpuMc9IKLjSZsGQQBqog4OQcnfimK0qVJOJf3G9QQAelULOEusIv7fZQbi6EStSeMZxfgYAwSY-q-qk9JYuLBkoe3Y2Aizsn5TuzTIOLEcF9bBzpNqVB16pXJOcavpE6g02hM2hpyKoChdKC9S0Ytiqeor788f3Z9Ar5vHQ8vAKXu2Go-_9JUuIJjciXz0LykSPB2argbMEWLYM1YPrt9IQINveNYFsPX50RmRgx9NKYkboYJ7x", height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(height: 160, color: c.cardAlt, child: Icon(Icons.image, color: c.textDim)))),
            Positioned(top: 12, left: 12, child: Container(width: 56, height: 56, decoration: BoxDecoration(border: Border.all(color: c.danger, width: 2), borderRadius: BorderRadius.circular(8), color: c.dangerSoft), child: Icon(Icons.crisis_alert_rounded, color: c.danger))),
          ]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Phytophthora infestans (Mildiu)", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                Text("98.4% Confidence", style: GoogleFonts.inter(fontSize: 11, color: c.textDim)),
              ]),
              Row(children: [Icon(Icons.schedule_rounded, color: c.textDim, size: 14), const SizedBox(width: 4), Text("2 hrs ago", style: GoogleFonts.inter(fontSize: 11, color: c.textDim))]),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _quickCatalog(BuildContext context, AppColors c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Quick Catalog", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: c.text)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4,
        children: [
          _catalogCard(c: c, icon: Icons.coronavirus_rounded, title: "Mildiu", subtitle: "(P. infestans)", color: c.danger),
          _catalogCard(c: c, icon: Icons.eco_rounded, title: "Oídium", subtitle: "(O. neolycopersici)", color: c.primary),
          _catalogCard(c: c, icon: Icons.bug_report_rounded, title: "Mosca Blanca", subtitle: "(B. tabaci)", color: c.textDim),
          _catalogCard(c: c, icon: Icons.pest_control_rounded, title: "Polilla Tomate", subtitle: "(Tuta absoluta)", color: c.textDim),
        ],
      ),
    ]);
  }

  Widget _catalogCard({required AppColors c, required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 8),
        Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.text), textAlign: TextAlign.center),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: c.textDim), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _weeklyStats(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Weekly Scans", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 4),
          Text("12 Scans total", style: GoogleFonts.inter(fontSize: 12, color: c.textDim)),
        ]),
        Row(children: [
          Column(children: [Text("10", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: c.primary)), Text("HEALTHY", style: GoogleFonts.inter(fontSize: 10, color: c.textDim))]),
          const SizedBox(width: 20),
          Column(children: [Text("2", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: c.danger)), Text("FLAGGED", style: GoogleFonts.inter(fontSize: 10, color: c.textDim))]),
        ]),
      ]),
    );
  }

  Widget _tendenciasPeru(BuildContext context, AppColors c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        RichText(text: TextSpan(children: [TextSpan(text: "Tendencias en ", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: c.text)), TextSpan(text: "Perú", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: c.primary, decoration: TextDecoration.underline, decorationColor: c.primary))])),
        Icon(Icons.more_horiz_rounded, color: c.textDim, size: 18),
      ]),
      const SizedBox(height: 4),
      Text("Noticias de plagas y enfermedades activas", style: GoogleFonts.inter(fontSize: 11, color: c.textDim)),
      const SizedBox(height: 12),
      SizedBox(
        height: 140,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          _trendCard(c: c, title: "Agapanto", url: "https://lh3.googleusercontent.com/aida-public/AB6AXuAWEcHmMAzOf5KpH4MZrIdybL_Zl97h0KwKkFCG7_-ejHF27U4aic5bIUx7gVN1UE4hLxPrq2HCCDrcbYqJfe7TaST_tM_APKIU4FL3zn9nnKhpEHULMziqfc_7B14OU0Lj4_MYvFQ-fZ0H0F0kOXbVlqjsZeeJyacvx0W0ePIqKigbL-44W_fmjEMj3Da3RTnfRxTVe7LMkdyclG2jbi1H2KiiaPxJboC-49aKRuYWO7nrKbnB-cY5IA"),
          const SizedBox(width: 12),
          _trendCard(c: c, title: "Hibisco", url: "https://lh3.googleusercontent.com/aida-public/AB6AXuD4kKNINfAa8WmaiVLVWEpP4rs-WOjvusGFl7z2Jq3ZW7MGKmm4OJnlVXVIb6tHak5G5eKTBlxwncZ2LCfolx2_Mm_Zpu7Fnt_3s_2lQ7EFZ-Frl1jLR6G5P0E9hvZvIMZPQHXwIECtEvolsMYd6LEJMXKxKr5u-LqBdiX6rRZlfppaaHQ03J6yUllqX6Sb3Ix4CHZQgB7zfQPNp3BJXuow6wxSEwmZPW1aa6HoyoAKEV7U5iOC_cMKZQ"),
          const SizedBox(width: 12),
          Container(width: 100, decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.textDim)), child: Icon(Icons.arrow_forward_rounded, color: c.textDim, size: 18)), const SizedBox(height: 6), Text("Ver todos", style: GoogleFonts.inter(fontSize: 11, color: c.textDim))])),
        ]),
      ),
    ]);
  }

  Widget _trendCard({required AppColors c, required String title, required String url}) {
    return Container(width: 130, decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(url, height: 90, width: 130, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(height: 90, color: c.cardAlt, child: Icon(Icons.image, color: c.textDim)))),
      Padding(padding: const EdgeInsets.all(8), child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: c.text))),
    ]));
  }
}
