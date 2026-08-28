import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomate_detection_app/core/constants/app_constants.dart';

class AppTheme {
  static ThemeData highContrastTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000),
    primaryColor: const Color(0xFFFFD600),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFD600),
      onPrimary: Colors.black,
      surface: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      secondary: Color(0xFFAAAAAA),
    ),
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFFFFFFFF)),
      bodyMedium: const TextStyle(fontSize: 16, color: Color(0xFFFFFFFF)),
      labelLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFD600), foregroundColor: Colors.black, textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), minimumSize: Size(48, 48)),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryEmerald,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryEmerald,
      secondary: AppColors.primaryEmeraldLight,
      surface: AppColors.backgroundWhite,
      onSurface: AppColors.textDark,
    ),
    textTheme: GoogleFonts.robotoTextTheme().copyWith(
      displayLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      displayMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        color: AppColors.textMedium,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: AppColors.textMedium,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryEmerald,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryEmerald,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryEmerald,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.1),
      selectedColor: AppColors.primaryEmerald,
      labelStyle: const TextStyle(color: AppColors.textDark),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}