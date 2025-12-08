// lib/services/calendario_sep_api_service.dart
import 'package:dio/dio.dart';

class EventoCalendarioSep {
  final String id;
  final String ciclo;
  final DateTime fecha;
  final String tipo;         // "VACACIONES" | "DIA_FESTIVO" | "SUSPENSION_CLASES"
  final String descripcion;
  final bool esHabil;

  EventoCalendarioSep({
    required this.id,
    required this.ciclo,
    required this.fecha,
    required this.tipo,
    required this.descripcion,
    required this.esHabil,
  });

  factory EventoCalendarioSep.fromJson(Map<String, dynamic> json) {
    return EventoCalendarioSep(
      id: json['uid'] ?? json['_id'] ?? '',
      ciclo: json['ciclo'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      tipo: json['tipo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      esHabil: json['esHabil'] ?? false,
    );
  }
}

class CalendarioSepApiService {
  final Dio dio;

  CalendarioSepApiService(this.dio);

  // Ajusta si en tu backend está montado como '/api/calendario-sep'
  String get _basePath => '/calendario-sep';

  /// GET /calendario-sep?desde=YYYY-MM-DD&hasta=YYYY-MM-DD&ciclo=...
  Future<List<EventoCalendarioSep>> obtenerEventosRango({
    required DateTime desde,
    required DateTime hasta,
    String? ciclo,
  }) async {
    final params = <String, dynamic>{
      'desde': _fmt(desde),
      'hasta': _fmt(hasta),
    };
    if (ciclo != null) {
      params['ciclo'] = ciclo;
    }

    final resp = await dio.get(_basePath, queryParameters: params);
    final data = resp.data;

    final List lista = data['eventos'] ?? [];
    return lista
        .map((e) => EventoCalendarioSep.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /calendario-sep/dia?fecha=YYYY-MM-DD&ciclo=...
  Future<List<EventoCalendarioSep>> obtenerEventosDia({
    required DateTime fecha,
    String? ciclo,
  }) async {
    final params = <String, dynamic>{
      'fecha': _fmt(fecha),
    };
    if (ciclo != null) {
      params['ciclo'] = ciclo;
    }

    final resp = await dio.get('$_basePath/dia', queryParameters: params);
    final data = resp.data;

    final List lista = data['eventos'] ?? [];
    return lista
        .map((e) => EventoCalendarioSep.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
