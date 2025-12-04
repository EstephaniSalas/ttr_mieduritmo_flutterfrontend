import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/usuario_api_service.dart';

// ← Clave global para navegar incluso fuera del contexto
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  final apiService = UsuarioApiService(); // Instancia global

  // ← Cuando el token expire, cerrar sesión automáticamente
  apiService.onTokenExpired = () {
    apiService.logout(); // limpia cookie/token

    // Regresas al login desde cualquier pantalla
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(api: apiService),
      ),
      (route) => false,
    );
  };

  runApp(MyApp(api: apiService));
}

class MyApp extends StatelessWidget {
  final UsuarioApiService api;

  const MyApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ← NECESARIO para logout global
      debugShowCheckedModeBanner: false,
      title: 'MiEduRitmo',
      home: LoginScreen(api: api),
    );
  }
}
