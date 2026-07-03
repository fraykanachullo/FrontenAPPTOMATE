import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomate_detection_app/core/constants/app_constants.dart';
import 'package:tomate_detection_app/core/services/database_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final DatabaseService _dbService = DatabaseService();
  
  bool _isLoading = true;
  int _totalDiagnostics = 0;
  int _diseaseCount = 0;
  int _healthyCount = 0;
  Map<String, int> _diseaseStats = {};
  String _selectedFilter = 'Todos';
  String _selectedPeriod = 'Semana';
  final List<String> _periods = ['Semana', 'Mes', 'Temporada'];

  final Map<String, String> _classDisplayNames = {
    'mildiu': 'Mildiu Velloso',
    'mosca_blanca': 'Mosca Blanca',
    'oidio': 'Cenicilla/Oidio',
    'polilla': 'Polilla del Tomate',
    'sana': 'Hoja Sana',
  };

  final Map<String, Color> _classColors = {
    'mildiu': const Color(0xFFFF6B35),
    'mosca_blanca': const Color(0xFFFF6B9D),
    'oidio': const Color(0xFFF9A825),
    'polilla': const Color(0xFFE53935),
    'sana': const Color(0xFF43A047),
  };

  final List<String> _filterOptions = [
    'Todos',
    'mildiu',
    'mosca_blanca',
    'oidio',
    'polilla',
    'sana',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      _totalDiagnostics = await _dbService.getTotalDiagnostics();
      _diseaseCount = await _dbService.getDiseaseCount();
      _healthyCount = await _dbService.getHealthyCount();
      _diseaseStats = await _dbService.getDiseaseStats();
    } catch (e) {
      debugPrint('❌ Error cargando datos: $e');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryEmerald),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primaryEmerald,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildPeriodSelector(),
                      const SizedBox(height: 16),
                      _buildMetricsGrid(),
                      const SizedBox(height: 16),
                      _buildPrimaryThreat(),
                      const SizedBox(height: 16),
                      _buildTrendChart(),
                      const SizedBox(height: 16),
                      _buildDistributionAndRecommendation(),
                      const SizedBox(height: 16),
                      _buildFieldImage(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.agriculture_rounded,
                color: AppColors.primaryEmerald,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Crop Analytics',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryEmerald,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.settings_rounded,
              color: Colors.grey.shade600,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SELECTOR DE PERÍODO
  // =====================================================
  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: _periods.map((period) {
            final isSelected = _selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedPeriod = period);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryEmerald : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryEmerald.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    period,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // =====================================================
  // MÉTRICAS (Bento Grid)
  // =====================================================
  Widget _buildMetricsGrid() {
    final avgHealth = _totalDiagnostics > 0
        ? ((_healthyCount / _totalDiagnostics) * 100).toInt()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              icon: Icons.qr_code_scanner_rounded,
              value: '$_totalDiagnostics',
              label: 'Total Scans',
              trend: '+12%',
              color: AppColors.primaryEmerald,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.health_and_safety_rounded,
              value: '$avgHealth%',
              label: 'Avg. Health',
              trend: '',
              color: avgHealth > 70 ? Colors.green.shade600 : Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    String trend = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (trend.isNotEmpty)
                Text(
                  trend,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // AMENAZA PRINCIPAL
  // =====================================================
  Widget _buildPrimaryThreat() {
    String primaryDisease = 'Ninguna';
    int primaryCount = 0;
    int total = _totalDiagnostics > 0 ? _totalDiagnostics : 1;
    
    if (_diseaseStats.isNotEmpty) {
      final sorted = _diseaseStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (var entry in sorted) {
        if (entry.key != 'sana') {
          primaryDisease = _classDisplayNames[entry.key] ?? entry.key;
          primaryCount = entry.value;
          break;
        }
      }
    }
    
    final percentage = total > 0 ? (primaryCount / total * 100).toInt() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryEmerald.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryEmerald.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppColors.primaryEmerald,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Threat',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryEmerald,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    primaryDisease,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  Text(
                    'Detected in $percentage% of scans',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // GRÁFICO DE TENDENCIA
  // =====================================================
  Widget _buildTrendChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Crop Health Trend',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChartBar('Mon', 60),
                  _buildChartBar('Wed', 75),
                  _buildChartBar('Fri', 90),
                  _buildChartBar('Sun', 85),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(String label, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: height.clamp(10.0, 120.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryEmerald.withValues(alpha: 0.6),
                AppColors.primaryEmerald,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // DISTRIBUCIÓN Y RECOMENDACIONES (MEJORADO)
  // =====================================================
  Widget _buildDistributionAndRecommendation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildDistributionCard(),
          const SizedBox(height: 12),
          _buildRecommendationCard(),
        ],
      ),
    );
  }

  Widget _buildDistributionCard() {
    final total = _totalDiagnostics > 0 ? _totalDiagnostics : 1;
    final healthyPct = (_healthyCount / total * 100).toInt();
    final diseasePct = (_diseaseCount / total * 100).toInt();
    final otherPct = 100 - healthyPct - diseasePct;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Issue Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          // Barra de distribución
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (healthyPct > 0)
                  Expanded(
                    flex: healthyPct,
                    child: Container(
                      height: 12,
                      color: Colors.green.shade500,
                    ),
                  ),
                if (diseasePct > 0)
                  Expanded(
                    flex: diseasePct,
                    child: Container(
                      height: 12,
                      color: Colors.red.shade500,
                    ),
                  ),
                if (otherPct > 0)
                  Expanded(
                    flex: otherPct,
                    child: Container(
                      height: 12,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Leyenda
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Healthy ($healthyPct%)', Colors.green.shade500),
              _buildLegendItem('Enfermedades ($diseasePct%)', Colors.red.shade500),
              _buildLegendItem('Other ($otherPct%)', Colors.grey.shade500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // RECOMENDACIÓN MEJORADA
  // =====================================================
  Widget _buildRecommendationCard() {
    String recommendation;
    IconData icon;
    Color color;

    if (_totalDiagnostics < 3) {
      recommendation = 'Realiza más diagnósticos para obtener recomendaciones precisas. Te sugerimos monitorear al menos 5 sectores diferentes.';
      icon = Icons.lightbulb_outline_rounded;
      color = Colors.amber.shade700;
    } else if (_diseaseCount > _healthyCount) {
      recommendation = '⚠️ Se detecta una alta incidencia de enfermedades. Se recomienda aplicar fungicidas preventivos y aumentar la frecuencia de monitoreo en las áreas más afectadas.';
      icon = Icons.warning_rounded;
      color = Colors.red.shade600;
    } else if (_healthyCount > _diseaseCount * 2) {
      recommendation = '✅ ¡Excelente! La mayoría de tus plantas están sanas. Continúa con las buenas prácticas agrícolas y mantén el monitoreo regular.';
      icon = Icons.emoji_events_rounded;
      color = Colors.green.shade600;
    } else {
      recommendation = '📊 El cultivo muestra un equilibrio entre plantas sanas y con enfermedades. Sigue monitoreando y aplica medidas preventivas según sea necesario.';
      icon = Icons.agriculture_rounded;
      color = AppColors.primaryEmerald;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Field Recommendations',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.map_rounded, size: 18),
            label: const Text('View Sector Map'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryEmerald,
              side: BorderSide(color: AppColors.primaryEmerald),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // IMAGEN DE CAMPO
  // =====================================================
  Widget _buildFieldImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: NetworkImage(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBrUNcQ2QHpq4csqKkCmmyQ3NLBSgYnDHx9x3UBfkfe2RWc8XVOeWknMmd83PfixYxG5jJMRR-ds42bC_AOQHvLbN3xoBG1jhaYhY9hvuTknJc8IWjKNZ4C3hOfaXdRy7WFVJFrfHiNIlP7aEoYfxutawYp9N7Qs7x70AkKofNnxNIJMNuBG0Mb6dO-qGRsaocV5uRmgC8zxvuknSG9jUrz9ODwtWmW_wyYziUyyI16eWIVH9yLpFnv-x5jo3z_Aes9_H0yMOlkDHP6'
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Active Monitoring: Sector B - North Block',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}