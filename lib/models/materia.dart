class HorarioMateria {
  final String dia;
  final String horaInicio; // "08:00"
  final String horaFin;    // "09:00"

  HorarioMateria({
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
  });

  factory HorarioMateria.fromJson(Map<String, dynamic> json) {
    return HorarioMateria(
      dia: json['dia'] as String,
      horaInicio: json['horaInicio'] as String,
      horaFin: json['horaFin'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'dia': dia,
        'horaInicio': horaInicio,
        'horaFin': horaFin,
      };
}

class Materia {
  final String id;
  final String nombre;
  final String profesor;
  final String edificio;
  final String salon;
  final List<HorarioMateria> horarios;

  Materia({
    required this.id,
    required this.nombre,
    required this.profesor,
    required this.edificio,
    required this.salon,
    required this.horarios,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: (json['uid'] ?? json['_id']) as String,
      nombre: json['nombreMateria'] as String,
      profesor: (json['profesorMateria'] ?? '') as String,
      edificio: (json['edificioMateria'] ?? '') as String,
      salon: (json['salonMateria'] ?? '') as String,
      horarios: (json['horariosMateria'] as List<dynamic>)
          .map((h) => HorarioMateria.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}
