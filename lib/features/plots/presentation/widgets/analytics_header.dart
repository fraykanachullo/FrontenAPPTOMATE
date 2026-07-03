import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomate_detection_app/core/constants/app_constants.dart';

class AnalyticsHeader extends StatelessWidget {
  final int totalDiagnostics;
  final int alertsCount;
  final String selectedFilter;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onDateRangeTap;
  final String? dateRangeLabel;

  const AnalyticsHeader({
    super.key,
    required this.totalDiagnostics,
    required this.alertsCount,
    required this.selectedFilter,
    required this.filterOptions,
    required this.onFilterChanged,
    required this.onDateRangeTap,
    this.dateRangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Análisis',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Monitoreo Agrícola',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              if (alertsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$alertsCount alertas',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickFilters(),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    final Map<String, String> classNames = {
      'Todos': 'Todos',
      'mildiu': 'Mildiu',
      'mosca_blanca': 'Mosca Blanca',
      'oidio': 'Oidio',
      'polilla': 'Polilla',
      'sana': 'Sana',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...filterOptions.map((filter) => _buildFilterChip(
                classNames[filter] ?? filter,
                filter,
                selectedFilter == filter,
              )),
          const SizedBox(width: 8),
          _buildDateFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onFilterChanged(isSelected ? 'Todos' : value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryEmerald : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primaryEmerald : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return GestureDetector(
      onTap: onDateRangeTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: dateRangeLabel != null ? AppColors.primaryEmerald : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: dateRangeLabel != null ? AppColors.primaryEmerald : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: dateRangeLabel != null ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              dateRangeLabel ?? 'Fechas',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: dateRangeLabel != null ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}