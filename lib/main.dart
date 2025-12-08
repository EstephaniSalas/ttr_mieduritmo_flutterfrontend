import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/usuario_api_service.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Clave global para navegar incluso fuera del contexto
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de formato de fechas para español México
  await initializeDateFormatting('es_MX', null);

  final apiService = UsuarioApiService(); // Instancia global

  // Cuando el token expire, cerrar sesión automáticamente
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
      navigatorKey: navigatorKey, // necesario para logout global
      debugShowCheckedModeBanner: false,
      title: 'MiEduRitmo',

      // Locale por defecto de la app
      locale: const Locale('es', 'MX'),
      supportedLocales: const [
        Locale('es', 'MX'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: LoginScreen(api: api),
    );
  }
}
