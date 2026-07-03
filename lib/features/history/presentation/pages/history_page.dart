import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomate_detection_app/core/constants/app_constants.dart';
import 'package:tomate_detection_app/core/services/database_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseService _dbService = DatabaseService();
  
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  List<Map<String, dynamic>> _diagnostics = [];
  bool _isLoading = true;
  
  int _totalDiagnostics = 0;
  int _diseaseCount = 0;
  int _healthyCount = 0;
  Map<String, int> _diseaseStats = {};

  final List<String> _filters = ['Todos', 'mildiu', 'mosca_blanca', 'oidio', 'polilla', 'sana'];

  final Map<String, String> _classDisplayNames = {
    'mildiu': 'Mildiu Velloso',
    'mosca_blanca': 'Mosca Blanca',
    'oidio': 'Cenicilla/Oidio',
    'polilla': 'Polilla del Tomate',
    'sana': 'Hoja Sana',
  };

  final Map<String, Color> _classColors = {
    'mildiu': Colors.orange,
    'mosca_blanca': Colors.pink,
    'oidio': Colors.yellow,
    'polilla': Colors.red,
    'sana': Colors.green,
  };

  final Map<String, IconData> _classIcons = {
    'mildiu': Icons.warning_rounded,
    'mosca_blanca': Icons.bug_report_rounded,
    'oidio': Icons.cloud_rounded,
    'polilla': Icons.pest_control_rounded,
    'sana': Icons.check_circle_rounded,
  };

  final Map<String, String> _severityLabels = {
    'mildiu': 'Enfermedad detectada',
    'mosca_blanca': 'Plaga detectada',
    'oidio': 'Enfermedad detectada',
    'polilla': 'Plaga detectada',
    'sana': 'Sin problemas',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final search = _searchQuery.isEmpty ? null : _searchQuery;
      final filter = _selectedFilter == 'Todos' ? null : _selectedFilter;
      
      _diagnostics = await _dbService.getDiagnostics(
        search: search,
        disease: filter,
      );
      
      _totalDiagnostics = await _dbService.getTotalDiagnostics();
      _diseaseCount = await _dbService.getDiseaseCount();
      _healthyCount = await _dbService.getHealthyCount();
      _diseaseStats = await _dbService.getDiseaseStats();
      
    } catch (e) {
      debugPrint('❌ Error cargando historial: $e');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildFilterChips(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _diagnostics.isEmpty
                      ? _buildEmptyState()
                      : _buildDiagnosticList(),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F4C3A), Color(0xFF1A6B4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historial de',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Diagnósticos',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Revisa tus diagnósticos anteriores',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white60,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ESTADÍSTICAS
  // =====================================================
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.camera_alt_rounded,
              color: Colors.grey.shade600,
              value: '$_totalDiagnostics',
              label: 'Total',
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade200,
            ),
            _buildStatItem(
              icon: Icons.warning_amber_rounded,
              color: Colors.orange.shade600,
              value: '$_diseaseCount',
              label: 'Enfermedades',
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade200,
            ),
            _buildStatItem(
              icon: Icons.health_and_safety_rounded,
              color: Colors.green.shade600,
              value: '$_healthyCount',
              label: 'Sanas',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // BÚSQUEDA
  // =====================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _loadData();
                },
                decoration: InputDecoration(
                  hintText: 'Buscar enfermedad o fecha...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // FILTROS
  // =====================================================
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter;
            final displayName = filter == 'Todos' 
                ? 'Todos' 
                : (_classDisplayNames[filter] ?? filter);
            
            return GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryEmerald : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryEmerald : Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryEmerald.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =====================================================
  // ESTADO VACÍO
  // =====================================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No se encontraron diagnósticos',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Realiza tu primer diagnóstico',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navegar al escáner
            },
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Ir al Escáner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // LISTA DE DIAGNÓSTICOS
  // =====================================================
  Widget _buildDiagnosticList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _diagnostics.length,
      itemBuilder: (context, index) {
        final diag = _diagnostics[index];
        return _buildDiagnosticCard(diag);
      },
    );
  }

  // =====================================================
  // TARJETA DE DIAGNÓSTICO
  // =====================================================
  Widget _buildDiagnosticCard(Map<String, dynamic> diag) {
    final disease = diag['disease'] ?? 'Desconocido';
    final isHealthy = disease == 'sana';
    final displayName = _classDisplayNames[disease] ?? disease;
    final color = _classColors[disease] ?? Colors.grey;
    final icon = _classIcons[disease] ?? Icons.help_rounded;
    final severityLabel = _severityLabels[disease] ?? 'Detectado';
    final confidence = (diag['confidence'] as num?)?.toDouble() ?? 0.0;
    final date = diag['created_at'] != null
        ? DateTime.parse(diag['created_at'])
        : DateTime.now();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isHealthy ? Colors.green.shade100 : color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navegar a detalle
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de clase
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: color.withOpacity(0.1),
                    child: Icon(
                      icon,
                      color: color,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(confidence * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Estado
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              severityLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Flecha
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}