// lib/screens/login_screen.dart - COMPLETO
import 'package:flutter/material.dart';
import '../services/usuario_api_service.dart';
import '../services/notification_service.dart'; // 🔔 NUEVO
import '../services/notification_sync_service.dart'; // 🔔 NUEVO
import '../models/usuario.dart';
import 'home_shell_screen.dart';
import 'solicitar_cambio_password_screen.dart';
import 'registro_screen.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final UsuarioApiService api;

  const LoginScreen({super.key, required this.api});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Login normal
      final Usuario usuario = await widget.api.loginUsuario(
        correo: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. 🔔 NUEVO: Sincronizar notificaciones en segundo plano
      final notificationService = NotificationService();
      final syncService = NotificationSyncService(
        widget.api.dio,
        notificationService,
      );

      // Sincronizar sin esperar (fire and forget)
      syncService.sincronizarTodasNotificaciones(usuario.uid).then((_) {
        print('✅ Notificaciones sincronizadas correctamente');
      }).catchError((error) {
        print('⚠️ Error sincronizando notificaciones: $error');
        // No mostramos error al usuario, las notificaciones son secundarias
      });

      // 3. Navegar al home
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeShellScreen(
            usuario: usuario,
            api: widget.api,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //--------- WIDGET INDIVIDUAL DEL INPUT -----------
  Widget _buildInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    bool obscure = false,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      focusNode: focusNode,
      textInputAction: action,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          nextFocus.requestFocus();
        } else {
          focusNode.unfocus();
        }
      },
      validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  //--------- CARTAS COLOREADAS DEL MOCKUP ----------
  Widget _buildColorCard(Color color, IconData icon) {
    return Container(
      width: 70,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 3),
            blurRadius: 6,
            color: Colors.black26,
          )
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // LOGO
                Image.asset(
                  'assets/images/MiEduRitmo_Negro.png',
                  height: 90,
                ),

                const SizedBox(height: 8),

                const Text(
                  '"Organiza tu estudio, sigue tu ritmo"',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),

                Center(
                  child: const Text(
                    '\n\nAplicación Móvil para la Gestión Académica Integral y Apoyo de Aprendizaje para Estudiantes',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color.fromARGB(213, 90, 90, 90),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // CARTAS DE COLORES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorCard(AppColors.purple, Icons.calendar_month),
                    _buildColorCard(AppColors.blue, Icons.note_alt),
                    _buildColorCard(const Color.fromARGB(255, 15, 171, 255),
                        Icons.list_alt),
                    _buildColorCard(AppColors.green, Icons.access_time),
                    _buildColorCard(AppColors.yellow, Icons.edit),
                  ],
                ),

                const SizedBox(height: 40),

                const Text(
                  "Inicia sesión",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),

                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInput(
                        label: "Correo",
                        hint: "correo@dominio.com",
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        focusNode: _emailFocus,
                        nextFocus: _passwordFocus,
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        label: "Contraseña",
                        hint: "********",
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscure: true,
                        action: TextInputAction.done,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SolicitarCambioPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "¿Olvidaste tu contraseña?",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // BOTÓN LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _isLoading ? "Ingresando..." : "Ingresar",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("¿No tienes cuenta?"),
                    TextButton(
                      child: const Text(
                        "Regístrate aquí.",
                        style: TextStyle(color: Colors.blue),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistrationScreen(),
                          ),
                        );
                      },
                    )
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}