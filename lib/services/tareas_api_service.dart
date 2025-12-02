// lib/services/tareas_api_service.dart
import 'package:dio/dio.dart';

import '../models/tarea.dart';

class TareasService {
  final Dio dio;

  TareasService(this.dio);

  // GET /tareas/idUsuario/:idU
  Future<List<Tarea>> obtenerTareasUsuario(String userId) async {
    try {
      final resp = await dio.get('/tareas/idUsuario/$userId');

      final data = resp.data;
      final List<dynamic> lista = data['tareas'] ?? [];

      return lista
          .map((e) => Tarea.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception(
          'Error al obtener tareas (status: $status, body: $body)');
    }
  }

  // POST /tareas/idUsuario/:idU
  Future<Tarea> crearTarea({
    required String userId,
    required String nombreTarea,
    String? materiaId,
    String descripcionTarea = '',
    String tipoTarea = 'Tarea',
    required DateTime fechaEntrega,
    required String horaEntrega24,
  }) async {
    final body = {
      'nombreTarea': nombreTarea,
      if (materiaId != null) 'materiaTarea': materiaId,
      'descripcionTarea': descripcionTarea,
      'tipoTarea': tipoTarea,
      'fechaEntregaTarea': _formatearFecha(fechaEntrega),
      'horaEntregaTarea': horaEntrega24,
      'estatusTarea': 'Pendiente',
    };

    try {
      final resp = await dio.post(
        '/tareas/idUsuario/$userId',
        data: body,
      );

      final tareaJson = resp.data['tarea'];
      return Tarea.fromJson(tareaJson as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg =
          e.response?.data['msg'] ?? 'Error al crear tarea';
      throw Exception(msg);
    }
  }

  // PUT /tareas/idUsuario/:idU/idTarea/:idT
  Future<Tarea> actualizarTarea({
    required String userId,
    required String tareaId,
    String? nombreTarea,
    String? materiaId,
    String? descripcionTarea,
    String? tipoTarea,
    DateTime? fechaEntrega,
    String? horaEntrega24,
    String? estatusTarea,
  }) async {
    final body = <String, dynamic>{};

    if (nombreTarea != null) body['nombreTarea'] = nombreTarea;
    if (materiaId != null) body['materiaTarea'] = materiaId;
    if (descripcionTarea != null) body['descripcionTarea'] = descripcionTarea;
    if (tipoTarea != null) body['tipoTarea'] = tipoTarea;
    if (fechaEntrega != null) {
      body['fechaEntregaTarea'] = _formatearFecha(fechaEntrega);
    }
    if (horaEntrega24 != null) body['horaEntregaTarea'] = horaEntrega24;
    if (estatusTarea != null) body['estatusTarea'] = estatusTarea;

    try {
      final resp = await dio.put(
        '/tareas/idUsuario/$userId/idTarea/$tareaId',
        data: body,
      );

      final tareaJson = resp.data['tarea'];
      return Tarea.fromJson(tareaJson as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg =
          e.response?.data['msg'] ?? 'Error al actualizar tarea';
      throw Exception(msg);
    }
  }

  // PATCH /tareas/idUsuario/:idU/idTarea/:idT/estatus
  Future<Tarea> cambiarEstatusTarea({
    required String userId,
    required String tareaId,
    required String estatusTarea, // Pendiente | Completada | Vencida
  }) async {
    try {
      final resp = await dio.patch(
        '/tareas/idUsuario/$userId/idTarea/$tareaId/estatus',
        data: {
          'estatusTarea': estatusTarea,
        },
      );

      final tareaJson = resp.data['tarea'];
      return Tarea.fromJson(tareaJson as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg =
          e.response?.data['msg'] ?? 'Error al cambiar estatus de tarea';
      throw Exception(msg);
    }
  }

  // DELETE /tareas/idUsuario/:idU/idTarea/:idT
  Future<void> eliminarTarea({
    required String userId,
    required String tareaId,
  }) async {
    try {
      await dio.delete(
        '/tareas/idUsuario/$userId/idTarea/$tareaId',
        data: {
          'confirmacion': true,
        },
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data['msg'] ?? 'Error al eliminar tarea';
      throw Exception(msg);
    }
  }

  // DELETE /tareas/idUsuario/:idU/todas
  Future<void> eliminarTodasTareas({
    required String userId,
  }) async {
    try {
      await dio.delete(
        '/tareas/idUsuario/$userId/todas',
        data: {
          'confirmacion': true,
        },
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data['msg'] ?? 'Error al eliminar todas las tareas';
      throw Exception(msg);
    }
  }

  String _formatearFecha(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d'; // formato que espera tu backend
  }
}
