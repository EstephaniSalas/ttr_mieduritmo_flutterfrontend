import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'validar_codigo_screen.dart';

// Ajusta al mismo host/puerto que tu API (emulador -> 10.0.2.2)
const String apiBaseUrl = 'http://10.0.2.2:3333/api';

class SolicitarCambioPasswordScreen extends StatefulWidget {
  const SolicitarCambioPasswordScreen({super.key});

  @override
  State<SolicitarCambioPasswordScreen> createState() =>
      _SolicitarCambioPasswordScreenState();
}

class _SolicitarCambioPasswordScreenState
    extends State<SolicitarCambioPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

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
      _emailFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() => _isLoading = true);
    try {
      final resp = await _dio.post(
        '/usuarios/solicitud-cambio-password',
        data: {'correo': email},
      );

      debugPrint('✔ solicitud-cambio-password -> ${resp.data}');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.data['msg'] ?? 'Código enviado a tu correo'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ValidarCodigoScreen(correo: email),
        ),
      );
    } on DioException catch (e) {
      debugPrint('✖ solicitud-cambio-password ERROR -> ${e.response?.data}');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data['msg'] ??
                'Error al solicitar el código de verificación',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('✖ solicitud-cambio-password EXCEPTION -> $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado al solicitar código'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Paso 1 de 3',
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
                  'Recuperación de Contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ingresa el correo con el que te registraste. Te enviaremos un código de verificación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => _enviarCodigo(),
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                        return 'Ingresa un correo válido.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'correo@dominio.com',
                      labelText: 'Correo',
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _enviarCodigo,
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
                            'Enviar Código de Verificación',
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
