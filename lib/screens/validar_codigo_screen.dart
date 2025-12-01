import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'cambiar_contraseña_screen.dart';
import 'solicitar_cambio_password_screen.dart'; // para reutilizar apiBaseUrl

class ValidarCodigoScreen extends StatefulWidget {
  final String correo;

  const ValidarCodigoScreen({super.key, required this.correo});

  @override
  State<ValidarCodigoScreen> createState() => _ValidarCodigoScreenState();
}

class _ValidarCodigoScreenState extends State<ValidarCodigoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

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
      _codeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _verificarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    final codigo = _codeController.text.trim();

    setState(() => _isLoading = true);
    try {
      final resp = await _dio.post(
        '/usuarios/validarCodigo',
        data: {
          'correo': widget.correo,
          'codigo': codigo,
        },
      );

      debugPrint('✔ validarCodigo -> ${resp.data}');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.data['msg'] ?? 'Código válido'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CambiarContrasenaScreen(correo: widget.correo),
        ),
      );
    } on DioException catch (e) {
      debugPrint('✖ validarCodigo ERROR -> ${e.response?.data}');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data['msg'] ?? 'Error al verificar el código',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('✖ validarCodigo EXCEPTION -> $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado al verificar código'),
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
          'Paso 2 de 3',
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
                  'Verificar Código',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hemos enviado un código de 6 dígitos a:\n${widget.correo}',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _codeController,
                    focusNode: _codeFocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => _verificarCodigo(),
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return 'El código debe tener 6 dígitos.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: '######',
                      labelText: 'Código',
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                      prefixIcon: const Icon(Icons.security_outlined,
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
                    onPressed: _isLoading ? null : _verificarCodigo,
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
                            'Verificar Código',
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
