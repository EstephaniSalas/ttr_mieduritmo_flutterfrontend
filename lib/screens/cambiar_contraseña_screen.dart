import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'login_screen.dart';
import 'solicitar_cambio_password_screen.dart'; // para reutilizar apiBaseUrl

class CambiarContrasenaScreen extends StatefulWidget {
  final String correo;

  const CambiarContrasenaScreen({super.key, required this.correo});

  @override
  State<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  final _newPassFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _newPassFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _newPassFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  Future<void> _guardarNuevaContrasena() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _newPasswordController.text.trim();
    final password2 = _confirmNewPasswordController.text.trim();

    setState(() => _isLoading = true);
    try {
      final resp = await _dio.post(
        '/usuarios/cambio-password',
        data: {
          'correo': widget.correo,
          'password': password,
          'password2': password2,
        },
      );

      debugPrint('✔ cambio-password -> ${resp.data}');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(resp.data['msg'] ?? 'Contraseña actualizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on DioException catch (e) {
      debugPrint('✖ cambio-password ERROR -> ${e.response?.data}');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data['msg'] ??
                'Error al confirmar cambio de contraseña',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('✖ cambio-password EXCEPTION -> $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado al cambiar contraseña'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted ??
          (_) {
            if (nextFocus != null) {
              nextFocus.requestFocus();
            } else {
              focusNode.unfocus();
            }
          },
      validator: validator,
      decoration: InputDecoration(
        hintText: '********',
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        prefixIcon:
            const Icon(Icons.lock_open_outlined, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Paso 3 de 3',
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Nueva Contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cambia la contraseña para el correo:\n${widget.correo}',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildPasswordField(
                        controller: _newPasswordController,
                        focusNode: _newPassFocus,
                        nextFocus: _confirmPassFocus,
                        label: 'Nueva Contraseña',
                        obscure: !_showNewPassword,
                        onToggle: () {
                          setState(() {
                            _showNewPassword = !_showNewPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'La contraseña debe tener al menos 8 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _confirmNewPasswordController,
                        focusNode: _confirmPassFocus,
                        label: 'Confirmar Contraseña',
                        obscure: !_showConfirmPassword,
                        onToggle: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null ||
                              value != _newPasswordController.text) {
                            return 'Las contraseñas no coinciden.';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _guardarNuevaContrasena(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _guardarNuevaContrasena,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            'Guardar y Entrar',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
