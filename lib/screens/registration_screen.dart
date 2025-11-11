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


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); 
  
  // Controladores y FocusNodes
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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

  void _handleRegistration() {
  // Si la validación pasa (todos los campos son correctos)...
  if (_formKey.currentState!.validate()) {
    
    final String name = _nameController.text;
    
    // 1. Muestra el mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registro exitoso. Bienvenido(a), $name!')),
    );

    // 2. REDIRECCIÓN AL LOGIN
    // Usamos pushReplacement para que el usuario no pueda volver al registro con el botón Atrás
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

  } else {
    // Muestra errores de validación si no pasa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, corrige los errores en el formulario.')),
    );
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

  // Diseño barra de colores 
Widget _buildColorBar(Color color, int heightRatio) {
    const double baseHeight = 200.0;
    
    return Expanded(
      flex: 1, // Mismo flex horizontal
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: SizedBox(
          height: baseHeight * (heightRatio / 18.0), // 18.0 es un divisor para mantener la altura visible
          child: Container(
            decoration: BoxDecoration(
              color: color, 
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0), 
                topRight: Radius.circular(20.0),
              ),
            ),
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 30),
          onPressed: () => Navigator.of(context).pop(), 
        ),
      ),
      // El Column principal maneja el espacio vertical
      body: Column(
        children: [
          // Sección de Scroll (Logo, Formulario, Botón)
          Expanded( 
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 150.0), 
                  child: Column(
                    children: <Widget>[
                      // SECCIÓN: Logo y Slogan
                      const SizedBox(height: 0),
                      Image.asset(
                        'assets/images/MiEduRitmo_Negro.png', 
                        height: 80,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '“Organiza tu estudio, sigue tu ritmo”',
                        style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
                      ),
                      const SizedBox(height: 30),
                      
                      // Contenido: formulario de registro
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
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 30),

                              // 1. Campo de Nombre
                              _buildTextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                nextFocusNode: _emailFocusNode,
                                labelText: 'Nombre',
                                hintText: 'Nombre Apellidos',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, ingresa tu nombre completo.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // 2. Campo de Correo Electrónico
                              _buildTextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                nextFocusNode: _passwordFocusNode,
                                labelText: 'Correo',
                                hintText: 'correo@dominio.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, ingresa tu correo electrónico.';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Ingresa un correo válido.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // 3. Campo de Contraseña
                              _buildTextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                nextFocusNode: _confirmPasswordFocusNode,
                                labelText: 'Contraseña',
                                hintText: '********',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty || value.length < 8) {
                                    return 'La contraseña debe tener al menos 8 caracteres.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              // 4. Campo de Confirmar Contraseña
                              _buildTextField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocusNode,
                                labelText: 'Confirmar contraseña',
                                hintText: '********',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (value) => _handleRegistration(), // Intenta registrar al presionar "Listo"
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Confirma tu contraseña.';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 30),


                              // Botón Registrar
                              ElevatedButton(
                                onPressed: _handleRegistration, 
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.black, 
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 0, 
                                ),
                                child: const Text(
                                  'Registrar',
                                  style: TextStyle(fontSize: 18, color: Colors.white),
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
          
          // BARRAS DE COLOR INFERIORES (FUERA DEL SCROLL)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            // Los valores ahora representan la PROPORCIÓN de la altura (Largo)
            children: [
              _buildColorBar(AppColors.red, 19),     // Más corto
              _buildColorBar(AppColors.orange, 15),   
              _buildColorBar(AppColors.yellow, 17),  
              _buildColorBar(AppColors.green, 13),  
              _buildColorBar(AppColors.blue, 15),    
              _buildColorBar(AppColors.purple, 20),  // Más largo
            ],
          ),
        ],
      ),
    );
  }
  
  // Helper: ConstruirTextFields
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
}