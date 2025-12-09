import 'package:dio/dio.dart';
import '../models/usuario.dart';
import '../config/api_config.dart';
import 'package:flutter/material.dart'; // Para VoidCallback

class UsuarioApiService {
  final Dio dio = Dio();
  String? _token;

  void Function()? onTokenExpired;

  UsuarioApiService() {
    dio.options.baseUrl = ApiConfig.baseUrl;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Si hay token, agregarlo SIEMPRE
          if (_token != null) {
            options.headers['x-token'] = _token;
          }
          return handler.next(options);
        },
         onError: (e, handler) {
          final status = e.response?.statusCode;
          if (status == 401 && onTokenExpired != null) {
            onTokenExpired!();
          }
          return handler.next(e);
        },
      ),
    );
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
        _token = resp.data['token'];                // <-- GUARDAR TOKEN
        return Usuario.fromJson(resp.data['usuario']);
      } else {
        throw Exception(resp.data['msg'] ?? 'Error al registrar usuario');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['msg'] ?? 'Error de conexión al registrar usuario');
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
        _token = resp.data['token'];               // <-- GUARDAR TOKEN AQUÍ
        return Usuario.fromJson(resp.data['usuario']);
      } else {
        throw Exception(resp.data['msg'] ?? 'Credenciales inválidas');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['msg'] ??
          'Error de conexión al iniciar sesión (${e.type})');
    }
  }

  // ---------- OBTENER USUARIO ----------
  Future<Usuario> obtenerUsuarioPorId(String uid) async {
    try {
      final resp = await dio.get('/usuarios/$uid');

      if (resp.statusCode == 200) {
        return Usuario.fromJson(resp.data['usuario']);
      } else {
        throw Exception(resp.data['msg'] ?? 'Error al obtener usuario');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['msg'] ?? 'Error de conexión al obtener usuario');
    }
  }


  // ---------- ACTUALIZAR USURARIO ---------
  Future<Usuario> actualizarUsuario({
    required String id,
    String? nombre,
    String? passwordActual,
    String? passwordNueva,
    String? passwordNueva2,
  }) async {
    final data = <String, dynamic>{};

    if (nombre != null)
      data['nombre'] = nombre;
    
    if (passwordActual != null &&
        passwordNueva != null &&
        passwordNueva2 != null) {
      data['passwordActual'] = passwordActual;
      data['passwordNueva'] = passwordNueva;
      data['passwordNueva2'] = passwordNueva2;
    }

    final url = '${ApiConfig.baseUrl}/usuarios/$id'; 

    try {
    final resp = await dio.put(url, data: data);

    if (resp.statusCode == 200) {
      return Usuario.fromJson(resp.data['usuario']);
    } else {
      throw Exception(resp.data['msg'] ?? 'Error al actualizar usuario');
    }
  } on DioException catch (e) {
    // para ver exactamente qué responde el backend
    debugPrint('ERROR actualizarUsuario: ${e.response?.data}');
    throw Exception(
      e.response?.data['msg'] ?? 'Error de conexión al actualizar usuario',
    );
  }
}


  // ---------- LOGOUT ----------
  Future<void> logout() async {
    _token = null;
  }
}
