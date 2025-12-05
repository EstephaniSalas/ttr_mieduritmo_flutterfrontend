import 'package:dio/dio.dart';

class ResumenDiaEstudio {
  final String fecha;         // "YYYY-MM-DD"
  final int totalSegundos;
  final double totalMinutos;

  ResumenDiaEstudio({
    required this.fecha,
    required this.totalSegundos,
    required this.totalMinutos,
  });

  factory ResumenDiaEstudio.fromJson(Map<String, dynamic> json) {
    return ResumenDiaEstudio(
      fecha: json['fecha'] as String,
      totalSegundos: (json['totalSegundos'] as num).toInt(),
      totalMinutos: (json['totalMinutos'] as num).toDouble(),
    );
  }
}

class SesionEstudioApiService {
  final Dio dio;

  SesionEstudioApiService(this.dio);

  /// Registrar una sesión de estudio
  ///
  /// Backend:
  /// POST /api/sesiones-estudio/idUsuario/:idU/idMateria/:idM
  Future<void> registrarSesionEstudio({
    required String userId,
    required String materiaId,
    required int duracionSegundos,
    DateTime? fechaSesion,
  }) async {
    // OJO: asumo que dio.options.baseUrl YA tiene el `/api`
    // ej. http://10.0.2.2:3333/api
    final resp = await dio.post(
      '/sesiones-estudio/idUsuario/$userId/idMateria/$materiaId',
      data: {
        'duracionSegundos': duracionSegundos,
        if (fechaSesion != null)
          'fechaSesion': fechaSesion.toUtc().toIso8601String(),
      },
    );

    if (resp.statusCode != 201) {
      throw Exception(
          'Error al registrar sesión: ${resp.statusCode} ${resp.data}');
    }
  }

  /// Obtener resumen de estudio
  ///
  /// Backend:
  /// GET /api/sesiones-estudio/idUsuario/:idU?desde=YYYY-MM-DD&hasta=YYYY-MM-DD&idMateria=...
  Future<List<ResumenDiaEstudio>> obtenerResumenEstudio({
    required String userId,
    DateTime? desde,
    DateTime? hasta,
    String? materiaId,
  }) async {
    final params = <String, dynamic>{};

    if (desde != null) {
      params['desde'] = '${desde.year.toString().padLeft(4, '0')}-'
          '${desde.month.toString().padLeft(2, '0')}-'
          '${desde.day.toString().padLeft(2, '0')}';
    }
    if (hasta != null) {
      params['hasta'] = '${hasta.year.toString().padLeft(4, '0')}-'
          '${hasta.month.toString().padLeft(2, '0')}-'
          '${hasta.day.toString().padLeft(2, '0')}';
    }
    if (materiaId != null && materiaId.isNotEmpty) {
      params['idMateria'] = materiaId;
    }

    final resp = await dio.get(
      '/sesiones-estudio/idUsuario/$userId',
      queryParameters: params,
    );

    if (resp.statusCode != 200) {
      throw Exception(
          'Error al obtener resumen estudio: ${resp.statusCode} ${resp.data}');
    }

    final data = resp.data;
    final list = (data['resumenDias'] as List? ?? []);
    return list
        .map((e) => ResumenDiaEstudio.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
