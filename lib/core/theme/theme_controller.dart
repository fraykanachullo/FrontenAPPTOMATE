import 'package:flutter/material.dart';

// Controla el modo de alto contraste (tema claro) global de la app.
class ThemeController extends ChangeNotifier {
  bool _highContrast = false;
  bool get isHighContrast => _highContrast;

  void toggle() {
    _highContrast = !_highContrast;
    notifyListeners();
  }
}

// Paleta global según el modo. Las páginas leen estos colores dinámicos
// para que el modo claro/alto contraste recoloera TODA la app.
class AppColors {
  final bool highContrast;

  AppColors(this.highContrast);

  // Fondo base
  Color get bg => highContrast ? const Color(0xFFF5F7FA) : const Color(0xFF131313);
  Color get bgPure => highContrast ? Colors.white : const Color(0xFF000000);

  // Tarjetas / superficies
  Color get card => highContrast ? Colors.white : const Color(0xFF202020);
  Color get cardAlt => highContrast ? const Color(0xFFEDF1F4) : const Color(0xFF0E0E0E);

  // Bordes
  Color get border => highContrast ? const Color(0xFFD0D7DE) : const Color(0xFF353535);

  // Texto
  Color get text => highContrast ? const Color(0xFF0F1B14) : const Color(0xFFE4E2E1);
  Color get textDim => highContrast ? const Color(0xFF5A6A60) : const Color(0xFFBBCABF);

  // Acento primario (verde)
  Color get primary => highContrast ? const Color(0xFF00875A) : const Color(0xFF4EDEA3);
  Color get onPrimary => highContrast ? Colors.white : const Color(0xFF002113);

  // Alerta
  Color get danger => highContrast ? const Color(0xFFC62828) : const Color(0xFFEF4444);
  Color get dangerSoft => highContrast ? const Color(0xFFFFEBEE) : const Color(0xFF3E1A22);

  // Warning / luz
  Color get warn => highContrast ? const Color(0xFFB26A00) : const Color(0xFFFFB95F);

  static AppColors of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<_ThemeScope>();
    return p?.colors ?? AppColors(false);
  }
}

class _ThemeScope extends InheritedWidget {
  final AppColors colors;
  final ThemeController controller;
  const _ThemeScope({required this.colors, required this.controller, required super.child});

  @override
  bool updateShouldNotify(_ThemeScope old) => old.colors.highContrast != colors.highContrast;
}

class ThemeProvider extends StatefulWidget {
  final Widget child;
  const ThemeProvider({super.key, required this.child});

  @override
  State<ThemeProvider> createState() => _ThemeProviderState();
}

class _ThemeProviderState extends State<ThemeProvider> {
  late final ThemeController _controller = ThemeController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeScope(
      colors: AppColors(_controller.isHighContrast),
      controller: _controller,
      child: widget.child,
    );
  }
}

// Botón de alternar modo (colócalo junto al logo)
class HighContrastToggle extends StatelessWidget {
  const HighContrastToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final p = context.dependOnInheritedWidgetOfExactType<_ThemeScope>();
    final active = colors.highContrast;
    return GestureDetector(
      onTap: () => p?.controller.toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? colors.primary : colors.card,
          shape: BoxShape.circle,
          border: Border.all(color: active ? colors.primary : colors.border),
        ),
        child: Icon(
          active ? Icons.brightness_3_rounded : Icons.light_mode_rounded,
          color: active ? colors.onPrimary : colors.primary,
          size: 18,
        ),
      ),
    );
  }
}
