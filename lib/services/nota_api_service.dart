// lib/services/notas_api_service.dart
import 'package:dio/dio.dart';
import '../models/nota.dart';

class NotasApiService {
  final Dio dio;

  NotasApiService(this.dio);

  // GET /notas/idUsuario/:idU
  Future<List<Nota>> obtenerNotasUsuario(String userId) async {
    try {
      final resp = await dio.get('/notas/idUsuario/$userId');
      final data = resp.data;

      final List<dynamic> rawList = (data['notas'] ?? []) as List<dynamic>;
      return rawList
          .map((e) => Nota.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_buildDioMessage(e));
    } catch (e) {
      throw Exception('Error desconocido al obtener notas: $e');
    }
  }

  // POST /notas/idUsuario/:idU
  Future<Nota> crearNota({
    required String userId,
    required String nombreNota,
    required String contenidoNota,
  }) async {
    try {
      final resp = await dio.post(
        '/notas/idUsuario/$userId',
        data: {
          'nombreNota': nombreNota,
          'contenidoNota': contenidoNota,
        },
      );

      final data = resp.data;
      final Map<String, dynamic> notaJson =
          (data['notaCreada'] ?? data['nota'] ?? data) as Map<String, dynamic>;

      return Nota.fromJson(notaJson);
    } on DioException catch (e) {
      throw Exception(_buildDioMessage(e));
    } catch (e) {
      throw Exception('Error desconocido al crear nota: $e');
    }
  }

  // PUT /notas/idUsuario/:idU/idNota/:idN
  Future<Nota> actualizarNota({
    required String userId,
    required String notaId,
    required String nombreNota,
    required String contenidoNota,
  }) async {
    try {
      final resp = await dio.put(
        '/notas/idUsuario/$userId/idNota/$notaId',
        data: {
          'nombreNota': nombreNota,
          'contenidoNota': contenidoNota,
        },
      );

      final data = resp.data;
      final Map<String, dynamic> notaJson =
          (data['nota'] ?? data) as Map<String, dynamic>;

      return Nota.fromJson(notaJson);
    } on DioException catch (e) {
      throw Exception(_buildDioMessage(e));
    } catch (e) {
      throw Exception('Error desconocido al actualizar nota: $e');
    }
  }

  // DELETE /notas/idUsuario/:idU/idNota/:idN
  Future<void> eliminarNota({
    required String userId,
    required String notaId,
  }) async {
    try {
      await dio.delete(
        '/notas/idUsuario/$userId/idNota/$notaId',
        data: {
          'confirmacion': true,
        },
      );
    } on DioException catch (e) {
      throw Exception(_buildDioMessage(e));
    } catch (e) {
      throw Exception('Error desconocido al eliminar nota: $e');
    }
  }

  // DELETE /notas/idUsuario/:idU
  Future<void> eliminarTodasNotas({
    required String userId,
  }) async {
    try {
      await dio.delete(
        '/notas/idUsuario/$userId',
        data: {
          'confirmacion': true,
        },
      );
    } on DioException catch (e) {
      throw Exception(_buildDioMessage(e));
    } catch (e) {
      throw Exception('Error desconocido al eliminar todas las notas: $e');
    }
  }

  String _buildDioMessage(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    return 'DioException [status: $status] ${e.message}\nRespuesta: $data';
  }
}
