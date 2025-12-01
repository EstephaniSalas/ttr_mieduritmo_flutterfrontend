import 'package:flutter/material.dart';
import 'login_screen.dart' as login;

// IMPORTS para el servicio de API y modelo de Usuario
import '../services/usuario_api_service.dart';
import '../models/usuario.dart';

import '../theme/app_colors.dart';

// -----------------------------------------------------------
// WIDGET PRINCIPAL
// -----------------------------------------------------------
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Servicio de API
  final UsuarioApiService _usuarioApi = UsuarioApiService();

  bool _isLoading = false;

  // Controladores y FocusNodes
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_nameFocusNode.canRequestFocus) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  // FUNCIÓN CLAVE: Manejo de Registro usando UsuarioApiService
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrige los errores en el formulario.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enviando registro a la API...')),
    );

    setState(() {
      _isLoading = true;
    });

    try {
      final Usuario usuario = await _usuarioApi.registrarUsuario(
        nombre: _nameController.text.trim(),
        correo: _emailController.text.trim(),
        password: _passwordController.text,
        password2: _confirmPasswordController.text,
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Registro Exitoso! Bienvenido(a), ${usuario.nombre}!',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const login.LoginScreen(),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------
  // HELPERS DE DISEÑO
  // -----------------------------------------------------------

  Widget _buildColorBar(Color color, int heightRatio) {
    const double baseHeight = 200.0;

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: SizedBox(
          height: baseHeight * (heightRatio / 30.0),
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ).copyWith(color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted ??
          (value) {
            if (nextFocusNode != null) {
              nextFocusNode.requestFocus();
            } else {
              focusNode.unfocus();
            }
          },
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        filled: true,
        fillColor: AppColors.lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.grey),
      ),
    );
  }

  // -----------------------------------------------------------
  // WIDGET BUILD
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 150.0),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 0),
                      Image.asset(
                        'assets/images/MiEduRitmo_Negro.png',
                        height: 80,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '“Organiza tu estudio, sigue tu ritmo”',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const Text(
                                'Registro',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 30),

                              _buildTextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                nextFocusNode: _emailFocusNode,
                                labelText: 'Nombre',
                                hintText: 'Nombre Apellidos',
                                icon: Icons.person_outline,
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Por favor, ingresa tu nombre completo.'
                                        : null,
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                nextFocusNode: _passwordFocusNode,
                                labelText: 'Correo',
                                hintText: 'correo@dominio.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) =>
                                    (value == null ||
                                            !RegExp(
                                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(value))
                                        ? 'Ingresa un correo válido.'
                                        : null,
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                nextFocusNode: _confirmPasswordFocusNode,
                                labelText: 'Contraseña',
                                hintText: '********',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                validator: (value) =>
                                    (value == null || value.length < 8)
                                        ? 'La contraseña debe tener al menos 8 caracteres.'
                                        : null,
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocusNode,
                                labelText: 'Confirmar contraseña',
                                hintText: '********',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (value) =>
                                    _handleRegistration(),
                                validator: (value) =>
                                    (value == null ||
                                            value !=
                                                _passwordController.text)
                                        ? 'Las contraseñas no coinciden.'
                                        : null,
                              ),
                              const SizedBox(height: 30),

                              ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleRegistration,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.black,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _isLoading
                                      ? 'Registrando...'
                                      : 'Registrar',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
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
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildColorBar(AppColors.red, 15),
              _buildColorBar(AppColors.orange, 18),
              _buildColorBar(AppColors.yellow, 21),
              _buildColorBar(AppColors.green, 24),
              _buildColorBar(AppColors.blue, 27),
              _buildColorBar(AppColors.purple, 30),
            ],
          ),
        ],
      ),
    );
  }
}
