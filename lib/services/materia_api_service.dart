import 'package:dio/dio.dart';

import '../models/materia.dart';

class MateriasService {
  final Dio dio;

  MateriasService(this.dio);

  Future<List<Materia>> getMateriasUsuario(String userId) async {
    try {
      final resp = await dio.get('/materias/idUsuario/$userId');

      final data = resp.data;
      final list = data['data'] ?? data['materias'];

      return (list as List<dynamic>)
          .map((e) => Materia.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception(
          'Error al obtener materias (status: $status, body: $body)');
    }
  }




  Future<Materia> crearMateria({
    required String userId,
    required String nombreMateria,
    String profesorMateria = '',
    String edificioMateria = '',
    String salonMateria = '',
    required List<HorarioMateria> horarios,
  }) async {
    final body = {
      'nombreMateria': nombreMateria,
      'profesorMateria': profesorMateria,
      'edificioMateria': edificioMateria,
      'salonMateria': salonMateria,
      'horariosMateria': horarios.map((h) => h.toJson()).toList(),
    };

    try {
      final resp = await dio.post(
        '/materias/idUsuario/$userId',
        data: body,
      );

      final data = resp.data['data'] ?? resp.data['materiaCreada'];
      return Materia.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data['msg'] ?? 'Error al crear materia';
      throw Exception(msg);
    }
  }




  Future<Materia> actualizarMateria({
    required String userId,
    required String materiaId,
    required String nombreMateria,
    required String profesorMateria,
    required String edificioMateria,
    required String salonMateria,
    required List<HorarioMateria> horarios,
  }) async {
    // Armamos el body igual que en crearMateria
    final body = {
      'nombreMateria': nombreMateria,
      'profesorMateria': profesorMateria,
      'edificioMateria': edificioMateria,
      'salonMateria': salonMateria,
      'horariosMateria': horarios.map((h) => h.toJson()).toList(),
    };

    if (profesorMateria.trim().isNotEmpty) {
    body['profesorMateria'] = profesorMateria.trim();
  }
  if (edificioMateria.trim().isNotEmpty) {
    body['edificioMateria'] = edificioMateria.trim();
  }
  if (salonMateria.trim().isNotEmpty) {
    body['salonMateria'] = salonMateria.trim();
  }

    try {
      final resp = await dio.put(
        '/materias/idUsuario/$userId/idMateria/$materiaId',
        data: body,
      );

      final data = resp.data['data'] ?? resp.data['materiaActualizada'];
      return Materia.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
    final data = e.response?.data;
    // debug para ver en pantalla qué contesta Node:
    throw Exception('Error actualizar (status: $status, data: $data)');
    }
  }




  Future<void> eliminarMateria({
    required String userId,
    required String materiaId,
  }) async {
    try {
      await dio.delete(
        '/materias/idUsuario/$userId/idMateria/$materiaId',
        data: {
          'confirmacion': true, // lo que pide tu backend
        },
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
    final data = e.response?.data;
    // debug para ver en pantalla qué contesta Node:
    throw Exception('Error actualizar (status: $status, data: $data)');
    }
  }



  Future<void> eliminarTodasLasMaterias({
    required String userId,
  }) async {
    try {
      await dio.delete(
        '/materias/idUsuario/$userId',
        data: {
          'confirmacion': true, // mismo patrón que eliminarMateria
        },
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data['msg'] ?? 'Error al eliminar todas las materias';
      throw Exception(msg);
    }
  }
}
