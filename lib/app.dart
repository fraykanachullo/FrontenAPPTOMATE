import 'package:flutter/material.dart';
import 'package:tomate_detection_app/core/constants/app_constants.dart';
import 'package:tomate_detection_app/core/theme/app_theme.dart';
import 'package:tomate_detection_app/features/diagnosis/presentation/pages/scanner_page.dart';
import 'package:tomate_detection_app/features/history/presentation/pages/history_page.dart';
import 'package:tomate_detection_app/features/plots/presentation/pages/analytics_page.dart';
import 'package:tomate_detection_app/features/authentication/presentation/pages/profile_page.dart';
import 'package:tomate_detection_app/features/authentication/presentation/pages/login_page.dart';
import 'package:tomate_detection_app/features/authentication/presentation/pages/register_page.dart';
import 'package:tomate_detection_app/features/authentication/presentation/pages/splash_page.dart';
import 'package:tomate_detection_app/features/authentication/data/models/user_model.dart';

class TomatoDetectionApp extends StatelessWidget {
  const TomatoDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomate Detection UPEU',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final user = settings.arguments as UserModel?;
          return MaterialPageRoute(
            builder: (context) => MainNavigationScreen(user: user),
          );
        }
        return null;
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final UserModel? user;
  const MainNavigationScreen({super.key, this.user});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ScannerPage(),
      const HistoryPage(),
      const AnalyticsPage(),
      ProfilePage(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryEmerald,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Escáner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Análisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}