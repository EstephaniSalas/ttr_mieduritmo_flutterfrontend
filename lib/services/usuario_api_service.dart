import 'package:dio/dio.dart';
import '../models/usuario.dart';
import '../config/api_config.dart';
import 'package:flutter/material.dart'; // Para VoidCallback

class UsuarioApiService {
  final Dio dio = Dio();
  String? _token;

  VoidCallback? onTokenExpired;

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
        onError: (DioException e, handler) {
          // Si el backend dice 401 → token inválido o expirado
          if (e.response?.statusCode == 401) {
            if (onTokenExpired != null) {
              onTokenExpired!();
            }
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

  // ---------- LOGOUT ----------
  Future<void> logout() async {
    _token = null;
  }
}
