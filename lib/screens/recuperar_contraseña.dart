import 'package:flutter/material.dart';
import 'login_screen.dart'; 

// Paleta de colores 
class AppColors {
  static const Color red = Color(0xFFF20000);
  static const Color orange = Color(0xFFFC8A27);
  static const Color yellow = Color(0xFFFFCB3A);
  static const Color green = Color(0xFF8ACB27);
  static const Color blue = Color(0xFF1782C6);
  static const Color purple = Color(0xFF6B4E91);
  static const Color black = Color(0xFF000000); 
  static const Color lightGrey = Color(0xFFF0F0F0); 
  static const Color darkGrey = Color.fromARGB(255, 0, 0, 0); 
}


class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  State<RecuperarContrasenaScreen> createState() => _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  // Manejo de Estado para los 3 pasos de recuperación
  int _currentStep = 1; // 1: Email, 2: Codigo de verificación, 3: Nueva contraseña

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 
  
  // Controladores y FocusNodes
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmNewPasswordFocusNode = FocusNode();

  // -----------------------------------------------------------
  // Lógica de Pasos
  // -----------------------------------------------------------

  void _nextStep() {
    // Si la validación del paso actual falla, detenemos el proceso.
    if (!_formKey.currentState!.validate()) return;

    // Aquí iría la llamada a la API de Node.js para enviar/verificar datos.
    
    // Simulación del avance (si la validación local es exitosa):
    setState(() {
      if (_currentStep < 3) {
        _currentStep++;
        // Pedir foco para el siguiente campo después de que el widget se construya
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_currentStep == 2) _codeFocusNode.requestFocus();
          if (_currentStep == 3) _newPasswordFocusNode.requestFocus();
        });
      } else if (_currentStep == 3) {
        _saveNewPassword();
      }
    });
  }

  void _saveNewPassword() {
    // La validación ya se hizo en _nextStep
    
    // TODO: Aquí iría la llamada a la API para guardar la nueva contraseña
    print('Contraseña cambiada para: ${_emailController.text}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Contraseña cambiada con éxito! Redireccionando a Login.')),
    );

    // Redireccionar al Login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
  
  String _getButtonText() {
    switch (_currentStep) {
      case 1:
        return 'Enviar Código de Verificación';
      case 2:
        return 'Verificar Código';
      case 3:
        return 'Guardar y Entrar';
      default:
        return '';
    }
  }

  // -----------------------------------------------------------
  // Widgets de Construcción (Helpers)
  // -----------------------------------------------------------

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildEmailStep();
      case 2:
        return _buildCodeStep();
      case 3:
        return _buildNewPasswordStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmailStep() {
    return _buildTextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      labelText: 'Correo',
      hintText: 'correo@dominio.com',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Ingresa un correo válido.';
        }
        return null;
      },
      textInputAction: TextInputAction.send,
      onFieldSubmitted: (value) => _nextStep(),
    );
  }

  Widget _buildCodeStep() {
    return Column(
      children: [
        const Text(
          'Se ha enviado un código de 6 dígitos a tu correo.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _codeController,
          focusNode: _codeFocusNode,
          labelText: 'Código',
          hintText: '######',
          icon: Icons.security_outlined,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.length != 6) {
              return 'El código debe tener 6 dígitos.';
            }
            return null;
          },
          textInputAction: TextInputAction.send,
          onFieldSubmitted: (value) => _nextStep(),
        ),
        TextButton(
          onPressed: () {
            // TODO: Lógica para reenviar código
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reenviando código...')),
            );
          },
          child: const Text('Reenviar código'),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _newPasswordController,
          focusNode: _newPasswordFocusNode,
          nextFocusNode: _confirmNewPasswordFocusNode,
          labelText: 'Nueva Contraseña',
          hintText: '********',
          icon: Icons.lock_open_outlined,
          obscureText: true,
          validator: (value) {
            if (value == null || value.length < 8) {
              return 'La contraseña debe tener al menos 8 caracteres.';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _confirmNewPasswordController,
          focusNode: _confirmNewPasswordFocusNode,
          labelText: 'Confirmar Contraseña',
          hintText: '********',
          icon: Icons.lock_open_outlined,
          obscureText: true,
          validator: (value) {
            if (value == null || value != _newPasswordController.text) {
              return 'Las contraseñas no coinciden.';
            }
            return null;
          },
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (value) => _nextStep(),
        ),
      ],
    );
  }

  // Helper para construir los TextFields (Reutilizado de Login/Registro)
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
  // Diseño Principal
  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Paso $_currentStep de 3', 
          style: const TextStyle(color: AppColors.darkGrey, fontSize: 16)
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 30),
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
              children: <Widget>[
                const SizedBox(height: 10),
                Image.asset(
                  'assets/images/MiEduRitmo_Negro.png', 
                  height: 80,
                ),
                const SizedBox(height: 30),
                
                const Text(
                  'Recuperación de Contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.black),
                ),
                const SizedBox(height: 30),
                
                // Formulario
                Form(
                  key: _formKey,
                  child: _buildStepContent(),
                ),
                
                const SizedBox(height: 50),
                
                // Botón de Acción
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black, 
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0, 
                  ),
                  child: Text(
                    _getButtonText(),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
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