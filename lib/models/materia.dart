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
    dia: json['dia']?.toString() ?? '',
    horaInicio: json['horaInicio']?.toString() ?? '',
    horaFin: json['horaFin']?.toString() ?? '',
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
  // Manejar el ID de forma segura
  final dynamic idValue = json["id"] ?? json["uid"] ?? json["_id"];
  final String safeId = idValue?.toString() ?? '';
  
  // Manejar horarios de forma segura
  final horariosData = json["horariosMateria"] as List<dynamic>? ?? [];
  final List<HorarioMateria> horarios = horariosData
      .map((e) => HorarioMateria.fromJson(e as Map<String, dynamic>))
      .toList();

  return Materia(
    id: safeId,
    nombre: json["nombreMateria"]?.toString() ?? "",
    profesor: json["profesorMateria"]?.toString() ?? "",
    edificio: json["edificioMateria"]?.toString() ?? "",
    salon: json["salonMateria"]?.toString() ?? "",
    horarios: horarios,
  );
}
}
