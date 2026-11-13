import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomate_detection_app/core/constants/api_constants.dart';
import 'package:tomate_detection_app/features/authentication/bloc/auth_bloc.dart';
import 'package:tomate_detection_app/features/authentication/bloc/auth_event.dart';
import 'package:tomate_detection_app/features/authentication/bloc/auth_state.dart';
import 'package:tomate_detection_app/features/authentication/data/models/user_model.dart';

// Stitch: dark #0f150e, primary #78dc77, input #0F4C3A/20 border #2D2D2D
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  void _doLogin() {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos"), backgroundColor: Color(0xFF93000A)));
      return;
    }
    context.read<AuthBloc>().add(LoginRequested(_email.text.trim(), _pass.text));
  }

  // Cambiar la URL del backend sin recompilar (p.ej. al cambiar de red Wi-Fi)
  Future<void> _editServer() async {
    final ctrl = TextEditingController(text: ApiConstants.baseUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Servidor"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: "http://192.168.1.40:8000", helperText: "USB: http://localhost:8000 (adb reverse). Wi-Fi: IP de la PC y puerto 8000"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ApiConstants.defaultBaseUrl), child: const Text("Por defecto")),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text("Guardar")),
        ],
      ),
    );
    if (url == null || url.trim().isEmpty) return;
    await ApiConstants.save(url);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bienvenido ${state.user.name}"), backgroundColor: const Color(0xFF4CAF50)));
          // Convertir UserEntity -> UserModel para compatibilidad con /home
          final u = UserModel(id: state.user.id, name: state.user.name, email: state.user.email, password: "", role: state.user.role, createdAt: DateTime.tryParse(state.user.createdAt ?? "") ?? DateTime.now());
          Navigator.pushReplacementNamed(context, '/home', arguments: u);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: const Color(0xFF93000A)));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F150E),
        body: SafeArea(
          child: Column(children: [
            // Header Stitch
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFF0F150E),
              child: Row(children: [
                const Icon(Icons.spa_rounded, color: Color(0xFF78DC77), size: 20),
                Expanded(child: Center(child: Text("AgriScan Pro", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF78DC77))))),
                const SizedBox(width: 20),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  const SizedBox(height: 24),
                  Text("Bienvenido de Vuelta", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFFDEE4D9), height: 1.2), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text("Inicia sesión para continuar", style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFBECAB9))),
                  const SizedBox(height: 24),
                  // Email
                  _inputField(controller: _email, hint: "Correo electrónico", icon: Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  // Password
                  _inputField(controller: _pass, hint: "Contraseña", icon: Icons.lock_outline_rounded, obscure: _obscure, suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF007B4F), size: 20), onPressed: () => setState(() => _obscure = !_obscure))),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: (){}, child: Text("¿Olvidaste tu contraseña?", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF78DC77))))),
                  const SizedBox(height: 8),
                  // Login button
                  BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
                    final loading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: loading ? null : _doLogin,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF78DC77), foregroundColor: const Color(0xFF00390A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0),
                        child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00390A))) : Text("Iniciar Sesión", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF00390A))),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Row(children: [
                    const Expanded(child: Divider(color: Color(0xFF3F4A3C))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text("O", style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFBECAB9)))),
                    const Expanded(child: Divider(color: Color(0xFF3F4A3C))),
                  ]),
                  const SizedBox(height: 20),
                  // Social
                  _socialBtn(icon: Icons.g_mobiledata_rounded, label: "Continuar con Google"),
                  const SizedBox(height: 12),
                  _socialBtn(icon: Icons.account_circle_outlined, label: "Continuar con SSO"),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("¿No tienes cuenta? ", style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFBECAB9))),
                    GestureDetector(onTap: () => Navigator.pushNamed(context, '/register'), child: Text("Crear una Cuenta", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF78DC77)))),
                  ]),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _editServer,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Servidor: ${ApiConstants.baseUrl}", style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFBECAB9).withValues(alpha: 0.6))),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_rounded, size: 12, color: const Color(0xFFBECAB9).withValues(alpha: 0.6)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, Widget? suffix, TextInputType keyboard = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF007B4F), width: 1.4),
      ),
      child: TextField(
        controller: controller, obscureText: obscure, keyboardType: keyboard,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
        cursorColor: const Color(0xFF007B4F),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF7A7A7A)),
          prefixIcon: Icon(icon, color: const Color(0xFF007B4F), size: 20),
          suffixIcon: suffix == null ? null : Padding(padding: const EdgeInsets.only(right: 4), child: suffix),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _socialBtn({required IconData icon, required String label}) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: OutlinedButton.icon(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente"))),
        icon: Icon(icon, color: const Color(0xFFDEE4D9)),
        label: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFDEE4D9))),
        style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFF1B211A), side: const BorderSide(color: Color(0xFF3F4A3C)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      ),
    );
  }
}
