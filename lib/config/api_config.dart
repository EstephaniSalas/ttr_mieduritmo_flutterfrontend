class ApiConfig {
  // - Android emulador: 10.0.2.2
  // - Dispositivo físico en misma red: IP local de PC
  // static const String baseUrl = 'http://10.0.2.2:3333/api'; dev
  static const String baseUrl = 'https://ttr-26-1-0001-appmieduritmo-production.up.railway.app/api'; //produccion

  //Rutas usuarios
  static const String usuarios = '$baseUrl/usuarios';
  static const String solicitarCambioPassword =
      '$usuarios/solicitud-cambio-password';
  static const String confirmarCambioPassword =
      '$usuarios/confirmar-cambio-password';

   // Rutas autenticación
  static const String loginUsuario = '$baseUrl/autenticacion/login';

   //Rutas materias
   static const String materias = '$baseUrl/materias';

 // Dispositivo físico en la misma red
 // static const String baseUrl = 'http://192.168.1.64:8080/api'; // IP de PC

 //static const String usuarios = '$baseUrl/usuarios';
 // static const String solicitarCambioPassword =
 //     '$usuarios/solicitud-cambio-password';
 // static const String confirmarCambioPassword =
 //     '$usuarios/confirmar-cambio-password';

}
