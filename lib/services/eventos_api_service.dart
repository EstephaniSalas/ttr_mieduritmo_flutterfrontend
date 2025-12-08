// lib/services/eventos_api_service.dart
import 'package:dio/dio.dart';

import '../models/evento.dart'; // aquí está EventoPersonal

class EventosApiService {
  final Dio dio;

  EventosApiService(this.dio);

  // En tu backend las rutas están montadas como /api/eventos,
  // y en Dio normalmente ya tienes baseUrl = 'http://.../api'
  // así que aquí solo va '/eventos'
  String get _basePath => '/eventos';

  String _fmtFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// GET /api/eventos/idUsuario/:idU
  Future<List<EventoPersonal>> obtenerEventosUsuario(String idUsuario) async {
    final resp = await dio.get('$_basePath/idUsuario/$idUsuario');
    final data = resp.data;
    final List lista = data['eventos'] ?? [];
    return lista
        .map((e) => EventoPersonal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/eventos/idUsuario/:idU
  Future<EventoPersonal> crearEvento({
    required String idUsuario,
    required String titulo,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    String descripcion = '',
    bool importante = false,
  }) async {
    final body = EventoPersonal(
      uid: '',
      tituloEvento: titulo,
      descripcionEvento: descripcion,
      fechaEvento: fecha,
      horaInicio: horaInicio,
      horaFin: horaFin,
      importante: importante,
    ).toJsonCrear();

    final resp = await dio.post(
      '$_basePath/idUsuario/$idUsuario',
      data: body,
    );

    final eventoJson = resp.data['evento'] as Map<String, dynamic>;
    return EventoPersonal.fromJson(eventoJson);
  }

  /// PUT /api/eventos/idUsuario/:idU/idEvento/:idE
  Future<EventoPersonal> actualizarEvento({
    required String idUsuario,
    required String idEvento,
    String? titulo,
    String? descripcion,
    DateTime? fecha,
    String? horaInicio,
    String? horaFin,
    bool? importante,
  }) async {
    final body = <String, dynamic>{};

    if (titulo != null) body['tituloEvento'] = titulo;
    if (descripcion != null) body['descripcionEvento'] = descripcion;
    if (fecha != null) body['fechaEvento'] = _fmtFecha(fecha);
    if (horaInicio != null) body['horaInicio'] = horaInicio;
    if (horaFin != null) body['horaFin'] = horaFin;
    if (importante != null) body['importante'] = importante;

    final resp = await dio.put(
      '$_basePath/idUsuario/$idUsuario/idEvento/$idEvento',
      data: body,
    );

    final eventoJson = resp.data['evento'] as Map<String, dynamic>;
    return EventoPersonal.fromJson(eventoJson);
  }

  /// DELETE /api/eventos/idUsuario/:idU
  Future<void> borrarTodosEventosUsuario(String idUsuario) async {
    await dio.delete('$_basePath/idUsuario/$idUsuario');
  }

  /// DELETE /api/eventos/idUsuario/:idU/idEvento/:idE
  Future<void> borrarEvento({
    required String idUsuario,
    required String idEvento,
  }) async {
    await dio.delete('$_basePath/idUsuario/$idUsuario/idEvento/$idEvento');
  }
}
