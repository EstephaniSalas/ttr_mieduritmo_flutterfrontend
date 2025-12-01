import 'package:flutter/material.dart';

import 'registro_screen.dart' as registro;
import 'solicitar_cambio_password_screen.dart';
import 'home_shell_screen.dart';

import '../services/usuario_api_service.dart';
import '../models/usuario.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Llave global para identificar y validar el formulario
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  final UsuarioApiService _usuarioApi = UsuarioApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Foco inicial al campo correo
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_emailFocusNode.canRequestFocus) {
        _emailFocusNode.requestFocus();
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa los campos solicitados.'),
        ),
      );
      return;
    }

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Validación exitosa. Iniciando sesión con $email...'),
      ),
    );

    setState(() {
      _isLoading = true;
    });

    try {
      final Usuario usuario = await _usuarioApi.loginUsuario(
        correo: email,
        password: password,
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenido(a), ${usuario.nombre}!'),
        ),
      );

      // Navegar al shell usando el MISMO Dio que hizo login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeShellScreen(
            usuario: usuario,
            dio: _usuarioApi.dio, // <- aquí va el Dio con cookie/token
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Sección superior: logo, slogan y cartas
              Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  Container(
                    height: screenHeight * 0.48,
                    color: Colors.white,
                  ),
                  // Logo MiEduRitmo
                  Positioned(
                    top: screenHeight * 0.1,
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/MiEduRitmo_Negro.png',
                          height: 100,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '“Organiza tu estudio, sigue tu ritmo”',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cartas fondo
                  Positioned(
                    top: screenHeight * 0.28,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildCardWithOffset(
                              offset: -160,
                              rotation: -0.2,
                              color: AppColors.purple,
                              icon: Icons.calendar_today,
                            ),
                            _buildCardWithOffset(
                              offset: -90,
                              rotation: -0.1,
                              color: AppColors.blue,
                              icon: Icons.description,
                            ),
                            _buildCardWithOffset(
                              offset: 0,
                              rotation: 0.0,
                              color: AppColors.red,
                              icon: Icons.check_box,
                            ),
                            _buildCardWithOffset(
                              offset: 90,
                              rotation: 0.1,
                              color: AppColors.green,
                              icon: Icons.access_time,
                            ),
                            _buildCardWithOffset(
                              offset: 160,
                              rotation: 0.2,
                              color: AppColors.orange,
                              icon: Icons.edit_note,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Contenido: pantalla de login
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: 30),
                      const Text(
                        'Inicia sesión',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Campo de Correo Electrónico
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (value) {
                          _passwordFocusNode.requestFocus();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa tu correo electrónico.';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Ingresa un correo válido.';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'correo@dominio.com',
                          labelText: 'Correo',
                          filled: true,
                          fillColor: AppColors.lightGrey,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo de Contraseña
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa tu contraseña.';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: '********',
                          labelText: 'Contraseña',
                          filled: true,
                          fillColor: AppColors.lightGrey,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.grey,
                          ),
                          suffixIcon: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SolicitarCambioPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Botón Ingresar
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isLoading ? 'Ingresando...' : 'Ingresar',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Texto "¿No tienes cuenta? Regístrate aquí."
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta? ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const registro.RegistrationScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Regístrate aquí.',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Construir una carta individual
  Widget _buildCardWithOffset({
    required double offset,
    required double rotation,
    required Color color,
    required IconData icon,
  }) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 110,
          height: 170,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
