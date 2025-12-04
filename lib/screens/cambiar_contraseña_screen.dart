import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/usuario_api_service.dart';
import 'login_screen.dart';
import 'solicitar_cambio_password_screen.dart';

class CambiarContrasenaScreen extends StatefulWidget {
  final String correo;

  const CambiarContrasenaScreen({
    super.key,
    required this.correo,
  });

  @override
  State<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _newPassController = TextEditingController();
  final _newPass2Controller = TextEditingController();

  final _focusNew = FocusNode();
  final _focusNew2 = FocusNode();

  bool _showNew = false;
  bool _showNew2 = false;
  bool _loading = false;

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
      _focusNew.requestFocus();
    });
  }

  @override
  void dispose() {
    _newPassController.dispose();
    _newPass2Controller.dispose();
    _focusNew.dispose();
    _focusNew2.dispose();
    super.dispose();
  }

  Future<void> _guardarNuevaContrasena() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final resp = await _dio.post(
        "/usuarios/cambio-password",
        data: {
          "correo": widget.correo,
          "password": _newPassController.text.trim(),
          "password2": _newPass2Controller.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.data["msg"] ?? "Contraseña actualizada"),
          backgroundColor: Colors.green,
        ),
      );

      // Redirigir al login, enviando una nueva instancia del servicio API
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(api: UsuarioApiService()),
        ),
        (route) => false,
      );
    } on DioException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data["msg"] ??
                "Error al actualizar contraseña",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _campoPassword({
    required TextEditingController controller,
    required FocusNode focus,
    FocusNode? nextFocus,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focus,
      obscureText: obscure,
      textInputAction:
          nextFocus == null ? TextInputAction.done : TextInputAction.next,
      validator: validator,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          nextFocus.requestFocus();
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: "********",
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
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
        title: const Text(
          "Paso 3 de 3",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                "Nueva Contraseña",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Correo:\n${widget.correo}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 30),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _campoPassword(
                      controller: _newPassController,
                      focus: _focusNew,
                      nextFocus: _focusNew2,
                      label: "Nueva contraseña",
                      obscure: !_showNew,
                      onToggle: () {
                        setState(() => _showNew = !_showNew);
                      },
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return "Mínimo 8 caracteres";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _campoPassword(
                      controller: _newPass2Controller,
                      focus: _focusNew2,
                      label: "Confirmar contraseña",
                      obscure: !_showNew2,
                      onToggle: () {
                        setState(() => _showNew2 = !_showNew2);
                      },
                      validator: (v) {
                        if (v != _newPassController.text) {
                          return "Las contraseñas no coinciden";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _guardarNuevaContrasena,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                      : const Text(
                          "Guardar y Entrar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
