import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../models/usuario.dart';
import '../config/api_config.dart';

class UsuarioApiService {
  // Este Dio se comparte en toda la app (login, materias, etc.)
  // y es el que guarda la cookie 'token'
  final Dio dio;

  UsuarioApiService()
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl, // http://10.0.2.2:3333/api
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ) {
    // Todas las cookies (incluida 'token') se guardan aquí
    dio.interceptors.add(CookieManager(CookieJar()));
  }

  // ---------- REGISTRO ----------
  Future<Usuario> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String password2,
  }) async {
    try {
      final resp = await dio.post(
        '/usuarios',
        data: {
          'nombre': nombre,
          'correo': correo,
          'password': password,
          'password2': password2,
        },
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return Usuario.fromJson(resp.data['usuario']);
      } else {
        final msg = resp.data['msg'] ?? 'Error al registrar usuario';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final msg =
          e.response?.data['msg'] ?? 'Error de conexión al registrar usuario';
      throw Exception(msg);
    }
  }

  // ---------- LOGIN ----------
  Future<Usuario> loginUsuario({
    required String correo,
    required String password,
  }) async {
    try {
      final resp = await dio.post(
        '/autenticacion/login',
        data: {
          'correo': correo,
          'password': password,
        },
      );

      if (resp.statusCode == 200) {
        // El backend setea cookie 'token'; CookieManager la guarda en ESTE Dio
        return Usuario.fromJson(resp.data['usuario']);
      } else {
        final msg = resp.data['msg'] ?? 'Credenciales inválidas';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final msg = e.response?.data['msg'] ??
          'Error de conexión al iniciar sesión (${e.type})';
      throw Exception(msg);
    }
  }

  // ---------- OBTENER USUARIO POR ID ----------
  Future<Usuario> obtenerUsuarioPorId(String uid) async {
    try {
      final resp = await dio.get('/usuarios/$uid');

      if (resp.statusCode == 200) {
        return Usuario.fromJson(resp.data['usuario']);
      } else {
        final msg = resp.data['msg'] ?? 'Error al obtener usuario';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final msg =
          e.response?.data['msg'] ?? 'Error de conexión al obtener usuario';
      throw Exception(msg);
    }
  }
}
