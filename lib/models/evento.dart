// lib/models/evento_personal.dart
class EventoPersonal {
  final String uid;
  final String tituloEvento;
  final String descripcionEvento;
  final DateTime fechaEvento;
  final String horaInicio;   // "HH:MM" 24h
  final String horaFin;      // "HH:MM" 24h
  final bool importante;

  EventoPersonal({
    required this.uid,
    required this.tituloEvento,
    required this.descripcionEvento,
    required this.fechaEvento,
    required this.horaInicio,
    required this.horaFin,
    required this.importante,
  });

  factory EventoPersonal.fromJson(Map<String, dynamic> json) {
    return EventoPersonal(
      uid: json['uid'] ?? json['_id'] ?? '',
      tituloEvento: json['tituloEvento'] ?? '',
      descripcionEvento: json['descripcionEvento'] ?? '',
      fechaEvento: DateTime.parse(json['fechaEvento']),
      horaInicio: json['horaInicio'] ?? '',
      horaFin: json['horaFin'] ?? '',
      importante: json['importante'] ?? false,
    );
  }

  /// Body para crear evento en el backend
  Map<String, dynamic> toJsonCrear() {
    return {
      'tituloEvento': tituloEvento,
      'descripcionEvento': descripcionEvento,
      // backend espera formato YYYY-MM-DD (isISO8601 con .toDate())
      'fechaEvento': _fmtFecha(fechaEvento),
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'importante': importante,
    };
  }

  String _fmtFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
