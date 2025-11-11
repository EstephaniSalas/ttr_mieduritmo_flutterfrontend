import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'recuperar_contraseña.dart';

// Paleata de colores
class AppColors {
  static const Color red = Color(0xFFF20000);
  static const Color orange = Color(0xFFFC8A27);
  static const Color yellow = Color(0xFFFFCB3A);
  static const Color green = Color(0xFF8ACB27);
  static const Color blue = Color(0xFF1782C6);
  static const Color purple = Color(0xFF6B4E91);
  static const Color black = Color(0xFF000000); // Para el botón Ingresar
  static const Color lightGrey = Color(0xFFF0F0F0); // Para el fondo de los TextField
  static const Color darkGrey = Color.fromARGB(255, 0, 0, 0); // Para slogan"
}

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

  // ARREGLO 1: Inicialización segura de FocusNode para evitar LateError
  final FocusNode _emailFocusNode = FocusNode(); 
  final FocusNode _passwordFocusNode = FocusNode(); 

  @override
  void initState() {
    super.initState();
    
    // ARREGLO 2: Forzar el foco inicial al campo de correo después de un breve retraso
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_emailFocusNode.canRequestFocus) {
        _emailFocusNode.requestFocus();
      }
    });
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final String email = _emailController.text;
      final String password = _passwordController.text;

      print('Intentando iniciar sesión con Email: $email, Password: $password');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Validación exitosa. Iniciando sesión con $email...')),
      );
      // TODO: Aquí iría la navegación a la siguiente pantalla si el login es exitoso
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa los campos solicitados.')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    // ARREGLO 3: Limpiar los FocusNode
    _emailFocusNode.dispose(); 
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el tamaño de la pantalla para ajustar los elementos
    final screenHeight = MediaQuery.of(context).size.height;

    // GestureDetector para cerrar el teclado si el usuario toca fuera de los campos
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
                    height: screenHeight * 0.48, // Mantiene tu valor de diseño
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
                          style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
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
                            _buildCardWithOffset(offset: -160, rotation: -0.2, color: AppColors.purple, icon: Icons.calendar_today), 
                            _buildCardWithOffset(offset: -90, rotation: -0.1, color: AppColors.blue, icon: Icons.description),
                            _buildCardWithOffset(offset: 0, rotation: 0.0, color: AppColors.red, icon: Icons.check_box), 
                            _buildCardWithOffset(offset: 90, rotation: 0.1, color: AppColors.green, icon: Icons.access_time),
                            _buildCardWithOffset(offset: 160, rotation: 0.2, color: AppColors.orange, icon: Icons.edit_note), 
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
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),

                      // Campo de Correo Electrónico
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode, // ASIGNACIÓN CLAVE
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next, // Tecla "Siguiente"
                        onFieldSubmitted: (value) {
                           _passwordFocusNode.requestFocus(); // Mover el foco a la Contraseña
                        },
                        // CLAVE: Añadimos un validador
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa tu correo electrónico.';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Ingresa un correo válido.';
                          }
                          return null; // El campo es válido
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
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo de Contraseña
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode, // ASIGNACIÓN CLAVE
                        obscureText: true,
                        textInputAction: TextInputAction.done, // Tecla "Listo"
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
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                          suffixIcon: TextButton(
                            onPressed: () {
                              // NAVEGACIÓN A RECUPERACIÓN DE CONTRASEÑA
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  // Asegúrate de usar la clase en español
                                  builder: (context) => const RecuperarContrasenaScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(color: AppColors.blue, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Botón Ingresar
                      ElevatedButton(
                        onPressed: _handleLogin, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black, 
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0, 
                        ),
                        child: const Text(
                          'Ingresar',
                          style: TextStyle(fontSize: 18, color: Colors.white),
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
                                  builder: (context) => const RegistrationScreen(),
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
  Widget _buildCardWithOffset({required double offset, required double rotation, required Color color, required IconData icon}) {
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
          child: Icon(icon, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}