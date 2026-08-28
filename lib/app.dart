import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tomate_detection_app/core/theme/app_theme.dart';
import 'package:tomate_detection_app/core/widgets/curved_nav_bar.dart';
import 'package:tomate_detection_app/features/home/presentation/pages/home_page.dart';
import 'package:tomate_detection_app/features/diagnosis/presentation/pages/scanner_page.dart';
import 'package:tomate_detection_app/features/history/presentation/pages/history_page.dart';
import 'package:tomate_detection_app/features/plots/presentation/pages/analytics_page.dart';
import 'package:tomate_detection_app/features/authentication/presentation/pages/profile_page.dart';
import 'package:tomate_detection_app/features/authentication/presentation/pages/login_page.dart';
import 'package:tomate_detection_app/features/authentication/presentation/pages/register_page.dart';
import 'package:tomate_detection_app/features/authentication/presentation/pages/splash_page.dart';
import 'package:tomate_detection_app/features/authentication/data/models/user_model.dart';
import 'package:tomate_detection_app/features/authentication/bloc/auth_bloc.dart';
import 'package:tomate_detection_app/features/diagnosis/bloc/diagnostic_bloc.dart';
import 'package:tomate_detection_app/core/theme/theme_controller.dart';
import 'package:tomate_detection_app/injection_container.dart' as di;

class TomatoDetectionApp extends StatelessWidget {
  const TomatoDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
          BlocProvider<DiagnosticBloc>(create: (_) => di.sl<DiagnosticBloc>()),
        ],
        child: MaterialApp(
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
        ),
      ),
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
  int _selectedIndex = 0; // 0:Home, 1:Analítica, 2:Historial, 3:Perfil

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onNavigate: _handleHomeNavigate),
      const AnalyticsPage(),
      const HistoryPage(),
      ProfilePage(user: widget.user),
    ];
  }

  void _handleHomeNavigate(int idx) {
    // Home bento: 1->Cámara, 2->Historial
    if (idx == 1) _openCamera();
    else setState(() => _selectedIndex = idx.clamp(0, 3));
  }

  void _openCamera() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerPage()));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      extendBody: true, // el body se extiende detrás de la nav (edge-to-edge)
      body: _pages[_selectedIndex],
      bottomNavigationBar: CurvedNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        onCameraTap: _openCamera,
      ),
    );
  }
}